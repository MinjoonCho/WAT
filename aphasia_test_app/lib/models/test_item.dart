class TestItem {
  String name;
  String? imagePath;
  bool isPractice;

  // 명칭 단계
  String namingInstruction;

  // 설명 단계
  String descInstruction;

  // 연습문항 전용 — 설명 예시 텍스트 (슬라이드6 하단)
  String? practiceDescExample;

  // 선택지 단계
  String choiceQuestion;
  String option1;
  String? option1ImagePath;
  String option2;
  String? option2ImagePath;

  // 정답 (1 또는 2) — CSV 정오 기록 및 연습문항 피드백에 사용
  int correctOptionIndex;

  // 연습문항 전용 — 정답 해설 텍스트 (슬라이드9 상단)
  String? practiceAnswerExplanation;

  TestItem({
    required this.name,
    this.imagePath,
    this.isPractice = false,
    this.namingInstruction = '이게 뭐죠?',
    this.descInstruction = '',
    this.practiceDescExample,
    this.choiceQuestion = '',
    this.option1 = '',
    this.option1ImagePath,
    this.option2 = '',
    this.option2ImagePath,
    this.correctOptionIndex = 1,
    this.practiceAnswerExplanation,
  });

  Map<String, dynamic> toJson() => {
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
        name: json['name'] ?? '',
        imagePath: json['imagePath'],
        isPractice: json['isPractice'] ?? false,
        namingInstruction: json['namingInstruction'] ?? '이게 뭐죠?',
        descInstruction: json['descInstruction'] ?? '',
        practiceDescExample: json['practiceDescExample'],
        choiceQuestion: json['choiceQuestion'] ?? '',
        option1: json['option1'] ?? '',
        option1ImagePath: json['option1ImagePath'],
        option2: json['option2'] ?? '',
        option2ImagePath: json['option2ImagePath'],
        correctOptionIndex: json['correctOptionIndex'] ?? 1,
        practiceAnswerExplanation: json['practiceAnswerExplanation'],
      );
}
