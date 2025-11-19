import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../common/session_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {
  String _selectedAvatar = 'assets/androgynousDefault.png';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _joinDateController = TextEditingController();

  List<Map<String, dynamic>> _runs = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchRuns();
  }

  @override
  void didPopNext() {
    _refreshAvatar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _joinDateController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // ---------------- API ----------------

  Future<void> _fetchUserProfile({bool retrying = false}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    token = await SessionManager.ensureGuestToken() ?? token;
    if (token == null) return; // No token available

    http.Response? response;
    try {
      response = await http.post(
        Uri.parse('http://pro-xi-mi-ty-srv/api/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Profile status: ${response.statusCode}');
      print('Profile body: ${response.body}');
    } catch (e) {
      print('API call failed: $e');
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _usernameController.text = data['user_name'] ?? '';
        _joinDateController.text = _formatJoinDate(data['user_joined']);
        _selectedAvatar = 'assets/${data['user_img']}';
      });
    } else if (response.statusCode == 401 && !retrying) {
      // Token expired; refresh guest token then retry once
      final newToken = await SessionManager.refreshExpiredToken();
      if (newToken != null) {
        await _fetchUserProfile(retrying: true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired, unable to refresh')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile (${response.statusCode})')),
      );
    }
  }

  Future<void> _refreshAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAvatar = prefs.getString('avatar');
    if (savedAvatar != null && savedAvatar != _selectedAvatar) {
      setState(() {
        _selectedAvatar = savedAvatar;
      });
    }
  }

  Future<void> _fetchRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://pro-xi-mi-ty-srv/api/runs/mine'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Runs status code: ${response.statusCode}');
      print('Runs body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['runs'] != null) {
          setState(() {
            _runs = List<Map<String, dynamic>>.from(data['runs']);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load runs')),
        );
      }
    } catch (e) {
      print('Failed to fetch runs: $e');
    }
  }


  // ---------------- Helpers ----------------
  void _confirmDeleteRun(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Run'),
        content: Text('Are you sure you want to delete ${_runs[index]['title']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _runs.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Run deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _infoField({
    required String label,
    required TextEditingController controller,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        readOnly: true,
        enabled: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }

  Widget _buildRunCard(int index) {
    final run = _runs[index];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line 1: run_type_icon + run_type_name (font size 10)
          Row(
            children: [
              Text(
                run['run_type']['run_type_icon'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                run['run_type']['run_type_name'] ?? '',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Line 2: run_title
          Text(
            run['run_title'] ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),

          // Line 3: run_description
          Text(
            run['run_description'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 4),

          // Line 4: run_pin
          Text(
            'PIN: ${run['run_pin'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),

          // Edit/Delete buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit ${run['run_title']} (not implemented)')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _confirmDeleteRun(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Utilities ----------------

  String _formatJoinDate(String? dateString) {
    if (dateString == null) return '';
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'March', 'April', 'May', 'June',
      'July', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Picture
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(_selectedAvatar),
                  radius: 50,
                ),
                const SizedBox(height: 8),
                const Text('Profile Picture', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Username and Join Date Fields
          Row(
            children: [
              _infoField(label: 'Username', controller: _usernameController),
              const SizedBox(width: 12),
              _infoField(label: 'Join Date', controller: _joinDateController),
            ],
          ),
          const SizedBox(height: 24),

          // Runs Section
          const Text(
            'Your Runs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_runs.isEmpty)
            const Text('You have no runs yet.', style: TextStyle(color: Colors.grey))
          else
            ...List.generate(_runs.length, _buildRunCard),
        ],
      ),
    );
  }
}
