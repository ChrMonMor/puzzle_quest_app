import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/session_manager.dart';
import '../pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedAvatar = 'assets/androgynousDefault.png';
  String _username = 'John Doe';
  String _email = 'john@example.com';
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
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAvatar = prefs.getString('avatar') ?? _selectedAvatar;
      _username = prefs.getString('username') ?? _username;
      _email = prefs.getString('email') ?? _email;
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatar', _selectedAvatar);
    await prefs.setString('username', _username);
    await prefs.setString('email', _email);
    await prefs.setBool('darkMode', _isDarkMode);
    setState(() => _hasUnsavedChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

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

  Future<void> _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
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

          // Email Field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _email),
            onChanged: (value) {
              _email = value;
              setState(() => _hasUnsavedChanges = true);
            },
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

          // Appearance Toggle (Pill Style)
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
