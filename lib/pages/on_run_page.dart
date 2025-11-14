import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class OnRunPage extends StatefulWidget {
  final String runId;

  const OnRunPage({super.key, required this.runId, required Map<String, dynamic> run});

  @override
  State<OnRunPage> createState() => _OnRunPageState();
}

class _OnRunPageState extends State<OnRunPage> {
  final MapController _mapController = MapController();
  final Distance _distanceCalc = Distance();

  Map<String, dynamic>? _run;
  List<Map<String, dynamic>> _flags = [];
  int _currentFlagIndex = 0;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

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
    _fetchRun();
    _startLocationTracking();
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
    final url = 'http://pro-xi-mi-ty-srv/api/runs/${widget.runId}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

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

        final flags = (runData['flags'] ?? []);
        setState(() {
          _run = runData;
          _flags = (flags is List)
              ? flags.map<Map<String, dynamic>>((f) => Map<String, dynamic>.from(f)).toList()
              : [];
          _loading = false;
          _error = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_flags.isNotEmpty && _currentPosition == null) {
            final lat = double.tryParse(_flags[0]['flag_lat'].toString()) ?? 0.0;
            final lng = double.tryParse(_flags[0]['flag_long'].toString()) ?? 0.0;
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
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _startLocationTracking() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

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
            _currentFlagIndex++;
          });

          if (_currentFlagIndex >= _flags.length) {
            _timer?.cancel();
          }
        }
      }

      _questionShown = false;
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

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(question['question_text'] ?? 'Question'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                Color? optionColor;
                if (submitted) {
                  final correct = question['question_answer'];
                  if (opt['question_option_id'] == correct) optionColor = Colors.green.shade300;
                  if (opt['question_option_id'] == selectedOption && selectedOption != correct) {
                    optionColor = Colors.red.shade300;
                  }
                }

                return Container(
                  color: optionColor,
                  child: RadioListTile<String>(
                    title: Text(opt['question_option_text']),
                    value: opt['question_option_id'],
                    groupValue: selectedOption,
                    onChanged: submitted
                        ? null
                        : (val) => setState(() => selectedOption = val),
                  ),
                );
              }).toList(),
            ),
            actions: [
              ElevatedButton(
                onPressed: selectedOption == null || submitted
                    ? null
                    : () {
                  submitted = true;
                  final correct = question['question_answer'];
                  result = selectedOption == correct;
                  setState(() {}); // refresh colors
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: result! ? Colors.green : Colors.red,
                        content: Text(
                          result! ? '✅ Correct Answer!' : '❌ Wrong Answer',
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
        });
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
    if (_flags.isEmpty || _currentFlagIndex >= _flags.length || _currentPosition == null) return 0.0;

    final nextFlag = _flags[_currentFlagIndex];
    final flagLat = double.tryParse(nextFlag['flag_lat'].toString()) ?? 0.0;
    final flagLong = double.tryParse(nextFlag['flag_long'].toString()) ?? 0.0;

    return _distanceCalc(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(flagLat, flagLong),
    ) / 1000;
  }

  void _cancelRun() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error || _run == null) return const Scaffold(body: Center(child: Text('Failed to load run data')));

    final runTitle = _run!['run_title'] ?? _run!['title'] ?? 'Run';

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade100]),
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
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                              builder: (ctx) => AlertDialog(
                                title: const Text('Cancel Run?'),
                                content: const Text('Are you sure you want to cancel your current run?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
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
                    Text('Time elapsed: ${_formatTime(_secondsElapsed)}', style: const TextStyle(fontSize: 16, color: Colors.white)),
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
                    initialCenter: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : (_flags.isNotEmpty
                        ? LatLng(
                      double.tryParse(_flags[0]['flag_lat'].toString()) ?? 0.0,
                      double.tryParse(_flags[0]['flag_long'].toString()) ?? 0.0,
                    )
                        : LatLng(0, 0)),
                    initialZoom: _currentZoom,
                    maxZoom: 18,
                    minZoom: 3,
                    onPositionChanged: (pos, _) => _currentZoom = pos.zoom,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.marc.proximityrundev'),
                    MarkerLayer(
                      markers: [
                        if (_currentPosition != null)
                          Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                          ),
                        ..._flags.map((flag) {
                          final lat = double.tryParse(flag['flag_lat'].toString()) ?? 0.0;
                          final lng = double.tryParse(flag['flag_long'].toString()) ?? 0.0;
                          final index = _flags.indexOf(flag);

                          Color color;
                          if (_flagAnswerStatus.containsKey(index)) {
                            color = _flagAnswerStatus[index]! ? Colors.green : Colors.red;
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
                              shadows: index == _currentFlagIndex
                                  ? [Shadow(color: Colors.orangeAccent.withValues(alpha:0.8), blurRadius: 10)]
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
                  final flagLat = double.tryParse(nextFlag['flag_lat'].toString()) ?? 0.0;
                  final flagLong = double.tryParse(nextFlag['flag_long'].toString()) ?? 0.0;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
