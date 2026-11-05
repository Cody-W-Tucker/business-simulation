extends SceneTree

const Actions = preload("res://scripts/room_input.gd")
const State = preload("res://scripts/interaction_state.gd")

class FakeBrowser extends Node:
	var keys: Array = []

	func set_key_pressed(code: int, pressed: bool, shift: bool, alt: bool, command: bool) -> void:
		keys.append([code, pressed, shift, alt, command])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for binding in [[Actions.LEFT, KEY_A], [Actions.RIGHT, KEY_D], [Actions.FORWARD, KEY_W],
			[Actions.BACK, KEY_S], [Actions.FAST, KEY_SHIFT], [Actions.JUMP, KEY_SPACE],
			[Actions.DESCEND, KEY_C], [Actions.INTERACT, KEY_E], [Actions.CANCEL, KEY_ESCAPE]]:
		var event := InputEventKey.new()
		event.keycode = binding[1]
		event.pressed = true
		if not event.is_action_pressed(binding[0]):
			_fail("Missing default binding: %s" % binding[0])
			return
	var home := InputEventKey.new()
	home.keycode = KEY_E
	home.shift_pressed = true
	home.pressed = true
	if not home.is_action_pressed(Actions.BOARD_HOME, false, true) or home.is_action_pressed(Actions.INTERACT, false, true):
		_fail("Board home shortcut conflicts with opening a board")
		return
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	var fake_browser := FakeBrowser.new()
	room.add_child(fake_browser)
	room.browser = fake_browser
	room._focus_wall()
	if room.interaction.mode != State.Mode.WALL or not room.wall_keyboard_focused or room.browser_focused:
		_fail("Wall focus state is inconsistent")
		return
	var typed := InputEventKey.new()
	typed.keycode = KEY_E
	typed.unicode = KEY_E
	typed.pressed = true
	room._input(typed)
	if fake_browser.keys.size() != 1 or fake_browser.keys[0][0] != KEY_E or room.interaction.mode != State.Mode.WALL:
		_fail("Room shortcut was not forwarded to the focused browser")
		return
	typed.shift_pressed = true
	room._input(typed)
	if fake_browser.keys.size() != 2 or not fake_browser.keys[1][2]:
		_fail("Shift+E was not forwarded as text to the focused browser")
		return
	var glance := InputEventMouseButton.new()
	glance.button_index = MOUSE_BUTTON_RIGHT
	glance.pressed = true
	room._input(glance)
	if room.interaction.mode != State.Mode.WALL_LOOK or not room.wall_looking:
		_fail("Wall look state was not entered")
		return
	glance.pressed = false
	room._input(glance)
	if room.interaction.mode != State.Mode.WALL:
		_fail("Wall look state was not released")
		return
	room._leave_wall()
	if room.interaction.mode != State.Mode.NAVIGATION or room.wall_keyboard_focused:
		_fail("Navigation state was not restored")
		return
	room.browser_layer = CanvasLayer.new()
	room.add_child(room.browser_layer)
	room.browser_view = TextureRect.new()
	room.browser_view.focus_mode = Control.FOCUS_ALL
	room.browser_layer.add_child(room.browser_view)
	room._open_board()
	if room.interaction.mode != State.Mode.FULL_WINDOW or not room.browser_focused or room.wall_keyboard_focused:
		_fail("Full-window state is inconsistent")
		return
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	room._input(cancel)
	if room.interaction.mode != State.Mode.NAVIGATION or room.browser_focused:
		_fail("Full-window cancel did not restore navigation")
		return
	print("PASS: input bindings and interaction modes")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
