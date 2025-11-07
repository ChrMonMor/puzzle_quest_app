import 'package:flutter/material.dart';
import 'common/base_navigation.dart';

void main() {
  runApp(const PuzzleQuestApp());
}

class PuzzleQuestApp extends StatelessWidget {
  const PuzzleQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Puzzle Quest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
        home: BaseNavigation(),
    );
  }
}
