import 'package:flutter/material.dart';

class CreateRunPage extends StatelessWidget {
  const CreateRunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Run'),
      ),
      body: const Center(
        child: Text(
          'This is the Create Run Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
