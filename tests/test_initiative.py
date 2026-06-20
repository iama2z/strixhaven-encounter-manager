"""
test_initiative.py — Unit tests for engine/initiative.py
"""

import random
import pytest

from engine.initiative import Combatant, build_turn_order, roll_initiative, sort_initiative


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_combatant(name: str, dex_mod: int = 0, initiative: int | None = None) -> Combatant:
    return Combatant(
        id=name.lower().replace(" ", "_"),
        name=name,
        type="player",
        max_hp=30,
        current_hp=30,
        dex_modifier=dex_mod,
        initiative=initiative,
    )


# ---------------------------------------------------------------------------
# Combatant.from_dict / to_dict
# ---------------------------------------------------------------------------

class TestCombatantSerialization:
    def test_from_dict_minimal(self):
        data = {"id": "p1", "name": "Alice", "max_hp": 20, "current_hp": 20}
        c = Combatant.from_dict(data)
        assert c.id == "p1"
        assert c.name == "Alice"
        assert c.dex_modifier == 0
        assert c.initiative is None

    def test_from_dict_full(self):
        data = {
            "id": "m1",
            "name": "Goblin",
            "type": "monster",
            "max_hp": 10,
            "current_hp": 7,
            "dex_modifier": 2,
            "initiative": 14,
        }
        c = Combatant.from_dict(data)
        assert c.initiative == 14
        assert c.dex_modifier == 2
        assert c.type == "monster"

    def test_round_trip(self):
        c = make_combatant("Bob", dex_mod=3, initiative=18)
        restored = Combatant.from_dict(c.to_dict())
        assert restored == c


# ---------------------------------------------------------------------------
# roll_initiative
# ---------------------------------------------------------------------------

class TestRollInitiative:
    def test_result_in_expected_range(self):
        c = make_combatant("Alice", dex_mod=3)
        for _ in range(50):
            result = roll_initiative(c, rng=random.Random())
            # d20 (1–20) + 3 = [4, 23]
            assert 4 <= result <= 23

    def test_updates_combatant_in_place(self):
        c = make_combatant("Alice", dex_mod=0)
        assert c.initiative is None
        roll_initiative(c)
        assert c.initiative is not None

    def test_deterministic_with_seeded_rng(self):
        c1 = make_combatant("Alice")
        c2 = make_combatant("Alice")
        roll_initiative(c1, rng=random.Random(99))
        roll_initiative(c2, rng=random.Random(99))
        assert c1.initiative == c2.initiative


# ---------------------------------------------------------------------------
# sort_initiative
# ---------------------------------------------------------------------------

class TestSortInitiative:
    def test_sorted_descending(self):
        combatants = [
            make_combatant("Low", initiative=5),
            make_combatant("High", initiative=20),
            make_combatant("Mid", initiative=12),
        ]
        result = sort_initiative(combatants)
        initiatives = [c.initiative for c in result]
        assert initiatives == sorted(initiatives, reverse=True)

    def test_all_get_initiative_rolled(self):
        combatants = [make_combatant(f"C{i}") for i in range(4)]
        result = sort_initiative(combatants, rng=random.Random(0))
        assert all(c.initiative is not None for c in result)

    def test_original_list_not_mutated(self):
        combatants = [make_combatant("A", initiative=10), make_combatant("B", initiative=5)]
        originals = [c.initiative for c in combatants]
        sort_initiative(combatants)
        assert [c.initiative for c in combatants] == originals

    def test_dex_tiebreak_higher_dex_first(self):
        # Give two combatants identical initiative, different dex
        c1 = make_combatant("LowDex", dex_mod=0, initiative=15)
        c2 = make_combatant("HighDex", dex_mod=5, initiative=15)
        results = []
        # Run 20 times; HighDex should always be first (deterministic dex tiebreak)
        for _ in range(20):
            sorted_c = sort_initiative([c1, c2], rng=random.Random())
            results.append(sorted_c[0].name)
        assert all(name == "HighDex" for name in results)

    def test_length_preserved(self):
        combatants = [make_combatant(f"C{i}") for i in range(6)]
        result = sort_initiative(combatants)
        assert len(result) == 6


# ---------------------------------------------------------------------------
# build_turn_order (dict API)
# ---------------------------------------------------------------------------

class TestBuildTurnOrder:
    def test_returns_dicts(self):
        combatants = [
            {"id": "p1", "name": "Alice", "type": "player", "max_hp": 30, "current_hp": 30},
            {"id": "m1", "name": "Goblin", "type": "monster", "max_hp": 10, "current_hp": 10},
        ]
        result = build_turn_order(combatants, rng=random.Random(5))
        assert all(isinstance(c, dict) for c in result)

    def test_all_have_initiative(self):
        combatants = [
            {"id": f"c{i}", "name": f"Comb{i}", "type": "player",
             "max_hp": 20, "current_hp": 20}
            for i in range(5)
        ]
        result = build_turn_order(combatants)
        assert all(c["initiative"] is not None for c in result)

    def test_sorted_descending(self):
        combatants = [
            {"id": f"c{i}", "name": f"Comb{i}", "type": "player",
             "max_hp": 20, "current_hp": 20}
            for i in range(4)
        ]
        result = build_turn_order(combatants, rng=random.Random(42))
        inits = [c["initiative"] for c in result]
        assert inits == sorted(inits, reverse=True)
