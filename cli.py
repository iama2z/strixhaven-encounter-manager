#!/usr/bin/env python3
"""
cli.py — Command-line interface for the Strixhaven Encounter Manager dice engine.

Usage examples:
    # Roll dice from the command line
    python cli.py roll "1d20 + 4"
    python cli.py roll "2d6" --count 5

    # Sort a hard-coded list of combatants (demo mode, no Firebase)
    python cli.py demo

    # Roll and push initiative to Firebase for a session
    python cli.py push-initiative --session <SESSION_ID> \
        --credentials /path/to/serviceAccountKey.json
"""

import argparse
import json
import sys

from engine.dice import DiceParseError, roll_dice, roll_dice_detailed
from engine.initiative import Combatant, build_turn_order


# ---------------------------------------------------------------------------
# Subcommand handlers
# ---------------------------------------------------------------------------

def cmd_roll(args: argparse.Namespace) -> int:
    """Roll dice from a notation string."""
    for _ in range(args.count):
        try:
            if args.verbose:
                result = roll_dice_detailed(args.notation)
                print(
                    f"  Notation : {result.notation}\n"
                    f"  Rolls    : {result.rolls}\n"
                    f"  Modifier : {result.modifier:+d}\n"
                    f"  Total    : {result.total}\n"
                )
            else:
                print(roll_dice(args.notation))
        except DiceParseError as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return 1
    return 0


def cmd_demo(args: argparse.Namespace) -> int:
    """Run a demo initiative sort with sample combatants."""
    sample_combatants = [
        {"id": "p1", "name": "Dina (Witherbloom)", "type": "player",
         "max_hp": 45, "current_hp": 45, "dex_modifier": 3},
        {"id": "p2", "name": "Zanther (Prismari)", "type": "player",
         "max_hp": 38, "current_hp": 38, "dex_modifier": 1},
        {"id": "m1", "name": "Groff", "type": "monster",
         "max_hp": 32, "current_hp": 32, "dex_modifier": 0},
        {"id": "m2", "name": "Shadow Mage", "type": "monster",
         "max_hp": 20, "current_hp": 20, "dex_modifier": 2},
    ]

    print("Rolling initiative for demo combatants...\n")
    sorted_combatants = build_turn_order(sample_combatants)

    print(f"{'#':<4} {'Name':<25} {'Type':<10} {'Initiative':<12} {'HP'}")
    print("-" * 60)
    for i, c in enumerate(sorted_combatants, start=1):
        hp_str = f"{c['current_hp']}/{c['max_hp']}"
        marker = "◀ ACTIVE" if i == 1 else ""
        print(
            f"{i:<4} {c['name']:<25} {c['type']:<10} "
            f"{c['initiative']:<12} {hp_str} {marker}"
        )

    if args.json:
        print("\nJSON output:")
        print(json.dumps(sorted_combatants, indent=2))
    return 0


def cmd_push_initiative(args: argparse.Namespace) -> int:
    """Roll and push sorted initiative order to Firebase."""
    try:
        from engine.firebase_client import FirebaseClient, FirebaseUnavailableError
    except ImportError as exc:
        print(f"Error importing firebase_client: {exc}", file=sys.stderr)
        return 1

    try:
        client = FirebaseClient(credentials_path=args.credentials)
        sorted_combatants = client.roll_and_push_initiative(args.session)
    except Exception as exc:  # noqa: BLE001
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    print(f"✓ Initiative sorted and pushed to Firestore (session={args.session})\n")
    print(f"{'#':<4} {'Name':<25} {'Initiative'}")
    print("-" * 42)
    for i, c in enumerate(sorted_combatants, start=1):
        print(f"{i:<4} {c['name']:<25} {c['initiative']}")
    return 0


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="strixhaven-engine",
        description="Strixhaven Encounter Manager — Dice & Initiative CLI",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # --- roll ---
    roll_p = sub.add_parser("roll", help="Roll dice from notation string")
    roll_p.add_argument("notation", help="Dice notation, e.g. '1d20 + 4'")
    roll_p.add_argument(
        "--count", "-n", type=int, default=1, metavar="N",
        help="Number of times to roll (default: 1)",
    )
    roll_p.add_argument(
        "--verbose", "-v", action="store_true",
        help="Show detailed breakdown of each roll",
    )
    roll_p.set_defaults(func=cmd_roll)

    # --- demo ---
    demo_p = sub.add_parser("demo", help="Demo initiative sort (no Firebase)")
    demo_p.add_argument(
        "--json", action="store_true",
        help="Also print JSON output",
    )
    demo_p.set_defaults(func=cmd_demo)

    # --- push-initiative ---
    push_p = sub.add_parser(
        "push-initiative", help="Roll initiative and push to Firebase"
    )
    push_p.add_argument(
        "--session", "-s", required=True, metavar="SESSION_ID",
        help="Firestore session document ID",
    )
    push_p.add_argument(
        "--credentials", "-c", metavar="PATH",
        help=(
            "Path to Firebase service account key JSON "
            "(default: $FIREBASE_CREDENTIALS_PATH)"
        ),
    )
    push_p.set_defaults(func=cmd_push_initiative)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
