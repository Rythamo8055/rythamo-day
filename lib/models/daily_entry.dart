/// Represents a single question-answer pair
class QuestionAnswer {
  final String question;
  final String answer;

  QuestionAnswer({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
  
  /// Check if this Q&A pair has an answer
  bool get hasAnswer => answer.trim().isNotEmpty;
}

/// Represents a daily journal entry containing all 4 questions and answers
class DailyEntry {
  final String id;
  final DateTime date;
  final List<QuestionAnswer> responses; // All 4 Q&A pairs
  final List<String> mediaPaths; // Paths to images/videos/audio
  final String? mascot; // Path to mascot animation

  DailyEntry({
    required this.id,
    required this.date,
    required this.responses,
    this.mediaPaths = const [],
    this.mascot,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'responses': responses.map((r) => r.toJson()).toList(),
      'mediaPaths': mediaPaths,
      'mascot': mascot,
    };
  }

  factory DailyEntry.fromJson(Map<String, dynamic> json) {
    return DailyEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      responses: (json['responses'] as List<dynamic>)
          .map((r) => QuestionAnswer.fromJson(r))
          .toList(),
      mediaPaths: List<String>.from(json['mediaPaths'] ?? []),
      mascot: json['mascot'],
    );
  }

  /// Get count of answered questions
  int get answeredCount => responses.where((r) => r.hasAnswer).length;
  
  /// Check if any question has been answered
  bool get hasAnyAnswer => responses.any((r) => r.hasAnswer);
  
  /// Create a copy with updated fields
  DailyEntry copyWith({
    String? id,
    DateTime? date,
    List<QuestionAnswer>? responses,
    List<String>? mediaPaths,
    String? mascot,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      responses: responses ?? this.responses,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      mascot: mascot ?? this.mascot,
    );
  }
}
