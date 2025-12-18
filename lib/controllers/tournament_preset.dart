import '../models/blind_level.dart';

class TournamentPreset {
  final String name;
  final List<BlindLevel> levels;
  final int buyInAmount;
  final int rebuyAmount;
  final int addonAmount;

  TournamentPreset({
    required this.name,
    required this.levels,
    required this.buyInAmount,
    required this.rebuyAmount,
    required this.addonAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'levels': levels.map((l) => l.toMap()).toList(),
      'buyInAmount': buyInAmount,
      'rebuyAmount': rebuyAmount,
      'addonAmount': addonAmount,
    };
  }

  factory TournamentPreset.fromMap(Map<dynamic, dynamic> map) {
    return TournamentPreset(
      name: map['name'] as String,
      levels: (map['levels'] as List)
          .map((l) => BlindLevel.fromMap(l as Map<dynamic, dynamic>))
          .toList(),
      buyInAmount: map['buyInAmount'] as int,
      rebuyAmount: map['rebuyAmount'] as int,
      addonAmount: map['addonAmount'] as int,
    );
  }

  // copyWith method for easy updates
  TournamentPreset copyWith({String? name}) {
    return TournamentPreset(
      name: name ?? this.name,
      levels: levels,
      buyInAmount: buyInAmount,
      rebuyAmount: rebuyAmount,
      addonAmount: addonAmount,
    );
  }
}
