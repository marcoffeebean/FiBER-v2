import 'dart:async';
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/performance_service.dart';
import '../models/module_model.dart';

class MockExam extends StatefulWidget {
  const MockExam({super.key});

  @override
  State<MockExam> createState() => _MockExamState();
}

class _MockExamState extends State<MockExam> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  List<Question> _questions = [];
  bool _finished = false;
  bool _resultSaved = false;

  @override
  void initState() {
    super.initState();
    DataService.moduleUpdateNotifier.addListener(_onModuleUpdated);
    _loadQuestions();
  }

  @override
  void dispose() {
    DataService.moduleUpdateNotifier.removeListener(_onModuleUpdated);
    super.dispose();
  }

  void _onModuleUpdated() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _finished = false;
      _resultSaved = false;
      _loadQuestions();
    });
  }

  void _loadQuestions() {
    final modules = DataService.modules;

    if (modules.isEmpty) {
      _questions = [];
      return;
    }

    final module = modules.last;

    if (module.questions.isEmpty) {
      _questions = [];
      return;
    }

    _questions = List<Question>.from(module.questions);
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) _score++;
    });
  }

  void _next() {
    if (_currentIndex + 1 >= _questions.length) {
      setState(() {
        _finished = true;
        _resultSaved = false;
      });
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _finished = true;
      DataService.addExamTaken();
    });
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
        title: Text(
          'Mock Exam',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _questions.isEmpty
            ? Center(
                child: Text(
                  'No questions available.\nAsk your teacher to upload a module.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            : _finished
            ? _buildResults(theme)
            : Padding(
                padding: const EdgeInsets.all(16),
                child: _buildQuestion(theme),
              ),
      ),
    );
  }

  Widget _buildQuestion(ThemeData theme) {
    final q = _questions[_currentIndex];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation(Colors.lightBlueAccent),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              q.question,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...q.choices.asMap().entries.map((entry) {
            final i = entry.key;
            final choice = entry.value;
            Color bgColor = theme.colorScheme.surface;
            if (_answered) {
              if (i == q.correctIndex) bgColor = Colors.green.shade100;
              if (i == _selectedAnswer && i != q.correctIndex) bgColor = Colors.red.shade100;
            }
            return GestureDetector(
              onTap: () => _selectAnswer(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _answered && i == q.correctIndex
                        ? Colors.green
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  choice,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (_answered)
            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentIndex + 1 >= _questions.length
                    ? 'See Results'
                    : 'Next Question',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (!_resultSaved) {
      _resultSaved = true;
      DataService.addExamTaken();
      final moduleTitle = _questions.isNotEmpty ? DataService.modules.isNotEmpty ? DataService.modules.last.title : 'General' : 'General';
      unawaited(PerformanceService.recordAssessmentResult(
        type: 'mock_exam',
        score: _score,
        total: _questions.length,
        subject: moduleTitle,
        moduleTitle: moduleTitle,
      ));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Exam Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Score: $_score / ${_questions.length}',
            style: TextStyle(fontSize: 20, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _restart,
          ),
        ],
      ),
    );
  }
}
