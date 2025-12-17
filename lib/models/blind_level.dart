class BlindLevel {
  final int level;
  String label;
  int smallBlind;
  int bigBlind;
  int? ante;
  int durationSeconds;

  BlindLevel({
    required this.level,
    required this.label,
    required this.smallBlind,
    required this.bigBlind,
    this.ante,
    required this.durationSeconds,
  });

  @override
  String toString() =>
      'Nível $level: $smallBlind/$bigBlind (${durationSeconds ~/ 60}m)';
}
