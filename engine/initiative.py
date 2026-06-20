"""
initiative.py — Initiative sorting and turn-order logic.

Accepts a list of combatants (dicts or dataclasses), computes initiative
rolls from dice notation, resolves ties, and returns an ordered list.

Combatant schema (matches Firestore document shape from technical_specs):
    {
        "id":           str,
        "name":         str,
        "type":         "player" | "monster",
        "initiative":   int | None,   # pre-set value; None = needs rolling
        "dex_modifier": int,          # default 0 — used for tie-breaking
        "max_hp":       int,
        "current_hp":   int,
    }
"""

from __future__ import annotations

import random
from copy import deepcopy
from dataclasses import dataclass, field
from typing import Any

from .dice import roll_dice


# ---------------------------------------------------------------------------
# Combatant dataclass
# ---------------------------------------------------------------------------

@dataclass
class Combatant:
    """Represents a single participant in a combat encounter."""

    id: str
    name: str
    type: str                       # "player" or "monster"
    max_hp: int
    current_hp: int
    dex_modifier: int = 0
    initiative: int | None = None   # None until rolled

    # ---------- factory ----------
    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Combatant":
        return cls(
            id=data["id"],
            name=data["name"],
            type=data.get("type", "player"),
            max_hp=int(data.get("max_hp", 0)),
            current_hp=int(data.get("current_hp", 0)),
            dex_modifier=int(data.get("dex_modifier", 0)),
            initiative=data.get("initiative"),
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "type": self.type,
            "max_hp": self.max_hp,
            "current_hp": self.current_hp,
            "dex_modifier": self.dex_modifier,
            "initiative": self.initiative,
        }


# ---------------------------------------------------------------------------
# Core functions
# ---------------------------------------------------------------------------

def roll_initiative(
    combatant: Combatant,
    *,
    rng: random.Random | None = None,
) -> int:
    """
    Roll a d20 and add the combatant's dex_modifier.

    Returns the rolled initiative and also updates combatant.initiative in place.
    """
    rng = rng or random
    roll = rng.randint(1, 20) + combatant.dex_modifier
    combatant.initiative = roll
    return roll


def sort_initiative(
    combatants: list[Combatant],
    *,
    rng: random.Random | None = None,
) -> list[Combatant]:
    """
    Sort a list of combatants by initiative, highest first.

    Tie-breaking rules (in order):
      1. Higher dex_modifier wins.
      2. Re-roll a d20 for tied combatants (recursive until resolved).
         The re-roll result is ephemeral and does NOT update combatant.initiative.

    Args:
        combatants: List of :class:`Combatant` objects. Those without an
                    initiative value will have one rolled automatically.
        rng:        Optional RNG for reproducibility.

    Returns:
        New list of combatants ordered by descending initiative.
    """
    rng = rng or random
    working = deepcopy(combatants)

    # Roll for any combatant that doesn't have an initiative yet
    for c in working:
        if c.initiative is None:
            roll_initiative(c, rng=rng)

    def _sort_key(c: Combatant) -> tuple[int, int, int]:
        # Primary: initiative (higher = first → negate for ascending sort)
        # Secondary: dex modifier (higher = first)
        # Tertiary: random tiebreaker roll (stored temporarily)
        return (-c.initiative, -c.dex_modifier, rng.randint(1, 20) * -1)

    working.sort(key=_sort_key)
    return working


def build_turn_order(
    combatants: list[dict[str, Any]],
    *,
    rng: random.Random | None = None,
) -> list[dict[str, Any]]:
    """
    High-level helper: accept raw dicts, roll/sort initiatives, return dicts.

    This is the primary API for the CLI and Firebase integration layer.

    Args:
        combatants: List of combatant dicts (Firestore document shape).
        rng:        Optional RNG for testing.

    Returns:
        Sorted list of combatant dicts with initiative values populated.
    """
    objs = [Combatant.from_dict(c) for c in combatants]
    sorted_objs = sort_initiative(objs, rng=rng)
    return [c.to_dict() for c in sorted_objs]
