extends Node

enum Difficulty { EASY, MEDIUM, HARD }

static var difficulty: int = Difficulty.MEDIUM


static func damage_per_hit() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.5
		Difficulty.HARD:
			return 1.5
		_:
			return 1.0


static func slime_speed_multiplier() -> float:
	if difficulty == Difficulty.HARD:
		return 1.2
	return 1.0
