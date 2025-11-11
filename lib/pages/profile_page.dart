import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {
  String _selectedAvatar = 'assets/androgynousDefault.png';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _joinDateController = TextEditingController();

  List<Map<String, String>> _runs = [];

  @override
  void initState() {
    super.initState();
    _usernameController.text = 'John Doe';
    _joinDateController.text = 'January 1, 2024';
    _loadProfile();
    _generateDummyRuns();
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

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    final savedJoinDate = prefs.getString('joinDate');
    final savedAvatar = prefs.getString('avatar');

    setState(() {
      _selectedAvatar = savedAvatar ?? _selectedAvatar;
      _usernameController.text =
      (savedUsername != null && savedUsername.isNotEmpty)
          ? savedUsername
          : _usernameController.text;
      _joinDateController.text =
      (savedJoinDate != null && savedJoinDate.isNotEmpty)
          ? savedJoinDate
          : _joinDateController.text;
    });
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


  void _generateDummyRuns() {
    _runs = List.generate(5, (i) => {'title': 'Run #${i + 1}'});
  }

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
        enabled: true, // ensures text always shows
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(run['title']!, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit ${run['title']} (not implemented)')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
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
