import 'package:flutter_test/flutter_test.dart';
import 'package:strixhaven_encounter_manager/models/encounter.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Combatant tests
  // ---------------------------------------------------------------------------
  group('Combatant', () {
    const player = Combatant(
      id: 'p1',
      name: 'Dina',
      type: 'player',
      initiative: 18,
      maxHp: 45,
      currentHp: 45,
    );

    const monster = Combatant(
      id: 'm1',
      name: 'Groff',
      type: 'monster',
      initiative: 12,
      maxHp: 32,
      currentHp: 16,
    );

    test('isPlayer returns true for player type', () {
      expect(player.isPlayer, isTrue);
      expect(monster.isPlayer, isFalse);
    });

    test('isMonster returns true for monster type', () {
      expect(monster.isMonster, isTrue);
      expect(player.isMonster, isFalse);
    });

    test('isAlive reflects currentHp > 0', () {
      expect(player.isAlive, isTrue);
      const dead = Combatant(
          id: 'x', name: 'Dead', type: 'monster',
          initiative: 5, maxHp: 10, currentHp: 0);
      expect(dead.isAlive, isFalse);
    });

    test('hpPercent is correct', () {
      expect(monster.hpPercent, closeTo(0.5, 0.01));
      expect(player.hpPercent, closeTo(1.0, 0.01));
    });

    test('hpPercent clamps to 0 when maxHp is 0', () {
      const c = Combatant(
          id: 'z', name: 'Zero', type: 'player',
          initiative: 10, maxHp: 0, currentHp: 0);
      expect(c.hpPercent, 0.0);
    });

    test('initiative can be null (not yet rolled)', () {
      const c = Combatant(
          id: 'u', name: 'Unrolled', type: 'player',
          initiative: null, maxHp: 20, currentHp: 20);
      expect(c.initiative, isNull);
    });

    test('fromMap deserialises correctly', () {
      final map = {
        'id': 'p2',
        'name': 'Zanther',
        'type': 'player',
        'initiative': 15,
        'max_hp': 38,
        'current_hp': 30,
        'dex_modifier': 3,
      };
      final c = Combatant.fromMap(map);
      expect(c.id, 'p2');
      expect(c.name, 'Zanther');
      expect(c.initiative, 15);
      expect(c.maxHp, 38);
      expect(c.currentHp, 30);
      expect(c.dexModifier, 3);
    });

    test('fromMap returns null initiative when key is absent', () {
      final c = Combatant.fromMap({'id': 'x', 'name': 'Unknown'});
      expect(c.initiative, isNull);
    });

    test('toMap round-trips correctly', () {
      final map = player.toMap();
      final restored = Combatant.fromMap(map);
      expect(restored.id, player.id);
      expect(restored.initiative, player.initiative);
      expect(restored.currentHp, player.currentHp);
    });

    test('copyWith updates currentHp only', () {
      final updated = player.copyWith(currentHp: 20);
      expect(updated.currentHp, 20);
      expect(updated.name, player.name);
      expect(updated.maxHp, player.maxHp);
    });

    test('fromMap provides safe defaults for missing keys', () {
      final c = Combatant.fromMap({'id': 'x', 'name': 'Unknown'});
      expect(c.type, 'player');
      expect(c.maxHp, 0);
      expect(c.dexModifier, 0);
    });
  });
}
