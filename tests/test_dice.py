"""
test_dice.py — Unit tests for engine/dice.py
"""

import random
import pytest

from engine.dice import (
    DiceParseError,
    DiceResult,
    parse_notation,
    roll_dice,
    roll_dice_detailed,
)


# ---------------------------------------------------------------------------
# parse_notation
# ---------------------------------------------------------------------------

class TestParseNotation:
    def test_simple_d20(self):
        count, sides, modifier = parse_notation("d20")
        assert (count, sides, modifier) == (1, 20, 0)

    def test_explicit_count_and_sides(self):
        count, sides, modifier = parse_notation("2d6")
        assert (count, sides, modifier) == (2, 6, 0)

    def test_positive_modifier(self):
        count, sides, modifier = parse_notation("1d20 + 4")
        assert (count, sides, modifier) == (1, 20, 4)

    def test_negative_modifier(self):
        count, sides, modifier = parse_notation("2d6 - 1")
        assert (count, sides, modifier) == (2, 6, -1)

    def test_no_spaces(self):
        count, sides, modifier = parse_notation("3d8+2")
        assert (count, sides, modifier) == (3, 8, 2)

    def test_case_insensitive(self):
        count, sides, modifier = parse_notation("1D12")
        assert (count, sides, modifier) == (1, 12, 0)

    def test_leading_trailing_whitespace(self):
        count, sides, modifier = parse_notation("  1d6  ")
        assert (count, sides, modifier) == (1, 6, 0)

    def test_invalid_notation_raises(self):
        with pytest.raises(DiceParseError):
            parse_notation("roll20")

    def test_empty_string_raises(self):
        with pytest.raises(DiceParseError):
            parse_notation("")

    def test_negative_modifier_no_space(self):
        count, sides, modifier = parse_notation("d10-2")
        assert (count, sides, modifier) == (1, 10, -2)


# ---------------------------------------------------------------------------
# roll_dice
# ---------------------------------------------------------------------------

class TestRollDice:
    def test_result_in_range_d20(self):
        # Without modifier, 1d20 should be in [1, 20]
        for _ in range(100):
            result = roll_dice("1d20")
            assert 1 <= result <= 20

    def test_result_in_range_with_modifier(self):
        # 1d20 + 4 should be in [5, 24]
        for _ in range(100):
            result = roll_dice("1d20 + 4")
            assert 5 <= result <= 24

    def test_negative_modifier(self):
        # 1d6 - 2 should be in [-1, 4]
        for _ in range(100):
            result = roll_dice("1d6 - 2")
            assert -1 <= result <= 4

    def test_deterministic_with_seeded_rng(self):
        rng = random.Random(42)
        r1 = roll_dice("1d20", rng=rng)
        rng2 = random.Random(42)
        r2 = roll_dice("1d20", rng=rng2)
        assert r1 == r2

    def test_multi_die(self):
        # 4d6 should be in [4, 24]
        for _ in range(50):
            result = roll_dice("4d6")
            assert 4 <= result <= 24

    def test_invalid_notation_raises(self):
        with pytest.raises(DiceParseError):
            roll_dice("bad notation")


# ---------------------------------------------------------------------------
# roll_dice_detailed
# ---------------------------------------------------------------------------

class TestRollDiceDetailed:
    def test_returns_dice_result(self):
        result = roll_dice_detailed("2d6 + 3")
        assert isinstance(result, DiceResult)

    def test_rolls_length_matches_count(self):
        rng = random.Random(0)
        result = roll_dice_detailed("3d8", rng=rng)
        assert len(result.rolls) == 3

    def test_total_equals_sum_plus_modifier(self):
        rng = random.Random(7)
        result = roll_dice_detailed("2d6 + 2", rng=rng)
        assert result.total == sum(result.rolls) + result.modifier

    def test_modifier_stored_correctly(self):
        rng = random.Random(1)
        result = roll_dice_detailed("1d20 - 1", rng=rng)
        assert result.modifier == -1

    def test_notation_preserved(self):
        notation = "1d12 + 5"
        result = roll_dice_detailed(notation)
        assert result.notation == notation
