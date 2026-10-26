class AlumniProfile {
  final String id;
  final String name;
  final String title;
  final String company;
  final String batchYear;
  final String salary;
  final String imageUrl;
  final String highlight;
  final bool isVisible;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlumniProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.batchYear,
    required this.salary,
    required this.imageUrl,
    required this.highlight,
    required this.isVisible,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlumniProfile.fromMap(String id, Map<String, dynamic> map) {
    return AlumniProfile(
      id: id,
      name: (map['name'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      company: (map['company'] ?? '').toString(),
      batchYear: (map['batchYear'] ?? '').toString(),
      salary: (map['salary'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      highlight: (map['highlight'] ?? '').toString(),
      isVisible: map['isVisible'] == true,
      displayOrder: (map['displayOrder'] is int)
          ? map['displayOrder'] as int
          : int.tryParse((map['displayOrder'] ?? '0').toString()) ?? 0,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : (map['updatedAt'] is String
              ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'company': company,
      'batchYear': batchYear,
      'salary': salary,
      'imageUrl': imageUrl,
      'highlight': highlight,
      'isVisible': isVisible,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AlumniProfile copyWith({
    String? id,
    String? name,
    String? title,
    String? company,
    String? batchYear,
    String? salary,
    String? imageUrl,
    String? highlight,
    bool? isVisible,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlumniProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      company: company ?? this.company,
      batchYear: batchYear ?? this.batchYear,
      salary: salary ?? this.salary,
      imageUrl: imageUrl ?? this.imageUrl,
      highlight: highlight ?? this.highlight,
      isVisible: isVisible ?? this.isVisible,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
