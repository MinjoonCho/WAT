class TestItem {
  static const String defaultNamingInstruction = '이것이 무엇인가요?';
  static const String defaultDescriptionInstruction = '이것에 대해 설명해보세요.';
  static const String defaultChoiceQuestion = '이것과 관련 있는 것을 골라보세요.';
  static int _idSeed = 0;

  static String _generateId() {
    _idSeed += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idSeed';
  }

  String id;
  String name;
  String? imagePath;
  bool isPractice;
  String namingInstruction;
  String descInstruction;
  String? practiceDescExample;
  String choiceQuestion;
  String option1;
  String? option1ImagePath;
  String option2;
  String? option2ImagePath;
  int correctOptionIndex;
  String? practiceAnswerExplanation;

  TestItem({
    String? id,
    required this.name,
    this.imagePath,
    this.isPractice = false,
    this.namingInstruction = defaultNamingInstruction,
    this.descInstruction = defaultDescriptionInstruction,
    this.practiceDescExample,
    this.choiceQuestion = defaultChoiceQuestion,
    this.option1 = '',
    this.option1ImagePath,
    this.option2 = '',
    this.option2ImagePath,
    this.correctOptionIndex = 1,
    this.practiceAnswerExplanation,
  }) : id = id ?? _generateId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'isPractice': isPractice,
        'namingInstruction': namingInstruction,
        'descInstruction': descInstruction,
        'practiceDescExample': practiceDescExample,
        'choiceQuestion': choiceQuestion,
        'option1': option1,
        'option1ImagePath': option1ImagePath,
        'option2': option2,
        'option2ImagePath': option2ImagePath,
        'correctOptionIndex': correctOptionIndex,
        'practiceAnswerExplanation': practiceAnswerExplanation,
      };

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        id: json['id'],
        name: json['name'] ?? '',
        imagePath: json['imagePath'],
        isPractice: json['isPractice'] ?? false,
        namingInstruction:
            json['namingInstruction'] ?? defaultNamingInstruction,
        descInstruction:
            json['descInstruction'] ?? defaultDescriptionInstruction,
        practiceDescExample: json['practiceDescExample'],
        choiceQuestion: json['choiceQuestion'] ?? defaultChoiceQuestion,
        option1: json['option1'] ?? '',
        option1ImagePath: json['option1ImagePath'],
        option2: json['option2'] ?? '',
        option2ImagePath: json['option2ImagePath'],
        correctOptionIndex: json['correctOptionIndex'] ?? 1,
        practiceAnswerExplanation: json['practiceAnswerExplanation'],
      );
}
