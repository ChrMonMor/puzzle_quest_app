import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> _runs = [];

  @override
  void initState() {
    super.initState();
    _generateDummyRuns();
  }

  void _generateDummyRuns() {
    final now = DateTime.now();
    _runs.addAll([
      {
        'title': 'Morning Trail',
        'type': '🌄',
        'start': now.subtract(const Duration(hours: 2, minutes: 15)),
        'end': now.subtract(const Duration(hours: 1, minutes: 30)),
        'status': 'Finished',
        'public': true,
      },
      {
        'title': 'Evening Hike',
        'type': '🥾',
        'start': now.subtract(const Duration(hours: 5)),
        'end': now.subtract(const Duration(hours: 3, minutes: 45)),
        'status': 'Finished',
        'public': false,
      },
      {
        'title': 'Obstacle Run',
        'type': '🧗‍♂️',
        'start': now.subtract(const Duration(days: 1, hours: 1)),
        'end': now.subtract(const Duration(days: 1)),
        'status': 'DNF',
        'public': true,
      },
      {
        'title': 'Training Session',
        'type': '🏃‍♂️',
        'start': now.subtract(const Duration(hours: 4)),
        'end': now.subtract(const Duration(hours: 3, minutes: 15)),
        'status': 'Finished',
        'public': false,
      },
    ]);
  }

  Widget _buildRunCard(int index) {
    final run = _runs[index];
    final start = DateFormat('dd/MM/yyyy HH:mm').format(run['start']);
    final end = DateFormat('dd/MM/yyyy HH:mm').format(run['end']);
    final duration = run['end'].difference(run['start']);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Type Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  run['title'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(run['type'], style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),

          // Times & Duration (stack vertically to prevent overflow)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Started: $start', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Ended: $end', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Time: ${hours}h ${minutes}m', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),

          // Status Pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: run['public'] ? Colors.green.shade300 : Colors.yellow.shade300,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                run['status'],
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Runs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_runs.isEmpty)
              const Text('You have no runs yet.', style: TextStyle(color: Colors.grey))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _runs.length,
                  itemBuilder: (context, index) => _buildRunCard(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
