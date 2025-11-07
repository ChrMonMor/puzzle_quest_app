import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedAvatar = 'assets/androgynousDefault.png'; // default avatar
  String _username = 'John Doe';
  String _email = 'john@example.com';
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';

  final List<String> _avatars = [
    'assets/maleDefault.png',
    'assets/femaleDefault.png',
    'assets/androgynousDefault.png',
    'assets/genderfluidDefault.png',
  ];

  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];

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
                  setState(() => _selectedAvatar = avatarPath);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
            onChanged: (value) => _username = value,
          ),
          const SizedBox(height: 16),

          // Email Field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _email),
            onChanged: (value) => _email = value,
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
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              // Apply theme change logic here if you use a theme provider
            },
          ),
          const SizedBox(height: 16),

          // Language Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Language',
              border: OutlineInputBorder(),
            ),
            items: _languages.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Text(lang),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedLanguage = value!),
          ),
        ],
      ),
    );
  }
}
