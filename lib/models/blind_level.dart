class BlindLevel {
  final int level;
  String label;
  int smallBlind;
  int bigBlind;
  int? ante;
  int durationSeconds;
  bool isBreak;

  BlindLevel({
    required this.level,
    required this.label,
    required this.smallBlind,
    required this.bigBlind,
    this.ante,
    required this.durationSeconds,
    this.isBreak = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'label': label,
      'smallBlind': smallBlind,
      'bigBlind': bigBlind,
      'ante': ante,
      'durationSeconds': durationSeconds,
      'isBreak': isBreak,
    };
  }

  factory BlindLevel.fromMap(Map<dynamic, dynamic> map) {
    return BlindLevel(
      level: map['level'] as int,
      label: map['label'] as String,
      smallBlind: map['smallBlind'] as int,
      bigBlind: map['bigBlind'] as int,
      ante: map['ante'] as int?,
      durationSeconds: map['durationSeconds'] as int,
      isBreak: (map['isBreak'] ?? false) as bool,
    );
  }

  @override
  String toString() =>
      'Nível $level: $smallBlind/$bigBlind (${durationSeconds ~/ 60}m)';
}
