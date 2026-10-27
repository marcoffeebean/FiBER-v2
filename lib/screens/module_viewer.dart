import 'package:flutter/material.dart';
import '../models/module_model.dart';

class ModuleViewer extends StatelessWidget {
  final Module module;

  const ModuleViewer({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            module.content,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ),
      ),
    );
  }
}
