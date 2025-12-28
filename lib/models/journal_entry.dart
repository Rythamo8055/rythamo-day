class JournalEntry {
  final String id;
  final DateTime date;
  final String question;
  final String answer;
  final List<String> mediaPaths; // Paths to images/videos/audio
  final String? mascot; // Path to mascot animation

  JournalEntry({
    required this.id,
    required this.date,
    required this.question,
    required this.answer,
    this.mediaPaths = const [],
    this.mascot,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'question': question,
      'answer': answer,
      'mediaPaths': mediaPaths,
      'mascot': mascot,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      question: json['question'],
      answer: json['answer'],
      mediaPaths: List<String>.from(json['mediaPaths']),
      mascot: json['mascot'],
    );
  }
}
