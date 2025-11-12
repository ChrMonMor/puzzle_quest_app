import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'view_run_page.dart';

class OverviewRunPage extends StatefulWidget {
  const OverviewRunPage({super.key});

  @override
  State<OverviewRunPage> createState() => _OverviewRunPageState();
}

class _OverviewRunPageState extends State<OverviewRunPage> {
  final List<Map<String, dynamic>> _runs = [];
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _loading = false;
  String? _nextPageUrl = 'http://pro-xi-mi-ty-srv/api/runs?page=1&per_page=12';

  final List<Map<String, dynamic>> _createdRuns = [];
  void addRun(Map<String, dynamic> run) => _createdRuns.add(run);
  List<Map<String, dynamic>> get createdRuns => List.unmodifiable(_createdRuns);

  @override
  void initState() {
    super.initState();
    _fetchRuns();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_loading &&
          _nextPageUrl != null) {
        _fetchRuns();
      }
    });
  }

  Future<void> _fetchRuns() async {
    if (_loading || _nextPageUrl == null) return;

    setState(() => _loading = true);

    try {
      final response = await http.get(Uri.parse(_nextPageUrl!));
      debugPrint('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        final List jsonData = decoded['data'];

        final apiRuns = jsonData.map((run) {
          final isPrivate = run['run_type']['run_type_name'] == 'Private';
          return {
            'id': run['run_id'],
            'title': run['run_title'],
            'type': run['run_type']['run_type_icon'],
            'description': run['run_description'],
            'kind': run['run_type']['run_type_name'],
            'public': !isPrivate,
            'code': run['run_pin'],
            'createdAt': DateTime.parse(run['run_added']),
            'updatedAt': DateTime.parse(run['run_last_update']),
          };
        }).toList();

        setState(() {
          _runs.addAll(apiRuns);
          _nextPageUrl = decoded['next_page_url'];
        });
      } else {
        throw Exception('Failed to load runs');
      }
    } catch (e) {
      debugPrint('Error fetching runs: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRuns {
    final combinedRuns = [..._runs, ...createdRuns];

    final publicMatches = combinedRuns.where((run) {
      final titleMatch = run['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      // Public runs appear in list if search matches or if search is empty
      return run['public'] && (_searchQuery.isEmpty || titleMatch);
    });

    final privateMatches = combinedRuns.where((run) {
      final codeMatch =
          run['code'].toString().toLowerCase() == _searchQuery.toLowerCase();
      // Private runs only appear if search matches exactly
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runsToShow = _filteredRuns;

    return Scaffold(
      appBar: AppBar(title: const Text('Overview Runs')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: runsToShow.isEmpty && _loading
                  ? const Center(child: CircularProgressIndicator())
                  : runsToShow.isEmpty
                  ? const Center(
                  child: Text('No runs found.',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                controller: _scrollController,
                itemCount:
                runsToShow.length + (_nextPageUrl != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < runsToShow.length) {
                    return _buildRunCard(runsToShow[index]);
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child:
                      Center(child: CircularProgressIndicator()),
                    );
                  }
                },
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
