"""
seed_encounter.py — Seeds a test encounter into Firestore for development.

Usage:
    FIREBASE_CREDENTIALS_PATH=/path/to/key.json python seed_encounter.py
"""

import os
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin")
    sys.exit(1)

cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH")
if not cred_path:
    print("ERROR: Set FIREBASE_CREDENTIALS_PATH to your service account JSON.")
    sys.exit(1)

cred = credentials.Certificate(os.path.expanduser(cred_path))
firebase_admin.initialize_app(cred)
db = firestore.client()

ENCOUNTER_ID = "encounter-001"

encounter_data = {
    "status": "setup",
    "current_turn_index": 0,
    "round": 1,
    "combatants": [
        {
            "id": "player-1",
            "name": "Lyriel Shadowmend",
            "type": "player",
            "initiative": 18,
            "max_hp": 45,
            "current_hp": 45,
        },
        {
            "id": "player-2",
            "name": "Thorn Ironclaw",
            "type": "player",
            "initiative": 14,
            "max_hp": 60,
            "current_hp": 60,
        },
        {
            "id": "player-3",
            "name": "Zara Brightflame",
            "type": "player",
            "initiative": 12,
            "max_hp": 38,
            "current_hp": 38,
        },
        {
            "id": "monster-1",
            "name": "Oriq Bloodmage",
            "type": "monster",
            "initiative": 16,
            "max_hp": 78,
            "current_hp": 78,
        },
        {
            "id": "monster-2",
            "name": "Pest Amalgam",
            "type": "monster",
            "initiative": 9,
            "max_hp": 32,
            "current_hp": 32,
        },
    ],
}

db.collection("encounters").document(ENCOUNTER_ID).set(encounter_data)
print(f"\n✅ Encounter '{ENCOUNTER_ID}' seeded successfully!")
print(f"   Combatants: {len(encounter_data['combatants'])}")
print(f"   Status: {encounter_data['status']}")
print(f"\nRefresh the app — you should now see the battle timeline.")
