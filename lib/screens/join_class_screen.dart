import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/module_model.dart';
import '../services/data_service.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  List<String> get _joinedClasses => DataService.joinedClassCodes;

  void _showJoinDialog() {
    final codeCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Join Class',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter class code',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  errorText: error,
                ),
                onChanged: (_) => setDialogState(() => error = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                final code = codeCtrl.text.trim().toUpperCase();
                if (code.isEmpty) {
                  setDialogState(() => error = 'Please enter a class code');
                  return;
                }

                if (DataService.hasJoinedClass(code)) {
                  setDialogState(
                      () => error = 'You already joined this class');
                  return;
                }

                final success = DataService.joinClass(code);
                if (success) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Joined class successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  setDialogState(
                      () => error = 'Class not found. Check the code.');
                }
              },
              child: const Text('Join Class'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 0,
        leading: BackButton(color: theme.colorScheme.onSurface),
        title: Text('My Classes',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Join a Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showJoinDialog,
            ),
            const SizedBox(height: 24),
            Text('Joined Classes',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Expanded(
              child: _joinedClasses.isEmpty
                  ? Center(
                      child: Text(
                        'You have not joined any classes yet.\nTap "Join a Class" to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _joinedClasses.length,
                      itemBuilder: (_, i) {
                        final code = _joinedClasses[i];
                        final classRoom = DataService.classes
                            .firstWhere((c) => c.id == code,
                                orElse: () => ClassRoom(
                                    id: code, name: 'Class $code'));
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.lightBlueAccent,
                              child: Icon(Icons.class_,
                                  color: Colors.white),
                            ),
                            title: Text(classRoom.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface)),
                            subtitle: Text('Code: $code',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              tooltip: 'Copy code',
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Class code copied!')),
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