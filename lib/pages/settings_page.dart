import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../common/session_manager.dart';
import '../pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedAvatar = 'assets/androgynousDefault.png';
  String _username = '';
  String _email = '';
  bool _isDarkMode = false;
  bool _hasUnsavedChanges = false;

  final List<String> _avatars = [
    'assets/maleDefault.png',
    'assets/femaleDefault.png',
    'assets/androgynousDefault.png',
    'assets/genderfluidDefault.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ------------------- API: Load User Profile -------------------
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://pro-xi-mi-ty-srv/api/user'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch profile: ${response.statusCode}');
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _username = data['user_name'] ?? '';
          _email = data['user_email'] ?? '';
          _selectedAvatar = 'assets/${data['user_img'] ?? 'androgynousDefault.png'}';
          _isDarkMode = prefs.getBool('darkMode') ?? false;
        });

        // Store in prefs for ProfilePage sync
        await prefs.setString('username', _username);
        await prefs.setString('email', _email);
        await prefs.setString('avatar', _selectedAvatar);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user profile')),
        );
      }
    } catch (e) {
      print('Error loading user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    }
  }

  // ------------------- API: Update Profile -------------------
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in')),
      );
      return;
    }

    final imageFileName = _selectedAvatar.split('/').last;

    try {
      final response = await http.patch(
        Uri.parse('http://pro-xi-mi-ty-srv/api/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'username': _username,
          'image': imageFileName,
        }),
      );

      print('Update profile: ${response.statusCode}');
      print(response.body);

      if (response.statusCode == 200) {
        // Update prefs for consistency
        await prefs.setString('username', _username);
        await prefs.setString('avatar', _selectedAvatar);
        await prefs.setString('email', _email);
        await prefs.setBool('darkMode', _isDarkMode);

        setState(() => _hasUnsavedChanges = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating profile')),
      );
    }
  }

  // ------------------- Logout -------------------
  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  // ------------------- UI Helpers -------------------
  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            children: _avatars.map((avatarPath) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatarPath;
                    _hasUnsavedChanges = true;
                  });
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(avatarPath),
                    radius: 40,
                    child: _selectedAvatar == avatarPath
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text(
          'Are you sure you want to reset your password? You will receive an email with instructions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appearance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.grey.shade300,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isDarkMode) {
                      setState(() {
                        _isDarkMode = false;
                        _hasUnsavedChanges = true;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isDarkMode
                          ? Colors.orangeAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      color: !_isDarkMode ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isDarkMode) {
                      setState(() {
                        _isDarkMode = true;
                        _hasUnsavedChanges = true;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.indigo
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.nightlight_round,
                      color: _isDarkMode ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------- Build UI -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.save,
              color: _hasUnsavedChanges
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: _hasUnsavedChanges ? _saveSettings : null,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar Section
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showAvatarSelectionDialog,
                  child: CircleAvatar(
                    backgroundImage: AssetImage(_selectedAvatar),
                    radius: 50,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tap to change picture'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Username Field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _username),
            onChanged: (value) {
              _username = value;
              setState(() => _hasUnsavedChanges = true);
            },
          ),
          const SizedBox(height: 16),

          // Email Field (read-only if not editable)
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _email),
            readOnly: true,
          ),
          const SizedBox(height: 16),

          // Reset Password Button
          ElevatedButton(
            onPressed: _showResetPasswordDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Password'),
          ),
          const Divider(height: 32),

          // Appearance Toggle
          _buildAppearanceToggle(),
          const Divider(height: 32),

          // Logout Button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 45),
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
