"""
dice.py — Dice notation parser for Strixhaven Encounter Manager.

Supports expressions such as:
    1d20 + 4
    2d6 - 1
    d10
    3d8+2
"""

import random
import re
from typing import NamedTuple


# ---------------------------------------------------------------------------
# Regex: optional count 'd' sides (optional whitespace) optional +/- modifier
# ---------------------------------------------------------------------------
_DICE_PATTERN = re.compile(
    r"^\s*(?P<count>\d+)?d(?P<sides>\d+)"
    r"(?:\s*(?P<op>[+\-])\s*(?P<modifier>\d+))?\s*$",
    re.IGNORECASE,
)


class DiceResult(NamedTuple):
    """Holds a detailed breakdown of a single dice roll."""

    notation: str
    rolls: list[int]
    modifier: int
    total: int


class DiceParseError(ValueError):
    """Raised when a dice notation string cannot be parsed."""


def parse_notation(notation: str) -> tuple[int, int, int]:
    """
    Parse a dice notation string into (count, sides, modifier).

    Args:
        notation: A string like '1d20 + 4', '2d6', 'd10', '3d8 - 1'.

    Returns:
        A tuple of (count, sides, modifier).

    Raises:
        DiceParseError: If the notation is invalid.
    """
    match = _DICE_PATTERN.match(notation)
    if not match:
        raise DiceParseError(
            f"Invalid dice notation: '{notation}'. "
            "Expected format like '1d20', '2d6+3', 'd10 - 1'."
        )

    count = int(match.group("count") or 1)
    sides = int(match.group("sides"))
    modifier_raw = int(match.group("modifier") or 0)
    op = match.group("op") or "+"

    if sides < 1:
        raise DiceParseError(f"Dice must have at least 1 side, got d{sides}.")
    if count < 1:
        raise DiceParseError(f"Must roll at least 1 die, got {count}d{sides}.")

    modifier = modifier_raw if op == "+" else -modifier_raw
    return count, sides, modifier


def roll_dice(notation: str, *, rng: random.Random | None = None) -> int:
    """
    Roll dice described by *notation* and return the total result.

    Args:
        notation: Dice notation string, e.g. '1d20 + 4'.
        rng:      Optional :class:`random.Random` instance for reproducibility
                  in tests. Uses the module-level RNG by default.

    Returns:
        Integer total of all rolls plus modifier.

    Raises:
        DiceParseError: If the notation cannot be parsed.

    Example::

        >>> roll_dice('1d20 + 4')   # some integer in range [5, 24]
        17
    """
    rng = rng or random
    count, sides, modifier = parse_notation(notation)
    rolls = [rng.randint(1, sides) for _ in range(count)]
    return sum(rolls) + modifier


def roll_dice_detailed(notation: str, *, rng: random.Random | None = None) -> DiceResult:
    """
    Same as :func:`roll_dice` but returns a :class:`DiceResult` with breakdown.

    Args:
        notation: Dice notation string.
        rng:      Optional RNG for testing.

    Returns:
        :class:`DiceResult` namedtuple with notation, rolls, modifier, total.
    """
    rng = rng or random
    count, sides, modifier = parse_notation(notation)
    rolls = [rng.randint(1, sides) for _ in range(count)]
    total = sum(rolls) + modifier
    return DiceResult(notation=notation, rolls=rolls, modifier=modifier, total=total)
