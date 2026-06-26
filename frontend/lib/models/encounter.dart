import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single participant in a combat encounter.
class Combatant {
  final String id;
  final String name;
  final String type; // 'player' | 'monster'
  /// Null until the Python engine has rolled initiative for this combatant.
  final int? initiative;
  final int maxHp;
  final int currentHp;
  /// Used by the engine for tie-breaking; carried through to the UI for display.
  final int dexModifier;

  const Combatant({
    required this.id,
    required this.name,
    required this.type,
    required this.initiative,
    required this.maxHp,
    required this.currentHp,
    this.dexModifier = 0,
  });

  bool get isPlayer => type == 'player';
  bool get isMonster => type == 'monster';
  bool get isAlive => currentHp > 0;
  double get hpPercent => maxHp > 0 ? currentHp / maxHp : 0.0;

  factory Combatant.fromMap(Map<String, dynamic> map) {
    return Combatant(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      type: map['type'] as String? ?? 'player',
      initiative: (map['initiative'] as num?)?.toInt(),
      maxHp: (map['max_hp'] as num?)?.toInt() ?? 0,
      currentHp: (map['current_hp'] as num?)?.toInt() ?? 0,
      dexModifier: (map['dex_modifier'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'initiative': initiative,
        'max_hp': maxHp,
        'current_hp': currentHp,
        'dex_modifier': dexModifier,
      };

  Combatant copyWith({int? currentHp}) => Combatant(
        id: id,
        name: name,
        type: type,
        initiative: initiative,
        maxHp: maxHp,
        currentHp: currentHp ?? this.currentHp,
        dexModifier: dexModifier,
      );
}

/// Represents a full combat encounter document from Firestore.
class Encounter {
  final String id;
  final String status; // 'setup' | 'active' | 'completed'
  final int currentTurnIndex;
  final int round;
  final List<Combatant> combatants;

  const Encounter({
    required this.id,
    required this.status,
    required this.currentTurnIndex,
    required this.round,
    required this.combatants,
  });

  Combatant? get activeCombatant =>
      combatants.isNotEmpty && currentTurnIndex < combatants.length
          ? combatants[currentTurnIndex]
          : null;

  factory Encounter.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawCombatants = data['combatants'] as List<dynamic>? ?? [];
    return Encounter(
      id: doc.id,
      status: data['status'] as String? ?? 'setup',
      currentTurnIndex: (data['current_turn_index'] as num?)?.toInt() ?? 0,
      round: (data['round'] as num?)?.toInt() ?? 1,
      combatants: rawCombatants
          .map((c) => Combatant.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
