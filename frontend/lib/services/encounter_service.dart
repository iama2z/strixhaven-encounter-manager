import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/encounter.dart';

/// EncounterService handles all reads and writes to Firestore for encounters.
class EncounterService {
  final FirebaseFirestore _db;

  EncounterService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Stream of the active encounter for a given session.
  Stream<Encounter?> watchEncounter(String encounterId) {
    return _db
        .collection('encounters')
        .doc(encounterId)
        .snapshots()
        .map((snap) => snap.exists ? Encounter.fromSnapshot(snap) : null);
  }

  /// Stream of the active_encounter_id from a session document.
  Stream<String?> watchActiveEncounterId(String sessionId) {
    return _db
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((snap) => snap.data()?['active_encounter_id'] as String?);
  }

  // ---------------------------------------------------------------------------
  // Turn management
  // ---------------------------------------------------------------------------

  Future<void> nextTurn(Encounter encounter) async {
    final nextIndex = encounter.currentTurnIndex + 1;
    final isNewRound = nextIndex >= encounter.combatants.length;

    await _db.collection('encounters').doc(encounter.id).update({
      'current_turn_index': isNewRound ? 0 : nextIndex,
      if (isNewRound) 'round': encounter.round + 1,
    });
  }

  Future<void> previousTurn(Encounter encounter) async {
    if (encounter.currentTurnIndex <= 0) return;
    await _db.collection('encounters').doc(encounter.id).update({
      'current_turn_index': encounter.currentTurnIndex - 1,
    });
  }

  Future<void> startEncounter(String encounterId) async {
    await _db.collection('encounters').doc(encounterId).update({
      'status': 'active',
      'current_turn_index': 0,
      'round': 1,
    });
  }

  Future<void> endEncounter(String encounterId) async {
    await _db
        .collection('encounters')
        .doc(encounterId)
        .update({'status': 'completed'});
  }

  Future<void> resetEncounter(Encounter encounter) async {
    final resetCombatants = encounter.combatants
        .map((c) => c.copyWith(currentHp: c.maxHp).toMap())
        .toList();

    await _db.collection('encounters').doc(encounter.id).update({
      'status': 'setup',
      'current_turn_index': 0,
      'round': 1,
      'combatants': resetCombatants,
    });
  }

  Future<void> resetAllHp(Encounter encounter) async {
    final resetCombatants = encounter.combatants
        .map((c) => c.copyWith(currentHp: c.maxHp).toMap())
        .toList();

    await _db
        .collection('encounters')
        .doc(encounter.id)
        .update({'combatants': resetCombatants});
  }

  Future<void> setRound(Encounter encounter, int round) async {
    final clampedRound = round < 1 ? 1 : round;
    await _db
        .collection('encounters')
        .doc(encounter.id)
        .update({'round': clampedRound});
  }

  Future<void> setCurrentTurnIndex(Encounter encounter, int index) async {
    if (encounter.combatants.isEmpty) return;
    final clampedIndex = index.clamp(0, encounter.combatants.length - 1);
    await _db
        .collection('encounters')
        .doc(encounter.id)
        .update({'current_turn_index': clampedIndex});
  }

  Future<void> createEncounterIfMissing(String encounterId) async {
    final encounterRef = _db.collection('encounters').doc(encounterId);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(encounterRef);
      if (snapshot.exists) return;
      tx.set(encounterRef, {
        'status': 'setup',
        'current_turn_index': 0,
        'round': 1,
        'combatants': [
          {
            'id': 'pc-1',
            'name': 'Mage Student',
            'type': 'player',
            'initiative': 15,
            'max_hp': 24,
            'current_hp': 24,
            'dex_modifier': 2,
          },
          {
            'id': 'pc-2',
            'name': 'Arcane Archer',
            'type': 'player',
            'initiative': 13,
            'max_hp': 28,
            'current_hp': 28,
            'dex_modifier': 1,
          },
          {
            'id': 'mon-1',
            'name': 'Animated Armor',
            'type': 'monster',
            'initiative': 12,
            'max_hp': 33,
            'current_hp': 33,
            'dex_modifier': 0,
          },
          {
            'id': 'mon-2',
            'name': 'Pest Swarm',
            'type': 'monster',
            'initiative': 10,
            'max_hp': 18,
            'current_hp': 18,
            'dex_modifier': 1,
          },
        ],
      });
    });
  }

  // ---------------------------------------------------------------------------
  // HP management
  // ---------------------------------------------------------------------------

  Future<void> adjustHp(Encounter encounter, String combatantId, int delta) async {
    final combatants = encounter.combatants.map((c) {
      if (c.id != combatantId) return c.toMap();
      final newHp = (c.currentHp + delta).clamp(0, c.maxHp);
      return c.copyWith(currentHp: newHp).toMap();
    }).toList();

    await _db
        .collection('encounters')
        .doc(encounter.id)
        .update({'combatants': combatants});
  }
}
