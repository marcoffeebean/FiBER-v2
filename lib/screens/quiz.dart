import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/module_model.dart';

class MiniQuiz extends StatefulWidget {
  const MiniQuiz({super.key});

  @override
  State<MiniQuiz> createState() => _MiniQuizState();
}

class _MiniQuizState extends State<MiniQuiz> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  List<Question> _questions = [];
  bool _finished = false;

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
      setState(() => _finished = true);
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
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6FAFF),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Mini Quiz',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _questions.isEmpty
            ? const Center(
                child: Text(
                  'No questions available.\nAsk your teacher to upload a module.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : _finished
                ? _buildResults()
                : _buildQuestion(),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Question ${_currentIndex + 1} of ${_questions.length}',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            minHeight: 8,
            backgroundColor: Colors.white,
            valueColor:
                const AlwaysStoppedAnimation(Colors.lightBlueAccent),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: Text(q.question,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        ...q.choices.asMap().entries.map((entry) {
          final i = entry.key;
          final choice = entry.value;
          Color bgColor = Colors.white;
          if (_answered) {
            if (i == q.correctIndex) bgColor = Colors.green.shade100;
            if (i == _selectedAnswer && i != q.correctIndex)
              bgColor = Colors.red.shade100;
          }
          return GestureDetector(
            onTap: () => _selectAnswer(i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _answered && i == q.correctIndex
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(choice,
                  style:
                      const TextStyle(fontWeight: FontWeight.w500)),
            ),
          );
        }),
        const Spacer(),
        if (_answered)
          ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _currentIndex + 1 >= _questions.length
                  ? 'See Results'
                  : 'Next Question',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildResults() {
    setState(() {
      DataService.addQuizTaken();
    });
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          const Text('Quiz Complete!',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Score: $_score / ${_questions.length}',
              style:
                  const TextStyle(fontSize: 20, color: Colors.black54)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _restart,
          ),
        ],
      ),
    );
  }
}