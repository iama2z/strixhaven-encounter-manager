"""
firebase_client.py — Firestore integration for the encounter manager.

Reads the active encounter from Firebase, merges initiative rolls, and
writes the sorted turn order back.

Requires a Firebase service account key (JSON) either via:
  - Environment variable:  FIREBASE_CREDENTIALS_PATH=/path/to/key.json
  - Or passed explicitly:  FirebaseClient(credentials_path="...")

The Firestore schema used here matches the technical specification:
    /sessions/{sessionId}  →  { active_encounter_id: str, ... }
    /encounters/{encounterId}  →  { combatants: [...], ... }
"""

from __future__ import annotations

import os
from typing import Any

try:
    import firebase_admin
    from firebase_admin import credentials, firestore

    _FIREBASE_AVAILABLE = True
except ImportError:
    _FIREBASE_AVAILABLE = False

from .initiative import build_turn_order


class FirebaseUnavailableError(RuntimeError):
    """Raised when firebase-admin is not installed."""


class FirebaseClient:
    """Thin wrapper around firebase-admin Firestore for encounter state."""

    def __init__(self, credentials_path: str | None = None) -> None:
        if not _FIREBASE_AVAILABLE:
            raise FirebaseUnavailableError(
                "firebase-admin is not installed. "
                "Run: pip install firebase-admin"
            )

        cred_path = credentials_path or os.environ.get("FIREBASE_CREDENTIALS_PATH")
        if not cred_path:
            raise ValueError(
                "Firebase credentials path must be provided via the "
                "'FIREBASE_CREDENTIALS_PATH' environment variable or "
                "the 'credentials_path' constructor argument."
            )

        # Initialise only once (firebase_admin raises if already initialised)
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)

        self._db = firestore.client()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def get_active_encounter_id(self, session_id: str) -> str:
        """Return the active_encounter_id for a given session."""
        doc = self._db.collection("sessions").document(session_id).get()
        if not doc.exists:
            raise ValueError(f"Session '{session_id}' not found in Firestore.")
        data = doc.to_dict()
        encounter_id = data.get("active_encounter_id")
        if not encounter_id:
            raise ValueError(
                f"Session '{session_id}' has no active_encounter_id set."
            )
        return encounter_id

    def get_encounter(self, encounter_id: str) -> dict[str, Any]:
        """Fetch and return a full encounter document as a dict."""
        doc = self._db.collection("encounters").document(encounter_id).get()
        if not doc.exists:
            raise ValueError(f"Encounter '{encounter_id}' not found in Firestore.")
        return doc.to_dict()

    def write_turn_order(
        self,
        encounter_id: str,
        sorted_combatants: list[dict[str, Any]],
    ) -> None:
        """
        Overwrite the combatants list in Firestore with the sorted turn order.

        Args:
            encounter_id:      Firestore document ID under /encounters/.
            sorted_combatants: Ordered list of combatant dicts.
        """
        self._db.collection("encounters").document(encounter_id).update(
            {
                "combatants": sorted_combatants,
                "current_turn_index": 0,
            }
        )

    def roll_and_push_initiative(self, session_id: str) -> list[dict[str, Any]]:
        """
        Full workflow:
          1. Resolve active encounter for the given session.
          2. Read combatants.
          3. Roll / sort initiative.
          4. Write sorted list back to Firestore.
          5. Return sorted combatants.

        Args:
            session_id: Firestore session document ID.

        Returns:
            Sorted list of combatant dicts.
        """
        encounter_id = self.get_active_encounter_id(session_id)
        encounter = self.get_encounter(encounter_id)
        combatants = encounter.get("combatants", [])

        sorted_combatants = build_turn_order(combatants)
        self.write_turn_order(encounter_id, sorted_combatants)
        return sorted_combatants
