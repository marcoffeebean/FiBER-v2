import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/alumni_model.dart';
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
  static final List<AlumniProfile> _alumniProfiles = [];

  static List<Module> get modules => List.unmodifiable(_modules);
  static List<ClassRoom> get classes => List.unmodifiable(_classes);
  static List<String> get joinedClassCodes =>
      List.unmodifiable(_joinedClassCodes);
  static List<String> get systemLogs => List.unmodifiable(_systemLogs);
  static List<AlumniProfile> get alumniProfiles =>
      List.unmodifiable(_alumniProfiles);

  static List<AlumniProfile> get visibleAlumniProfiles => List.unmodifiable(
    [..._alumniProfiles.where((profile) => profile.isVisible)]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
  );

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static ValueNotifier<int> moduleUpdateNotifier = ValueNotifier(0);
  static ValueNotifier<ThemeMode>? _themeModeNotifier;
  static ValueNotifier<String>? _fontFamilyNotifier;
  static ValueNotifier<double>? _fontSizeNotifier;

  static ValueNotifier<ThemeMode> get themeModeNotifier =>
      _themeModeNotifier ??= ValueNotifier(ThemeMode.system);
  static ValueNotifier<String> get fontFamilyNotifier =>
      _fontFamilyNotifier ??= ValueNotifier('Roboto');
  static ValueNotifier<double> get fontSizeNotifier =>
      _fontSizeNotifier ??= ValueNotifier(14.0);

  static ThemeMode get themeMode => themeModeNotifier.value;
  static String get selectedFontFamily => fontFamilyNotifier.value;
  static double get fontScale => fontSizeNotifier.value / 14.0;

  static void setFontSize(double size) {
    fontSizeNotifier.value = size;
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

  // ── Get file bytes ─────────────────────────────────────────────
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

  // ── Strip XML tags, return plain text ─────────────────────────
  static String _stripXml(String xml) {
    return xml
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&apos;'), "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ── PPTX extraction ────────────────────────────────────────────
  // PPTX files are ZIP archives containing slide XML files.
  // Each slide is in ppt/slides/slide1.xml, slide2.xml, etc.
  static String _extractPptx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final slideBuffer = StringBuffer();

      // Collect slide files and sort by slide number
      final slideFiles = archive.files
          .where(
            (f) =>
                f.name.startsWith('ppt/slides/slide') &&
                f.name.endsWith('.xml') &&
                !f.name.contains('slideLayout') &&
                !f.name.contains('slideMaster'),
          )
          .toList();

      slideFiles.sort((a, b) {
        // Extract slide number from filename e.g. slide1.xml → 1
        final aNum =
            int.tryParse(
              RegExp(r'slide(\d+)\.xml').firstMatch(a.name)?.group(1) ?? '0',
            ) ??
            0;
        final bNum =
            int.tryParse(
              RegExp(r'slide(\d+)\.xml').firstMatch(b.name)?.group(1) ?? '0',
            ) ??
            0;
        return aNum.compareTo(bNum);
      });

      int slideNumber = 1;
      for (final file in slideFiles) {
        if (!file.isFile) continue;
        try {
          final xmlContent = utf8.decode(
            file.content as List<int>,
            allowMalformed: true,
          );

          // Extract text runs preserving paragraph breaks
          final paragraphs = <String>[];
          final paraMatches = RegExp(
            r'<a:p[>\s][^]*?</a:p>',
          ).allMatches(xmlContent);

          for (final para in paraMatches) {
            final paraXml = para.group(0) ?? '';
            // Extract text elements within paragraph
            final textParts = <String>[];
            final textMatches = RegExp(
              r'<a:t[>\s][^]*?</a:t>',
            ).allMatches(paraXml);
            for (final t in textMatches) {
              final raw = t.group(0) ?? '';
              final text = _stripXml(raw).trim();
              if (text.isNotEmpty) textParts.add(text);
            }
            final paraText = textParts.join(' ').trim();
            if (paraText.isNotEmpty) paragraphs.add(paraText);
          }

          if (paragraphs.isNotEmpty) {
            slideBuffer.writeln('--- Slide $slideNumber ---');
            for (final p in paragraphs) {
              slideBuffer.writeln(p);
            }
            slideBuffer.writeln();
          }
          slideNumber++;
        } catch (e) {
          debugPrint('Error reading slide ${file.name}: $e');
        }
      }

      final result = slideBuffer.toString().trim();
      debugPrint('PPTX extracted: ${result.length} chars, $slideNumber slides');
      return result;
    } catch (e) {
      debugPrint('PPTX extraction error: $e');
      return '';
    }
  }

  // ── Improved DOCX extraction ───────────────────────────────────
  // Uses docx_to_text as primary, falls back to manual XML parse
  static String _extractDocx(Uint8List bytes) {
    try {
      // Primary: use docx_to_text
      final text = docxToText(bytes);
      if (text.trim().isNotEmpty) {
        debugPrint('DOCX extracted via docx_to_text: ${text.length} chars');
        return text;
      }
    } catch (e) {
      debugPrint('docx_to_text failed: $e, trying manual extraction');
    }

    // Fallback: manual XML extraction from ZIP
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.files.firstWhere(
        (f) => f.name == 'word/document.xml',
        orElse: () => archive.files.first,
      );

      final xmlContent = utf8.decode(
        docFile.content as List<int>,
        allowMalformed: true,
      );

      // Extract paragraphs preserving structure
      final paragraphs = <String>[];
      final paraMatches = RegExp(r'<w:p[ >][^]*?</w:p>').allMatches(xmlContent);

      for (final para in paraMatches) {
        final paraXml = para.group(0) ?? '';
        final textParts = <String>[];
        final textMatches = RegExp(
          r'<w:t[^>]*>([^<]*)</w:t>',
        ).allMatches(paraXml);
        for (final t in textMatches) {
          final text = t.group(1)?.trim() ?? '';
          if (text.isNotEmpty) textParts.add(text);
        }
        final paraText = textParts.join(' ').trim();
        if (paraText.isNotEmpty) paragraphs.add(paraText);
      }

      final result = paragraphs.join('\n').trim();
      debugPrint('DOCX fallback extracted: ${result.length} chars');
      return result;
    } catch (e) {
      debugPrint('DOCX fallback extraction error: $e');
      return '';
    }
  }

  // ── Improved PDF extraction ────────────────────────────────────
  // Extracts text page by page to preserve reading order
  static String _extractPdf(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final pageBuffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        try {
          final pageText = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
          final trimmed = pageText.trim();
          if (trimmed.isNotEmpty) {
            pageBuffer.writeln('--- Page ${i + 1} ---');
            pageBuffer.writeln(trimmed);
            pageBuffer.writeln();
          }
        } catch (e) {
          debugPrint('Error extracting PDF page $i: $e');
        }
      }

      document.dispose();
      final result = pageBuffer.toString().trim();
      debugPrint(
        'PDF extracted: ${result.length} chars, ${document.pages.count} pages',
      );
      return result;
    } catch (e) {
      debugPrint('PDF extraction error: $e');
      // Fallback: extract all at once
      try {
        final document = PdfDocument(inputBytes: bytes);
        final text = PdfTextExtractor(document).extractText();
        document.dispose();
        debugPrint('PDF fallback extracted: ${text.length} chars');
        return text;
      } catch (e2) {
        debugPrint('PDF fallback also failed: $e2');
        return '';
      }
    }
  }

  // ── Main extraction dispatcher ─────────────────────────────────
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
        return _extractPdf(fileBytes);
      }

      if (fileLower.endsWith('.pptx') || fileLower.endsWith('.ppt')) {
        return _extractPptx(fileBytes);
      }

      if (fileLower.endsWith('.docx')) {
        return _extractDocx(fileBytes);
      }

      if (fileLower.endsWith('.txt')) {
        final text = utf8.decode(fileBytes, allowMalformed: true);
        debugPrint('TXT extracted: ${text.length} chars');
        return text;
      }

      debugPrint('Unsupported file format: $fileName');
      return '';
    } catch (e) {
      debugPrint('Text extraction error: $e');
      return '';
    }
  }

  // ── Generate questions from module content ─────────────────────
  static List<Question> _generateQuestions(String content) {
    // Clean page/slide markers before processing
    final cleanContent = content
        .replaceAll(RegExp(r'--- (Page|Slide) \d+ ---'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final sentences = cleanContent
        .split(RegExp(r'[.!?\n]'))
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

      final allWords = cleanContent
          .split(RegExp(r'[^a-zA-Z]+'))
          .where(
            (w) =>
                w.length > 4 &&
                w != keyword &&
                RegExp(r'^[a-zA-Z]+$').hasMatch(w),
          )
          .toSet()
          .toList();

      allWords.shuffle(random);
      final wrongAnswers = allWords.take(3).toList();
      if (wrongAnswers.length < 3) continue;

      final choices = [...wrongAnswers, keyword]..shuffle(random);

      questions.add(
        Question(
          question: blankSentence,
          choices: choices,
          correctIndex: choices.indexOf(keyword),
        ),
      );
    }

    debugPrint('Generated ${questions.length} questions');
    return questions;
  }

  // ── Extract words for word hunt ────────────────────────────────
  static List<String> extractWordsForWordHunt(String content) {
    final cleanContent = content
        .replaceAll(RegExp(r'--- (Page|Slide) \d+ ---'), '')
        .toUpperCase();

    final words = cleanContent
        .split(RegExp(r'[^A-Z]+'))
        .where((w) => w.length >= 4 && w.length <= 10)
        .toSet()
        .toList();

    words.shuffle();
    return words.take(12).toList();
  }

  // ── Upload module ──────────────────────────────────────────────
  static Future<void> uploadModule(Module module) async {
    try {
      final docRef = await _firestore.collection('modules').add({
        ...module.toMap(),
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      final savedModule = Module(
        id: docRef.id,
        title: module.title,
        content: module.content,
        questions: module.questions,
        isValid: module.isValid,
        fileName: module.fileName,
        fileType: module.fileType,
        fileUrl: module.fileUrl,
        fileSize: module.fileSize,
        pageCount: module.pageCount,
        uploadedAt: module.uploadedAt ?? DateTime.now(),
      );

      _modules.add(savedModule);

      _log('Module uploaded: ${module.title}');
      notifyModuleUpdated();
    } catch (e) {
      debugPrint('Error saving module to Firestore: $e');
      rethrow;
    }
  }

  static Future<void> uploadModuleFile({
    required String title,
    required String fileName,
    Uint8List? bytes,
    String? filePath,
  }) async {
    try {
      debugPrint(
        'Uploading: $fileName | bytes: ${bytes?.length} | path: $filePath',
      );

      // Read the original file bytes.
      final fileBytes = await _getBytes(bytes: bytes, filePath: filePath);

      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('The selected file is empty or could not be read.');
      }

      // Extract the document text.
      String content = await _extractText(
        fileName: fileName,
        bytes: fileBytes,
        filePath: filePath,
      );

      debugPrint('Extracted content length: ${content.length}');

      if (content.length > 200) {
        debugPrint('Preview: ${content.substring(0, 200)}');
      }

      if (content.trim().isEmpty) {
        content =
            'Module content could not be extracted. Please re-upload the file.';
      }

      // Generate quiz questions from the extracted content.
      final questions = _generateQuestions(content);

      // Get the file extension.
      final extension = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : '';
      // Save the module and metadata in Firestore.
      final docRef = await _firestore.collection('modules').add({
        'title': title,
        'content': content,
        'questions': questions.map((q) => q.toMap()).toList(),
        'isValid': true,
        'fileName': fileName,
        'fileType': extension,
        'fileUrl': null,
        'fileSize': fileBytes.length,
        'pageCount': null,
        'uploadedAt': DateTime.now().toUtc().toIso8601String(),
      });

      // Update the local list only after the cloud save succeeds.
      _modules.add(
        Module(
          id: docRef.id,
          title: title,
          content: content,
          questions: questions,
          fileName: fileName,
          fileType: extension,
          fileUrl: null,
          fileSize: fileBytes.length,
          uploadedAt: DateTime.now(),
        ),
      );

      _log(
        'Module uploaded: $fileName '
        '(${questions.length} questions generated)',
      );

      notifyModuleUpdated();
    } catch (e, stackTrace) {
      debugPrint('Error uploading module file: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // ── Delete module ──────────────────────────────────────────────
  static Future<void> deleteModule(int index) async {
    if (index < 0 || index >= _modules.length) return;

    final module = _modules[index];

    try {
      // Delete the original file from Storage when a URL exists.
      if (module.fileUrl != null && module.fileUrl!.isNotEmpty) {
        try {
          await _storage.refFromURL(module.fileUrl!).delete();
        } catch (e) {
          debugPrint('Could not delete the original module file: $e');
        }
      }

      // Delete the Firestore document.
      if (module.id != null && module.id!.isNotEmpty) {
        await _firestore.collection('modules').doc(module.id).delete();
      }

      _modules.removeAt(index);

      _log('Module deleted: ${module.title}');
      notifyModuleUpdated();
    } catch (e) {
      debugPrint('Error deleting module: $e');
      rethrow;
    }
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
    if (found &&
        !_joinedClassCodes.any((code) => code.toUpperCase() == normalizedId)) {
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

  // ── Load modules from Firestore ──────────────────────
  static Future<void> loadModules() async {
    try {
      final snapshot = await _firestore
          .collection('modules')
          .orderBy('uploadedAt', descending: true)
          .get();

      _modules
        ..clear()
        ..addAll(
          snapshot.docs.map((doc) {
            return Module.fromMap(doc.data(), id: doc.id);
          }),
        );

      notifyModuleUpdated();

      debugPrint('Loaded ${_modules.length} modules from Firestore.');
    } catch (e) {
      debugPrint('Error loading modules from Firestore: $e');
      rethrow;
    }
  }

  // ── Alumni profiles ─────────────────────────────────────────────
  static Future<List<AlumniProfile>> loadAlumniProfiles() async {
    try {
      final snapshot = await _firestore
          .collection('alumni_profiles')
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true)
          .get();

      final profiles = snapshot.docs
          .map((doc) => AlumniProfile.fromMap(doc.id, doc.data()))
          .where((profile) => profile.name.isNotEmpty)
          .toList();

      _alumniProfiles
        ..clear()
        ..addAll(profiles);

      return List.unmodifiable([..._alumniProfiles]);
    } catch (_) {
      _alumniProfiles
        ..clear()
        ..addAll(_seedAlumniProfiles());
      return List.unmodifiable([..._alumniProfiles]);
    }
  }

  static Future<void> saveAlumniProfile(AlumniProfile profile) async {
    try {
      final now = DateTime.now();
      final data = profile.toMap();
      final payload = {...data, 'updatedAt': now.toIso8601String()};

      final docId = profile.id.trim();
      if (docId.isEmpty) {
        final ref = await _firestore.collection('alumni_profiles').add(payload);
        _alumniProfiles.add(
          profile.copyWith(
            id: ref.id,
            updatedAt: now,
            createdAt: profile.createdAt,
          ),
        );
      } else {
        await _firestore
            .collection('alumni_profiles')
            .doc(docId)
            .set(payload, SetOptions(merge: true));

        final index = _alumniProfiles.indexWhere((item) => item.id == docId);
        if (index >= 0) {
          _alumniProfiles[index] = profile.copyWith(updatedAt: now);
        } else {
          _alumniProfiles.add(profile.copyWith(updatedAt: now));
        }
      }
      notifyModuleUpdated();
    } catch (_) {
      if (!_alumniProfiles.any((item) => item.id == profile.id)) {
        _alumniProfiles.add(profile);
      }
      notifyModuleUpdated();
    }
  }

  static Future<void> deleteAlumniProfile(String id) async {
    try {
      await _firestore.collection('alumni_profiles').doc(id).delete();
    } catch (_) {}

    _alumniProfiles.removeWhere((profile) => profile.id == id);
    notifyModuleUpdated();
  }

  static Future<String> uploadAlumniImage(
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      final storageRef = _storage.ref().child('alumni_profiles/$fileName');
      final uploadTask = await storageRef.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return '';
    }
  }

  static List<AlumniProfile> _seedAlumniProfiles() {
    final now = DateTime.now();
    return [
      AlumniProfile(
        id: 'sample-1',
        name: 'Marjorie Dela Cruz',
        title: 'Fisheries Officer',
        company: 'BFAR Region 8',
        batchYear: '2021',
        salary: '₱48,000/mo',
        imageUrl: '',
        highlight:
            'Now helping monitor fishery sustainability and coastal programs.',
        isVisible: true,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      AlumniProfile(
        id: 'sample-2',
        name: 'Rafael Santos',
        title: 'Quality Assurance Analyst',
        company: 'SeaFresh Foods',
        batchYear: '2019',
        salary: '₱62,000/mo',
        imageUrl: '',
        highlight:
            'Applies quality assurance and product safety standards in the seafood industry.',
        isVisible: true,
        displayOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      AlumniProfile(
        id: 'sample-3',
        name: 'Leah Magbanua',
        title: 'Aquaculture Specialist',
        company: 'Coastal Harvest',
        batchYear: '2022',
        salary: '₱55,000/mo',
        imageUrl: '',
        highlight:
            'Supports sustainable fish farming and production planning in local communities.',
        isVisible: true,
        displayOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
