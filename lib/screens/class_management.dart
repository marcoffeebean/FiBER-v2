import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../services/data_service.dart';

class ClassManagement extends StatefulWidget {
  const ClassManagement({super.key});

  @override
  State<ClassManagement> createState() => _ClassManagementState();
}

class _ClassManagementState extends State<ClassManagement> {
  final TextEditingController _nameCtrl = TextEditingController();

  // ── Generate short readable class code ────────────────────────
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random();
    final existing = DataService.classes.map((c) => c.id).toSet();
    String code;
    do {
      code = List.generate(7, (_) => chars[random.nextInt(chars.length)]).join();
    } while (existing.contains(code));
    return code;
  }

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final code = _generateClassCode();
    DataService.createClassWithCode(name, code);
    _nameCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Class Management',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'New class name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _create,
            ),
            const SizedBox(height: 20),
            const Text(
              'Existing Classes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DataService.classes.isEmpty
                  ? const Center(
                      child: Text(
                        'No classes created yet.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: DataService.classes.length,
                      itemBuilder: (_, i) {
                        final c = DataService.classes[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(
                              Icons.class_,
                              color: Colors.lightBlueAccent,
                            ),
                            title: Text(
                              c.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Code: ${c.id}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copy class code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: c.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Class code copied!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}