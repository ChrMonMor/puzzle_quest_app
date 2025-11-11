import 'package:flutter/material.dart';

class ViewRunPage extends StatelessWidget {
  final Map<String, dynamic> run;

  const ViewRunPage({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(run['title']),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Created/Updated box
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  run['title'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Created: ${run['createdAt'].toString().split(' ')[0]}',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                      Text(
                        'Updated: ${run['updatedAt'].toString().split(' ')[0]}',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Type + Kind and Public/Private
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${run['type']} ${run['kind']}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  run['public'] ? 'Public' : 'Private',
                  style: TextStyle(
                      fontSize: 16,
                      color: run['public'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // MAP placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('MAP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),

            // Full description
            Text(
              run['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),

            // Start Run button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {

                },
                child: const Text('Start Run'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
