import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTest extends StatelessWidget {
  const FirestoreTest({super.key});

  // Step 3: Function to add a question
  void addQuestion() {
    FirebaseFirestore.instance.collection('questions').add({
      'text': 'What is aquaculture?',
      'choices': ['Fish farming', 'Mining', 'Forestry', 'Agriculture'],
      'answer': 'Fish farming',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore Test')),
      body: StreamBuilder(
        // Step 4: Display questions
        stream: FirebaseFirestore.instance.collection('questions').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return ListTile(
                title: Text(data['text'] ?? ''),
                subtitle: Text((data['choices'] as List<dynamic>).join(', ')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addQuestion,
        child: const Icon(Icons.add),
      ),
    );
  }
}