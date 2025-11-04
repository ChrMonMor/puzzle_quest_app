import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

    // Hash the password using SHA-256
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final url = Uri.parse('http://pro-xi-mi-ty-srv/api/register');

    final response = await http.post(
    url,
    headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    },
    body: jsonEncode({
    'username': username,
    'email': email,
    'password': hashedPassword,
    }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
    // Registration successful
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration successful!')));
    } else {
    // Error
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: ${response.body}')));
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
// Logo
                  Image.asset('assets/logo.png', height: 100),
              SizedBox(height: 16),

          // App Name
          Text('Puzzle Quest', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

          SizedBox(height: 32),

          // Username
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
            maxLength: 255,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a username';
              if (value.length > 255) return 'Username cannot be longer than 255 characters';
              return null;
            },
          ),

          SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter an email';
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
              return null;
            },
          ),

          SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),

          SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),

          SizedBox(height: 32),

          // Register Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ),
          ],
        ),
      ),
    ),
    ),
    );
  }
}
