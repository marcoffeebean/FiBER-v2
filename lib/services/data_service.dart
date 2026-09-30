import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../models/module_model.dart';

class DataService {
  static int quizzesTaken = 0;
  static int examsTaken = 0;
  static int gamesPlayed = 0;
  static int studySeconds = 0;

  static final List<Module> _modules = [];
  static final List<ClassRoom> _classes = [];
  static final List<String> _joinedClassCodes = [];
  static final List<String> _systemLogs = [];

  static List<Module> get modules => List.unmodifiable(_modules);
  static List<ClassRoom> get classes => List.unmodifiable(_classes);
  static List<String> get joinedClassCodes => List.unmodifiable(_joinedClassCodes);
  static List<String> get systemLogs => List.unmodifiable(_systemLogs);

  static final ValueNotifier<int> moduleUpdateNotifier = ValueNotifier(0);
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  static ThemeMode get themeMode => themeModeNotifier.value;

  static void setThemeMode(ThemeMode value) {
    themeModeNotifier.value = value;
  }

  // ── Study Timer ────────────────────────────────────────────────
  static Timer? _studyTimer;

  static void startStudyTimer() {
    _studyTimer?.cancel();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      studySeconds++;
    });
  }

  static void stopStudyTimer() {
    _studyTimer?.cancel();
    _studyTimer = null;
  }

  static void resetStudyTimer() {
    studySeconds = 0;
  }

  // ── Log helper ─────────────────────────────────────────────────
  static void _log(String message) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    _systemLogs.add('[$timestamp] $message');
  }

  static void addQuizTaken() {
    quizzesTaken++;
    _log('Quiz taken. Total: $quizzesTaken');
  }

  static void addExamTaken() {
    examsTaken++;
    _log('Mock Exam taken. Total: $examsTaken');
  }

  static void addGamePlayed() {
    gamesPlayed++;
    _log('Game played. Total: $gamesPlayed');
  }

  static void addStudyTime(int seconds) {
    studySeconds += seconds;
  }

  static int get studyMinutes => studySeconds ~/ 60;

  static String get studyTimeFormatted {
    final h = studySeconds ~/ 3600;
    final m = (studySeconds % 3600) ~/ 60;
    final s = studySeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Get file bytes from path or bytes ──────────────────────────
  static Future<Uint8List?> _getBytes({
    Uint8List? bytes,
    String? filePath,
  }) async {
    if (bytes != null) return bytes;
    if (filePath != null && !kIsWeb) {
      try {
        return await File(filePath).readAsBytes();
      } catch (e) {
        debugPrint('Error reading file from path: $e');
        return null;
      }
    }
    return null;
  }

  // ── Extract text from file ─────────────────────────────────────
  static Future<String> _extractText({
    required String fileName,
    Uint8List? bytes,
    String? filePath,
  }) async {
    try {
      final fileBytes = await _getBytes(bytes: bytes, filePath: filePath);
      if (fileBytes == null || fileBytes.isEmpty) {
        debugPrint('No bytes available for extraction');
        return '';
      }

      final fileLower = fileName.toLowerCase();

      if (fileLower.endsWith('.pdf')) {
        final document = PdfDocument(inputBytes: fileBytes);
        final text = PdfTextExtractor(document).extractText();
        document.dispose();
        debugPrint('PDF extracted: ${text.length} chars');
        return text;
      }

      if (fileLower.endsWith('.docx')) {
        final text = docxToText(fileBytes);
        debugPrint('DOCX extracted: ${text.length} chars');
        return text;
      }

      if (fileLower.endsWith('.txt')) {
        final text = utf8.decode(fileBytes);
        debugPrint('TXT extracted: ${text.length} chars');
        return text;
      }

      return '';
    } catch (e) {
      debugPrint('Text extraction error: $e');
      return '';
    }
  }

  // ── Generate questions from module content ─────────────────────
  static List<Question> _generateQuestions(String content) {
    final sentences = content
        .split(RegExp(r'[.!?]'))
        .map((s) => s.trim())
        .where((s) => s.split(' ').length > 5)
        .toList();

    if (sentences.length < 4) return [];

    final random = Random();
    sentences.shuffle(random);

    final List<Question> questions = [];

    for (int i = 0; i < min(10, sentences.length); i++) {
      final sentence = sentences[i];
      final words = sentence.split(' ');
      if (words.length < 4) continue;

      final keyword = words.firstWhere(
        (w) => w.length > 4 && RegExp(r'^[a-zA-Z]+$').hasMatch(w),
        orElse: () => '',
      );

      if (keyword.isEmpty) continue;

      final blankSentence = sentence.replaceFirst(keyword, '_____');

      final allWords = content
          .split(RegExp(r'[^a-zA-Z]+'))
          .where((w) =>
              w.length > 4 &&
              w != keyword &&
              RegExp(r'^[a-zA-Z]+$').hasMatch(w))
          .toSet()
          .toList();

      allWords.shuffle(random);
      final wrongAnswers = allWords.take(3).toList();
      if (wrongAnswers.length < 3) continue;

      final choices = [...wrongAnswers, keyword]..shuffle(random);

      questions.add(Question(
        question: blankSentence,
        choices: choices,
        correctIndex: choices.indexOf(keyword),
      ));
    }

    debugPrint('Generated ${questions.length} questions');
    return questions;
  }

  // ── Extract words for word hunt ────────────────────────────────
  static List<String> extractWordsForWordHunt(String content) {
    final words = content
        .toUpperCase()
        .split(RegExp(r'[^A-Z]+'))
        .where((w) => w.length >= 4 && w.length <= 10)
        .toSet()
        .toList();

    words.shuffle();
    return words.take(12).toList();
  }

  // ── Upload module ──────────────────────────────────────────────
  static void uploadModule(Module module) {
    _modules.add(module);
    _log('Module uploaded: ${module.title}');
    notifyModuleUpdated();
  }

  static Future<void> uploadModuleFile({
    required String title,
    required String fileName,
    Uint8List? bytes,
    String? filePath,
  }) async {
    debugPrint(
        'Uploading: $fileName | bytes: ${bytes?.length} | path: $filePath');

    String content = await _extractText(
      fileName: fileName,
      bytes: bytes,
      filePath: filePath,
    );

    debugPrint('Extracted content length: ${content.length}');
    if (content.length > 100) {
      debugPrint('Preview: ${content.substring(0, 100)}');
    }

    if (content.trim().isEmpty) {
      content =
          'Module content could not be extracted. Please re-upload the file.';
      debugPrint('Warning: extraction returned empty content for $fileName');
    }

    final questions = _generateQuestions(content);

    _modules.add(Module(
      title: title,
      content: content,
      questions: questions,
    ));

    _log(
        'Module uploaded: $fileName (${questions.length} questions generated)');
    notifyModuleUpdated();
  }

  // ── Delete module ──────────────────────────────────────────────
  static void deleteModule(int index) {
    if (index < 0 || index >= _modules.length) return;
    _log('Module deleted: ${_modules[index].title}');
    _modules.removeAt(index);
    notifyModuleUpdated();
  }

  // ── Class methods ──────────────────────────────────────────────
  static ClassRoom createClass(String name) {
    final newClass = ClassRoom(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _classes.add(newClass);
    _log('Class created: $name');
    return newClass;
  }

  static ClassRoom createClassWithCode(String name, String code) {
    final newClass = ClassRoom(id: code, name: name);
    _classes.add(newClass);
    _log('Class created: $name (code: $code)');
    return newClass;
  }

  static bool joinClass(String id) {
    final normalizedId = id.trim().toUpperCase();
    if (normalizedId.isEmpty) return false;

    final found = _classes.any((c) => c.id.toUpperCase() == normalizedId);
    if (found && !_joinedClassCodes.any((code) => code.toUpperCase() == normalizedId)) {
      _joinedClassCodes.add(normalizedId);
    }

    _log(
      'Student attempted to join class: $id — ${found ? 'success' : 'failed'}',
    );
    return found;
  }

  static void leaveClass(String id) {
    final normalizedId = id.trim().toUpperCase();
    _joinedClassCodes.removeWhere((code) => code.toUpperCase() == normalizedId);
  }

  static bool hasJoinedClass(String id) {
    final normalizedId = id.trim().toUpperCase();
    return _joinedClassCodes.any((code) => code.toUpperCase() == normalizedId);
  }

  static void notifyModuleUpdated() {
    moduleUpdateNotifier.value++;
  }
}