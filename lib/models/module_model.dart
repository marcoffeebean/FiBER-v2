class Module {
  final String? id;
  final String title;
  final String content;
  final List<Question> questions;
  final bool isValid;

  // Original uploaded file information
  final String? fileName;
  final String? fileType;
  final String? fileUrl;
  final int? fileSize;
  final int? pageCount;
  final DateTime? uploadedAt;

  Module({
    this.id,
    required this.title,
    required this.content,
    this.questions = const [],
    this.isValid = true,
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.fileSize,
    this.pageCount,
    this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isValid': isValid,
      'fileName': fileName,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'uploadedAt': uploadedAt == null
          ? null
          : uploadedAt!.toUtc().toIso8601String(),
    };
  }

  factory Module.fromMap(Map<String, dynamic> map, {String? id}) {
    return Module(
      id: id,
      title: map['title'] as String? ?? 'Untitled Module',
      content: map['content'] as String? ?? '',
      questions: (map['questions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((q) => Question.fromMap(Map<String, dynamic>.from(q)))
          .toList(),
      isValid: map['isValid'] as bool? ?? true,
      fileName: map['fileName'] as String?,
      fileType: map['fileType'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileSize: (map['fileSize'] as num?)?.toInt(),
      pageCount: (map['pageCount'] as num?)?.toInt(),
      uploadedAt: DateTime.tryParse(map['uploadedAt'] as String? ?? ''),
    );
  }
}

class Question {
  final String question;
  final List<String> choices;
  final int correctIndex;

  Question({
    required this.question,
    required this.choices,
    required this.correctIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'choices': choices,
      'correctIndex': correctIndex,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      question: map['question'] as String? ?? '',
      choices: (map['choices'] as List<dynamic>? ?? [])
          .map((choice) => choice.toString())
          .toList(),
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassRoom {
  final String id;
  final String name;

  ClassRoom({required this.id, required this.name});
}
