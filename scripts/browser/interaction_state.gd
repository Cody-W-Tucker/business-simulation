extends RefCounted
## Room navigation and browser interaction are mutually exclusive modes.

enum Mode { NAVIGATION, WALL, WALL_LOOK, FULL_WINDOW }

var mode := Mode.NAVIGATION


func is_wall() -> bool:
	return mode == Mode.WALL or mode == Mode.WALL_LOOK
