class_name GameBalance
extends RefCounted

## Shared SRD constants used across character creation, leveling, and combat.

## Cumulative XP thresholds for levels 1-20 (index 0 = level 1).
const XP_THRESHOLDS: Array[int] = [
	0,       # Level 1
	300,     # Level 2
	900,     # Level 3
	2700,    # Level 4
	6500,    # Level 5
	14000,   # Level 6
	23000,   # Level 7
	34000,   # Level 8
	48000,   # Level 9
	64000,   # Level 10
	85000,   # Level 11
	100000,  # Level 12
	120000,  # Level 13
	140000,  # Level 14
	165000,  # Level 15
	195000,  # Level 16
	225000,  # Level 17
	265000,  # Level 18
	305000,  # Level 19
	355000,  # Level 20
]

## Levels at which Ability Score Improvements (or feats) are granted.
const ASI_LEVELS: Array[int] = [4, 8, 12, 16, 19]


## Returns the XP threshold for a given level (1-20), or 0 if out of range.
static func xp_threshold(level: int) -> int:
	if level < 1 or level > 20:
		return 0
	return XP_THRESHOLDS[level - 1]
