import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'on_run_page.dart';

class ViewRunPage extends StatefulWidget {
  final Map<String, dynamic> run;

  const ViewRunPage({super.key, required this.run});

  @override
  State<ViewRunPage> createState() => _ViewRunPageState();
}

class _ViewRunPageState extends State<ViewRunPage> {
  Map<String, dynamic>? _detailedRun;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRunDetails();
  }

  Future<void> _fetchRunDetails() async {
    final runId = widget.run['id'];

    try {
      final url = Uri.parse('http://pro-xi-mi-ty-srv/api/runs/$runId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _detailedRun = decoded;
          _loading = false;
        });
      } else {
        throw Exception('Failed to load run details');
      }
    } catch (e) {
      debugPrint('Error fetching run details: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final run = _detailedRun ?? widget.run;
    final flags = (run['flags'] ?? []) as List;
    double? flagLat;
    double? flagLong;

    if (flags.isNotEmpty) {
      final firstFlag = flags.first;
      flagLat = double.tryParse(firstFlag['flag_lat'].toString());
      flagLong = double.tryParse(firstFlag['flag_long'].toString());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(run['run_title'] ?? widget.run['title'] ?? 'Run Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              run['run_title'] ?? widget.run['title'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Map
            if (flagLat != null && flagLong != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(flagLat, flagLong),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // static map for preview
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.marc.proximityrundev',
                        additionalOptions: const {
                          'User-Agent': 'ProximityRunDev/0.1 (marc8539edudev@gmail.com)',
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(flagLat, flagLong),
                            child: const Icon(Icons.flag, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  )
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No map data', style: TextStyle(fontSize: 18)),
                ),
              ),
            const SizedBox(height: 12),

            // Description
            Text(
              run['run_description'] ?? widget.run['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            // Start Run button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnRunPage(
                        runId: widget.run['id'].toString(),
                        run: widget.run,
                      ),
                    ),
                  );
                },
                child: const Text('Start Run'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
