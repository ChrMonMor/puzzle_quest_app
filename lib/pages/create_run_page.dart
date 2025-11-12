import 'dart:math';
import 'package:flutter/material.dart';
import '../common/run_memory.dart';

class CreateRunPage extends StatefulWidget {
  const CreateRunPage({super.key});

  @override
  State<CreateRunPage> createState() => _CreateRunPageState();
}

class _CreateRunPageState extends State<CreateRunPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = '🏃‍♂️ Fitness Run';
  bool _isPublic = false;
  final List<Question> _questions = [];
  late final String _runCode;

  final List<Map<String, String>> runTypes = [
    {'emoji': '🏃‍♂️', 'label': 'Fitness Run'},
    {'emoji': '🕊️', 'label': 'Casual Run'},
    {'emoji': '🌄', 'label': 'Trail Run'},
    {'emoji': '🧗‍♂️', 'label': 'Obstacle Course'},
    {'emoji': '🗺️', 'label': 'Objective Run'},
    {'emoji': '🥾', 'label': 'Hike'},
  ];

  @override
  void initState() {
    super.initState();
    _runCode = _generateRunCode();
  }

  String _generateRunCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(Question());
    });
  }

  void _deleteQuestion(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _questions.removeAt(index);
      });
    }
  }

  void _createRun() {
    final runData = {
      'title': _titleController.text.trim().isEmpty
          ? 'Untitled Run'
          : _titleController.text.trim(),
      'type': _selectedType.split(' ').first,
      'description': _descriptionController.text.trim(),
      'kind': _selectedType.split(' ').sublist(1).join(' '),
      'public': _isPublic,
      'code': _runCode.toLowerCase(),
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    // Save temporarily in memory
    RunMemory.addRun(runData);

    // Go back to BaseNavigation and switch to Overview tab
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Pop CreateRunPage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Run'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createRun,
            tooltip: 'Create Run',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Run Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Run Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Type selector
            const Text('Select Run Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: runTypes.map((type) {
                final isSelected = _selectedType == '${type['emoji']} ${type['label']}';
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = '${type['emoji']} ${type['label']}';
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      type['emoji']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Run Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Questions Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green, size: 32),
                  onPressed: _addQuestion,
                ),
              ],
            ),
            const SizedBox(height: 10),

            Column(
              children: _questions.asMap().entries.map((entry) {
                final index = entry.key;
                final q = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question title
                        TextField(
                          controller: q.titleController,
                          decoration: const InputDecoration(labelText: 'Question Title'),
                        ),
                        const SizedBox(height: 10),

                        // Answer type selector + location + delete
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: q.answerType,
                                items: const [
                                  DropdownMenuItem(value: 'Paragraph', child: Text('Paragraph')),
                                  DropdownMenuItem(value: 'Multiple Choice', child: Text('Multiple Choice')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    q.answerType = value!;
                                  });
                                },
                                decoration: const InputDecoration(labelText: 'Answer Type'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.location_pin, color: Colors.redAccent),
                              onPressed: () {}, // placeholder
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteQuestion(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Multiple Choice Options
                        if (q.answerType == 'Multiple Choice')
                          Column(
                            children: [
                              ...q.options.asMap().entries.map((opt) {
                                final optIndex = opt.key;
                                final optController = opt.value;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: optController,
                                        decoration: InputDecoration(
                                          labelText: 'Option ${optIndex + 1}',
                                        ),
                                      ),
                                    ),
                                    Radio<int>(
                                      value: optIndex,
                                      groupValue: q.correctIndex,
                                      onChanged: (val) {
                                        setState(() {
                                          q.correctIndex = val;
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    q.options.add(TextEditingController());
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Option'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Privacy selector
            const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Private'),
                  selected: !_isPublic,
                  onSelected: (_) => setState(() => _isPublic = false),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Public'),
                  selected: _isPublic,
                  onSelected: (_) => setState(() => _isPublic = true),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Run code display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Run Code:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_runCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Question model
class Question {
  final TextEditingController titleController = TextEditingController();
  String answerType = 'Paragraph';
  final List<TextEditingController> options = [];
  int? correctIndex;
}
