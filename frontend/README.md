# Strixhaven Encounter Manager — Flutter Frontend

Cross-platform Flutter UI for the Strixhaven battle timeline. Connects to Firebase Firestore for real-time state synchronisation.

## Structure

```
frontend/
├── lib/
│   ├── main.dart                          # App entry point + Firebase init
│   ├── models/
│   │   └── encounter.dart                 # Combatant + Encounter models
│   ├── services/
│   │   └── encounter_service.dart         # Firestore read/write layer
│   ├── screens/
│   │   └── battle_timeline_screen.dart    # Main battle timeline UI
│   ├── widgets/
│   │   └── combatant_card.dart            # Combatant card with HP controls
│   └── theme/
│       └── app_theme.dart                 # Dark arcane colour palette + ThemeData
└── test/
    └── encounter_model_test.dart          # Unit tests for models
```

## Running

1. Add your `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) from Firebase console to the appropriate platform folder.

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run (pass your Firestore encounter document ID):
   ```bash
   flutter run --dart-define=ENCOUNTER_ID=<your_encounter_id>
   ```

4. For web:
   ```bash
   flutter run -d web-server --web-port=3000 --dart-define=ENCOUNTER_ID=<your_encounter_id>
   ```

## Features

- **Real-time sync** — `StreamBuilder` connected to Firestore updates the UI instantly
- **Colour-coded cards** — Green for players, Red for monsters
- **Active turn glow** — animated highlight with colour-matched shadow
- **HP bar** — transitions green → yellow → red as HP drops
- **+/- HP controls** — tap to adjust HP, clamped to [0, maxHp]
- **GM controls** — Start / Next Turn / Previous Turn / End Encounter
- **Round counter** — auto-increments when the turn wraps around

## Firebase Schema

```
/sessions/{sessionId}
  active_encounter_id: string

/encounters/{encounterId}
  status: "setup" | "active" | "completed"
  current_turn_index: number
  round: number
  combatants: [
    { id, name, type, initiative, max_hp, current_hp }
  ]
```
