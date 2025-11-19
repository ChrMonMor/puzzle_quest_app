import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnRunPage extends StatefulWidget {
  final String runId;
  final http.Client? httpClient;
  final String? baseUrl;
  final bool startTracking;

  const OnRunPage({
    super.key,
    required this.runId,
    required Map<String, dynamic> run,
    this.httpClient,
    this.baseUrl,
    this.startTracking = true,
  });

  @override
  State<OnRunPage> createState() => _OnRunPageState();
}

class _OnRunPageState extends State<OnRunPage> {
  final MapController _mapController = MapController();
  final Distance _distanceCalc = Distance();
  late final http.Client _http;
  late final String _baseUrl;

  Map<String, dynamic>? _run;
  List<Map<String, dynamic>> _flags = [];
  int _currentFlagIndex = 0;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  String? historyId;
  Map<int, int> _flagIndexToHistoryFlagId = {};

  Timer? _timer;
  int _secondsElapsed = 0;
  double _currentZoom = 16;

  bool _loading = true;
  bool _error = false;
  bool _questionShown = false;

  /// Store user answer status for progress bar: true = correct, false = wrong
  final Map<int, bool> _flagAnswerStatus = {};

  @override
  void initState() {
    super.initState();
    _http = widget.httpClient ?? http.Client();
    _baseUrl = widget.baseUrl ?? 'http://pro-xi-mi-ty-srv';
    _fetchRun();
    if (widget.startTracking) {
      _startLocationTracking();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _fetchRun() async {
    final url = '$_baseUrl/api/runs/${widget.runId}';
    try {
      debugPrint('[OnRunPage] GET $url');
      final response = await _http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      debugPrint('[OnRunPage] GET /runs -> ${response.statusCode}');
      debugPrint('[OnRunPage] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        Map<String, dynamic> runData;
        if (decoded is List && decoded.isNotEmpty) {
          runData = decoded.first;
        } else if (decoded is Map<String, dynamic>) {
          runData = decoded;
        } else {
          throw Exception('Unexpected JSON structure');
        }
        final prefs = await SharedPreferences.getInstance();
        var token = prefs.getString('token');
        debugPrint('[OnRunPage] Current token: ${token ?? "(none)"}');
        if (token == null) {
          final guestUrl = '$_baseUrl/api/guests/init';
          debugPrint('[OnRunPage] POST $guestUrl (initializing guest)');
          final guestToken = await _http.post(
            Uri.parse(guestUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          );
          debugPrint('[OnRunPage] guest init -> ${guestToken.statusCode}');
          debugPrint('[OnRunPage] guest init body: ${guestToken.body}');
          if (guestToken.statusCode == 200 || guestToken.statusCode == 201) {
            final gData = jsonDecode(guestToken.body);
            token = gData['guest_uuid'];
            if (token == null || token.isEmpty) {
              debugPrint('[OnRunPage] ERROR: guest_uuid is missing or empty!');
              throw Exception('Guest init response missing guest_uuid');
            }
            await prefs.setString('token', token);
            debugPrint('[OnRunPage] Guest token saved: $token');
          } else {
            debugPrint('[OnRunPage] ERROR: Failed to initialize guest token');
            throw Exception('Failed to initialize guest token');
          }
        }
        Future<http.Response> doStart(String useToken) {
          final startUrl = '$_baseUrl/api/history/run/${widget.runId}/start';
          debugPrint('[OnRunPage] POST $startUrl');
          debugPrint('[OnRunPage] Authorization: Bearer $useToken');
          return _http.post(
            Uri.parse(startUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $useToken',
            },
          );
        }

        var h = await doStart(token);
        if (h.statusCode == 401) {
          // Attempt token refresh (guest re-init) then retry once
          debugPrint('[OnRunPage] 401 starting run - refreshing token');
          final prefsRefresh = await SharedPreferences.getInstance();
          await prefsRefresh.remove('token');
          final guestUrl = '$_baseUrl/api/guests/init';
          final guestTokenResp = await _http.post(
            Uri.parse(guestUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          );
            if (guestTokenResp.statusCode == 200 || guestTokenResp.statusCode == 201) {
              final gData = jsonDecode(guestTokenResp.body);
              final newToken = gData['guest_uuid'];
              if (newToken is String && newToken.isNotEmpty) {
                await prefsRefresh.setString('token', newToken);
                token = newToken;
                debugPrint('[OnRunPage] Retrying start with refreshed token');
                h = await doStart(token);
              }
            }
        }

        debugPrint('[OnRunPage] start run -> ${h.statusCode}');
        debugPrint('[OnRunPage] start run body: ${h.body}');
        if (h.statusCode == 201 || h.statusCode == 200) {
          final hData = jsonDecode(h.body);
          historyId = hData['history']['history_id'].toString();

          // Map flag indices to history_flag_id by matching coordinates (tolerant)
          final historyFlags =
              (hData['history']['flags'] as List<dynamic>)
                  .map<Map<String, dynamic>>(
                    (f) => Map<String, dynamic>.from(f),
                  )
                  .toList();

          bool matches(double a, double b) => (a - b).abs() < 1e-6;

          final runFlagsList = (runData['flags'] ?? []) as List<dynamic>;
          for (int i = 0; i < runFlagsList.length; i++) {
            final rf = Map<String, dynamic>.from(runFlagsList[i]);
            final rLat = double.tryParse(rf['flag_lat'].toString()) ?? 0.0;
            final rLng = double.tryParse(rf['flag_long'].toString()) ?? 0.0;

            final match = historyFlags.firstWhere(
              (hf) =>
                  matches(
                    double.tryParse(hf['history_flag_lat'].toString()) ?? 0.0,
                    rLat,
                  ) &&
                  matches(
                    double.tryParse(hf['history_flag_long'].toString()) ?? 0.0,
                    rLng,
                  ),
              orElse: () => {},
            );

            if (match.isNotEmpty && match['history_flag_id'] != null) {
              _flagIndexToHistoryFlagId[i] = match['history_flag_id'] as int;
            }
          }
        } else {
          debugPrint('[OnRunPage] ERROR: Failed to start run - status ${h.statusCode}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text('Failed to start run (HTTP ${h.statusCode})'),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
        final flags = (runData['flags'] ?? []);
        setState(() {
          _run = runData;
          _flags =
              (flags is List)
                  ? flags
                      .map<Map<String, dynamic>>(
                        (f) => Map<String, dynamic>.from(f),
                      )
                      .toList()
                  : [];
          _loading = false;
          _error = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_flags.isNotEmpty && _currentPosition == null) {
            final lat =
                double.tryParse(_flags[0]['flag_lat'].toString()) ?? 0.0;
            final lng =
                double.tryParse(_flags[0]['flag_long'].toString()) ?? 0.0;
            _mapController.move(LatLng(lat, lng), _currentZoom);
          }
        });
      } else {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    } catch (e) {
      debugPrint('[OnRunPage] ERROR in _fetchRun: $e');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      setState(() => _currentPosition = position);
      _checkNextFlag(position);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition != null) {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            _currentZoom,
          );
        }
      });
    });
  }

  void _checkNextFlag(Position position) async {
    if (_currentFlagIndex >= _flags.length) return;

    final nextFlag = _flags[_currentFlagIndex];
    final flagLat = double.tryParse(nextFlag['flag_lat'].toString()) ?? 0.0;
    final flagLong = double.tryParse(nextFlag['flag_long'].toString()) ?? 0.0;

    final distanceToFlag = _distanceCalc(
      LatLng(position.latitude, position.longitude),
      LatLng(flagLat, flagLong),
    );

    if (distanceToFlag <= 10 && !_questionShown) {
      _questionShown = true;

      if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 500);

      if (nextFlag['questions'] != null && nextFlag['questions'].isNotEmpty) {
        final question = nextFlag['questions'][0];
        final isCorrect = await _showQuestionDialog(question);

        // Only mark flag as complete if user answered
        if (isCorrect != null) {
          setState(() {
            _flagAnswerStatus[_currentFlagIndex] = isCorrect;
          });

          // Call API to mark flag as reached
          await _markFlagReached(_currentFlagIndex, isCorrect, distanceToFlag);

          setState(() {
            _currentFlagIndex++;
          });

          if (_currentFlagIndex >= _flags.length) {
            _timer?.cancel();
            await _endRun();
          }
        }
      } else {
        // No questions: auto-complete this flag with 1 point
        setState(() {
          _flagAnswerStatus[_currentFlagIndex] = true;
        });
        await _markFlagReached(_currentFlagIndex, true, distanceToFlag);
        setState(() {
          _currentFlagIndex++;
        });

        if (_currentFlagIndex >= _flags.length) {
          _timer?.cancel();
          await _endRun();
        }
      }

      _questionShown = false;
    }
  }

  Future<void> _markFlagReached(
    int flagIndex,
    bool isCorrect,
    double distanceInMeters,
  ) async {
    if (historyId == null) return;

    final historyFlagId = _flagIndexToHistoryFlagId[flagIndex];
    if (historyFlagId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Calculate points: correct = 1, wrong = 0
      final points = isCorrect ? 1 : 0;

      final response = await _http.post(
        Uri.parse(
          '$_baseUrl/api/history/run/$historyId/flag/$historyFlagId/reach',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'history_flag_point': points,
          // Send distance in meters as provided by calculator
          'history_flag_distance': distanceInMeters,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to mark flag as reached: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking flag as reached: $e');
    }
  }

  Future<void> _endRun({bool showSuccess = true, bool popAfter = true}) async {
    if (historyId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await _http.post(
        Uri.parse('$_baseUrl/api/history/run/$historyId/end'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted && showSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                '🎉 Run completed successfully!',
                textAlign: TextAlign.center,
              ),
              duration: Duration(seconds: 3),
            ),
          );
          if (popAfter) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) Navigator.pop(context);
            });
          }
        } else if (mounted && popAfter) {
          Navigator.pop(context);
        }
      } else {
        debugPrint('Failed to end run: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error ending run: $e');
    }
  }

  /// Returns true if answer correct, false if wrong, null if not answered
  Future<bool?> _showQuestionDialog(Map<String, dynamic> question) async {
    String? selectedOption;
    bool? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final options = (question['options'] ?? []) as List<dynamic>;
        bool submitted = false;
        final allowSubmitWithoutOption = options.isEmpty;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(question['question_text'] ?? 'Question'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    options.map((opt) {
                      Color? optionColor;
                      if (submitted) {
                        final correct = question['question_answer'];
                        if (opt['question_option_id'] == correct)
                          optionColor = Colors.green.shade300;
                        if (opt['question_option_id'] == selectedOption &&
                            selectedOption != correct) {
                          optionColor = Colors.red.shade300;
                        }
                      }

                      return Container(
                        color: optionColor,
                        child: RadioListTile<String>(
                          title: Text(opt['question_option_text']),
                          value: opt['question_option_id'],
                          groupValue: selectedOption,
                          onChanged:
                              submitted
                                  ? null
                                  : (val) =>
                                      setState(() => selectedOption = val),
                        ),
                      );
                    }).toList(),
              ),
              actions: [
                ElevatedButton(
                  onPressed:
                      (selectedOption == null && !allowSubmitWithoutOption) ||
                              submitted
                          ? null
                          : () {
                            submitted = true;
                            if (allowSubmitWithoutOption) {
                              // No options: accept submit as correct (1 point)
                              result = true;
                            } else {
                              final correct = question['question_answer'];
                              result = selectedOption == correct;
                            }
                            setState(() {}); // refresh colors
                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor:
                                      result! ? Colors.green : Colors.red,
                                  content: Text(
                                    result!
                                        ? '✅ Correct Answer!'
                                        : '❌ Wrong Answer',
                                    textAlign: TextAlign.center,
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            });
                          },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  double _distanceToNextFlag() {
    if (_flags.isEmpty ||
        _currentFlagIndex >= _flags.length ||
        _currentPosition == null)
      return 0.0;

    final nextFlag = _flags[_currentFlagIndex];
    final flagLat = double.tryParse(nextFlag['flag_lat'].toString()) ?? 0.0;
    final flagLong = double.tryParse(nextFlag['flag_long'].toString()) ?? 0.0;

    return _distanceCalc(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(flagLat, flagLong),
        ) /
        1000;
  }

  void _cancelRun() async {
    _timer?.cancel();
    // End the run when user cancels, but do it silently and don't auto-pop here
    await _endRun(showSuccess: false, popAfter: false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error || _run == null)
      return const Scaffold(
        body: Center(child: Text('Failed to load run data')),
      );

    final runTitle = _run!['run_title'] ?? _run!['title'] ?? 'Run';

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade100],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            runTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text('Cancel Run?'),
                                    content: const Text(
                                      'Are you sure you want to cancel your current run?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, false),
                                        child: const Text('No'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(ctx, true),
                                        child: const Text('Yes, Cancel'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) _cancelRun();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentFlagIndex < _flags.length
                          ? 'Distance to next flag: ${_distanceToNextFlag().toStringAsFixed(2)} km'
                          : '🏁 Run Completed!',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time elapsed: ${_formatTime(_secondsElapsed)}',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Progress bar with green/red flags
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(_flags.length, (index) {
                    final isCompleted = index < _currentFlagIndex;
                    final status = _flagAnswerStatus[index];
                    Color color;
                    if (status != null) {
                      color = status ? Colors.green : Colors.red;
                    } else if (isCompleted) {
                      color = Colors.green.shade300;
                    } else if (index == _currentFlagIndex) {
                      color = Colors.orangeAccent;
                    } else {
                      color = Colors.grey.shade300;
                    }

                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Map
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _currentPosition != null
                            ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                            : (_flags.isNotEmpty
                                ? LatLng(
                                  double.tryParse(
                                        _flags[0]['flag_lat'].toString(),
                                      ) ??
                                      0.0,
                                  double.tryParse(
                                        _flags[0]['flag_long'].toString(),
                                      ) ??
                                      0.0,
                                )
                                : LatLng(0, 0)),
                    initialZoom: _currentZoom,
                    maxZoom: 18,
                    minZoom: 3,
                    onPositionChanged: (pos, _) => _currentZoom = pos.zoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.marc.proximityrundev',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ..._flags.map((flag) {
                          final lat =
                              double.tryParse(flag['flag_lat'].toString()) ??
                              0.0;
                          final lng =
                              double.tryParse(flag['flag_long'].toString()) ??
                              0.0;
                          final index = _flags.indexOf(flag);

                          Color color;
                          if (_flagAnswerStatus.containsKey(index)) {
                            color =
                                _flagAnswerStatus[index]!
                                    ? Colors.green
                                    : Colors.red;
                          } else if (index < _currentFlagIndex) {
                            color = Colors.green.shade300;
                          } else if (index == _currentFlagIndex) {
                            color = Colors.orangeAccent;
                          } else {
                            color = Colors.grey;
                          }

                          return Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(lat, lng),
                            child: Icon(
                              Icons.flag,
                              color: color,
                              size: 40,
                              shadows:
                                  index == _currentFlagIndex
                                      ? [
                                        Shadow(
                                          color: Colors.orangeAccent.withValues(
                                            alpha: 0.8,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ]
                                      : [],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_currentFlagIndex < _flags.length) {
                  final nextFlag = _flags[_currentFlagIndex];
                  final flagLat =
                      double.tryParse(nextFlag['flag_lat'].toString()) ?? 0.0;
                  final flagLong =
                      double.tryParse(nextFlag['flag_long'].toString()) ?? 0.0;

                  final simulatedPosition = Position(
                    latitude: flagLat,
                    longitude: flagLong,
                    timestamp: DateTime.now(),
                    accuracy: 5,
                    altitude: 0,
                    heading: 0,
                    speed: 0,
                    speedAccuracy: 0,
                    altitudeAccuracy: 0,
                    headingAccuracy: 0,
                  );

                  _checkNextFlag(simulatedPosition);
                }
              },
              icon: const Icon(Icons.flag),
              label: const Text('Simulate Next Flag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}