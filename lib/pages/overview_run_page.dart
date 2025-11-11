import 'package:flutter/material.dart';
import 'view_run_page.dart';
import '../common/run_memory.dart';

class OverviewRunPage extends StatefulWidget {
  const OverviewRunPage({super.key});

  @override
  State<OverviewRunPage> createState() => _OverviewRunPageState();
}

class _OverviewRunPageState extends State<OverviewRunPage> {
  final List<Map<String, dynamic>> _runs = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _generateDummyRuns();
  }

  void _generateDummyRuns() {
    _runs.addAll([
      {
        'title': 'Morning Trail',
        'type': '🌄',
        'description': 'A refreshing early trail run.',
        'kind': 'Trail Run',
        'public': true,
        'code': 'n9dm3j',
        'createdAt': DateTime(2025, 11, 1),
        'updatedAt': DateTime(2025, 11, 2),
      },
      {
        'title': 'Evening Hike',
        'type': '🥾',
        'description': 'Leisurely hike after work.',
        'kind': 'Hike',
        'public': false,
        'code': '5hgj3n',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 4),
      },
      {
        'title': 'Obstacle Run',
        'type': '🧗‍♂️',
        'description': 'Tough obstacle training that tests strength and agility.',
        'kind': 'Obstacle Course',
        'public': true,
        'code': 'a9kdm2',
        'createdAt': DateTime(2025, 11, 3),
        'updatedAt': DateTime(2025, 11, 5),
      },
      {
        'title': 'Training Session',
        'type': '🏃‍♂️',
        'description': 'Focused fitness run to push your limits.',
        'kind': 'Fitness Run',
        'public': true,
        'code': '8bnm2k',
        'createdAt': DateTime(2025, 11, 1),
        'updatedAt': DateTime(2025, 11, 2),
      },
      {
        'title': 'Community Run',
        'type': '🕊️',
        'description': 'Casual community run for all ages.',
        'kind': 'Casual Run',
        'public': false,
        'code': '34djn2',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 3),
      },
      {
        'title': 'Zombie Chase',
        'type': '🧗‍♂️',
        'description': 'Run like the undead are right behind you. Heart-pumping fun!',
        'kind': 'Obstacle Course',
        'public': true,
        'code': '1jhksm',
        'createdAt': DateTime(2025, 11, 3),
        'updatedAt': DateTime(2025, 11, 5),
      },
      {
        'title': 'Coffee Sprint',
        'type': '🏃‍♂️',
        'description': 'Dash to the nearest café before it closes.',
        'kind': 'Fitness Run',
        'public': false,
        'code': '9askj1',
        'createdAt': DateTime(2025, 11, 4),
        'updatedAt': DateTime(2025, 11, 5),
      },
      {
        'title': 'Midnight Moon Jog',
        'type': '🌄',
        'description': 'Silvery night air, empty streets, perfect for introspection.',
        'kind': 'Trail Run',
        'public': true,
        'code': '3kgmsa',
        'createdAt': DateTime(2025, 11, 1),
        'updatedAt': DateTime(2025, 11, 3),
      },
      {
        'title': 'Doggy Dash',
        'type': '🕊️',
        'description': 'Bring your pup and see who gets tired first!',
        'kind': 'Casual Run',
        'public': true,
        'code': 'fi3jnb',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 3),
      },
      {
        'title': 'Parkour Playground',
        'type': '🧗‍♂️',
        'description': 'Leap over benches, walls, and your own limitations.',
        'kind': 'Obstacle Course',
        'public': false,
        'code': 'a8gjd2',
        'createdAt': DateTime(2025, 11, 3),
        'updatedAt': DateTime(2025, 11, 5),
      },
      {
        'title': 'Cloud Watching Walk',
        'type': '🕊️',
        'description': 'Slow stroll while spotting shapes in the sky.',
        'kind': 'Casual Run',
        'public': true,
        'code': '28vmw3',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 4),
      },
      {
        'title': 'Retro Roller Run',
        'type': '🏃‍♂️',
        'description': 'Skates on, music loud, feel the 80s vibe.',
        'kind': 'Fitness Run',
        'public': true,
        'code': 'rjopf8',
        'createdAt': DateTime(2025, 11, 1),
        'updatedAt': DateTime(2025, 11, 3),
      },
      {
        'title': 'Mystery Route',
        'type': '🗺️',
        'description': 'No one knows where we’re going—adventure guaranteed.',
        'kind': 'Objective Run',
        'public': false,
        'code': 'a8gmg3',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 5),
      },
      {
        'title': 'Giggle Gallop',
        'type': '🕊️',
        'description': 'Laughter-focused run. Try not to trip from laughing too hard!',
        'kind': 'Casual Run',
        'public': true,
        'code': 'a9gm2k',
        'createdAt': DateTime(2025, 11, 3),
        'updatedAt': DateTime(2025, 11, 4),
      },
      {
        'title': 'Forest Whisper',
        'type': '🌄',
        'description': 'Run quietly and listen to the secrets of the trees.',
        'kind': 'Trail Run',
        'public': true,
        'code': 'a8bhj2',
        'createdAt': DateTime(2025, 11, 1),
        'updatedAt': DateTime(2025, 11, 2),
      },
      {
        'title': 'Sunset Sprint',
        'type': '🏃‍♂️',
        'description': 'Race the sun to the horizon, feel the colors chase you.',
        'kind': 'Fitness Run',
        'public': false,
        'code': 'sd9thm',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 3),
      },
      {
        'title': 'Candy Dash',
        'type': '🏃‍♂️',
        'description': 'A sugary-fueled short sprint for the sweet-toothed.',
        'kind': 'Fitness Run',
        'public': true,
        'code': '1mg9am',
        'createdAt': DateTime(2025, 11, 3),
        'updatedAt': DateTime(2025, 11, 4),
      },
      {
        'title': 'Backyard Exploration',
        'type': '🌄',
        'description': 'Discover secret corners of your own neighborhood.',
        'kind': 'Trail Run',
        'public': false,
        'code': '1k8asm',
        'createdAt': DateTime(2025, 11, 1),
        'updatedAt': DateTime(2025, 11, 3),
      },
      {
        'title': 'Laughing Laps',
        'type': '🕊️',
        'description': 'Everyone tells a joke every lap—running never felt so silly.',
        'kind': 'Casual Run',
        'public': true,
        'code': 'a74hd8',
        'createdAt': DateTime(2025, 11, 2),
        'updatedAt': DateTime(2025, 11, 4),
      },
    ]);
  }


  List<Map<String, dynamic>> get _filteredRuns {
    // Combine dummy and created runs
    final combinedRuns = [...RunMemory.runs, ..._runs];

    // Always show public runs that match search
    final publicMatches = combinedRuns.where((run) {
      final titleMatch = run['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      return run['public'] && (_searchQuery.isEmpty || titleMatch);
    });

    // Allow searching private runs only by code
    final privateMatches = combinedRuns.where((run) {
      final codeMatch =
          run['code'].toString().toLowerCase() == _searchQuery.toLowerCase();
      return !run['public'] && codeMatch;
    });

    return [...publicMatches, ...privateMatches];
  }

  Widget _buildRunCard(Map<String, dynamic> run) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewRunPage(run: run),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Text(run['type'], style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run['title'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    run['description'],
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview Runs')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: _filteredRuns.isEmpty
                  ? const Center(
                  child: Text('No runs found.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _filteredRuns.length,
                itemBuilder: (context, index) => _buildRunCard(_filteredRuns[index]),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search runs...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

