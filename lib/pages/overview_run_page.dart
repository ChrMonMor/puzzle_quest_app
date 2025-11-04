import 'package:flutter/material.dart';

class OverviewRunPage extends StatelessWidget {
  const OverviewRunPage ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview Runs'),
      ),
      body: const Center(
        child: Text(
          'This is the Overview Runs page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
