enum QuizMode {
  multipleChoice,
  trueFalse,
  openEnded
}

class Quiz {
  final String subject;
  final String difficultyLevel;
  final int numberOfQuestions;
  final QuizMode mode;
  final int timerMinutes;
  
  Quiz({
    required this.subject,
    required this.difficultyLevel,
    required this.numberOfQuestions,
    required this.mode,
    required this.timerMinutes,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'difficultyLevel': difficultyLevel,
      'numberOfQuestions': numberOfQuestions,
      'mode': mode.toString(),
      'timerMinutes': timerMinutes,
    };
  }
  
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      subject: json['subject'],
      difficultyLevel: json['difficultyLevel'],
      numberOfQuestions: json['numberOfQuestions'],
      mode: QuizMode.values.firstWhere(
        (e) => e.toString() == json['mode'],
        orElse: () => QuizMode.multipleChoice,
      ),
      timerMinutes: json['timerMinutes'],
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  String? selectedAnswer;
  
  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.selectedAnswer,
  });
  
  bool isCorrect() {
    return selectedAnswer == correctAnswer;
  }
  
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'] ?? 'No explanation available.',
    );
  }
} 