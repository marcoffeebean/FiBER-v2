class Module {
  final String title;
  final String content;
  final List<Question> questions; // optional list of quiz questions related to this module
  // more fields can be added (e.g., questions, flashcards, etc.)
  final bool isValid;
  
  Module({
    required this.title, 
    required this.content,
    this.questions = const [],// default to true if not provided
    this.isValid = true, 
    });
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
}
// simple class representation for teacher/student
class ClassRoom {
  final String id;
  final String name;

  ClassRoom({
    required this.id, 
    required this.name
    });
}
