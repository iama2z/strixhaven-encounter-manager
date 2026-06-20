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
