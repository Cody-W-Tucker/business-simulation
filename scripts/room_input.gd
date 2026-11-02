extends RefCounted
## Central room action names. Bindings are editable in Project Settings > Input Map.
## Browser keystrokes are forwarded separately and must not be translated here.

const LEFT := &"room_left"
const RIGHT := &"room_right"
const FORWARD := &"room_forward"
const BACK := &"room_back"
const FAST := &"room_fast"
const JUMP := &"room_jump"
const DESCEND := &"room_descend"
const INTERACT := &"room_interact"
const CANCEL := &"room_cancel"


static func movement() -> Vector2:
	return Input.get_vector(LEFT, RIGHT, FORWARD, BACK)
