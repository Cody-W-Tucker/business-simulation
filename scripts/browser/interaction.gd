extends Node
## Player interaction with browser surfaces and their full-window views.

signal look_requested(relative: Vector2)
signal look_reset_requested

const RoomInput = preload("res://scripts/room_input.gd")
const InteractionState = preload("res://scripts/browser/interaction_state.gd")
const BrowserInput = preload("res://scripts/browser/input.gd")
const BROWSER_FRAME_RATE := 1
const ACTIVE_BROWSER_FRAME_RATE := 120
const BOARD_REACH := 12.0

var camera: Camera3D
var crosshair_layer: CanvasLayer
var keyboard_hint: Label
var boards: Array[Dictionary] = []
var active_board: Dictionary = {}
var browser: Node
var browser_layer: CanvasLayer
var browser_view: TextureRect
var interaction := InteractionState.new()
var wall_cursor_position := Vector2.ZERO
var wall_button := 0
var wall_mouse_position := Vector2.ZERO
var browser_focused: bool:
	get: return interaction.mode == InteractionState.Mode.FULL_WINDOW
var wall_keyboard_focused: bool:
	get: return interaction.is_wall()
var wall_looking: bool:
	get: return interaction.mode == InteractionState.Mode.WALL_LOOK


func initialize(board_list: Array[Dictionary], player_camera: Camera3D, crosshair: CanvasLayer) -> void:
	boards = board_list
	camera = player_camera
	crosshair_layer = crosshair
	keyboard_hint = Label.new()
	keyboard_hint.text = "Board: mouse to draw · hold right mouse to look · Esc to return"
	keyboard_hint.position = Vector2(20, 20)
	keyboard_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keyboard_hint.visible = false
	crosshair_layer.add_child(keyboard_hint)
	_select_board(boards[0])
	var runtime := preload("res://scripts/browser/runtime.gd").new()
	runtime.name = "BrowserRuntime"
	add_child(runtime)
	runtime.browsers_ready.connect(_on_browsers_ready)
	runtime.start(boards, BROWSER_FRAME_RATE, _browser_input)


func is_active() -> bool:
	return browser_focused or wall_keyboard_focused


func handle_navigation(event: InputEvent) -> void:
	if event.is_action_pressed(RoomInput.BOARD_HOME, false, true):
		var target := _target_board(false)
		if not target.is_empty():
			var target_browser: Node = target.get("browser")
			if target_browser != null:
				target_browser.call("load_url", target.url)
	elif event.is_action_pressed(RoomInput.INTERACT, false, true):
		var target := _target_board(false)
		if not target.is_empty():
			_select_board(target)
			_open_board()
	elif event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var target := _target_board(true)
			if not target.is_empty():
				_select_board(target)
				_focus_wall()


func _target_board(require_reach: bool) -> Dictionary:
	var center := get_viewport().get_visible_rect().size / 2.0
	var closest: Dictionary = {}
	var closest_distance := INF
	for board in boards:
		var hit := _board_hit(center, board, false, require_reach)
		if not hit.is_empty() and hit.distance < closest_distance:
			closest = board
			closest_distance = hit.distance
	return closest


func _board_coordinates(screen_position: Vector2, allow_outside := false) -> Vector2:
	var hit := _board_hit(screen_position, active_board, allow_outside, true)
	return hit.get("coordinates", Vector2.INF)


func _board_hit(screen_position: Vector2, board: Dictionary, allow_outside: bool, require_reach: bool) -> Dictionary:
	if board.is_empty():
		return {}
	var node: Node3D = board.node
	var size: Vector2 = board.size
	var origin := node.to_local(camera.project_ray_origin(screen_position))
	var direction := node.global_transform.basis.inverse() * camera.project_ray_normal(screen_position)
	if absf(direction.z) < 0.0001:
		return {}
	var surface: MeshInstance3D = board.mesh
	var distance := (surface.position.z - origin.z) / direction.z
	var hit := origin + direction * distance
	var world_distance := camera.global_position.distance_to(node.to_global(hit))
	if distance <= 0.0 or (not allow_outside and ((require_reach and world_distance > BOARD_REACH) or absf(hit.x) > size.x / 2.0 or absf(hit.y) > size.y / 2.0)):
		return {}
	var view: TextureRect = board.get("view")
	var view_size := view.size if view != null else Vector2(2560, 1440)
	return {"coordinates": Vector2(clampf(hit.x / size.x + 0.5, 0.0, 1.0), clampf(0.5 - hit.y / size.y, 0.0, 1.0)) * view_size, "distance": world_distance}


func _select_board(board: Dictionary) -> void:
	active_board = board
	browser = board.get("browser")
	browser_view = board.get("view")


func _focus_wall() -> void:
	if browser == null:
		OS.shell_open(active_board.url)
		return
	browser.call("set_frame_rate", ACTIVE_BROWSER_FRAME_RATE)
	interaction.mode = InteractionState.Mode.WALL
	look_reset_requested.emit()
	keyboard_hint.visible = true
	for child in crosshair_layer.get_children():
		if child is ColorRect:
			child.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	wall_cursor_position = get_viewport().get_visible_rect().size / 2.0
	Input.warp_mouse(wall_cursor_position)


func _leave_wall() -> void:
	_release_wall_button()
	if browser != null:
		browser.call("set_frame_rate", BROWSER_FRAME_RATE)
	look_reset_requested.emit()
	interaction.mode = InteractionState.Mode.NAVIGATION
	keyboard_hint.visible = false
	for child in crosshair_layer.get_children():
		if child is ColorRect:
			child.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_board() -> void:
	if browser == null:
		OS.shell_open(active_board.url)
		return
	browser.call("set_frame_rate", ACTIVE_BROWSER_FRAME_RATE)
	_release_wall_button()
	look_reset_requested.emit()
	keyboard_hint.visible = false
	interaction.mode = InteractionState.Mode.FULL_WINDOW
	get_viewport().disable_3d = true
	browser_layer.visible = true
	browser_view.visible = true
	crosshair_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	browser_view.grab_focus()


func _close_board() -> void:
	_release_wall_button()
	if browser != null:
		browser.call("set_frame_rate", BROWSER_FRAME_RATE)
	interaction.mode = InteractionState.Mode.NAVIGATION
	get_viewport().disable_3d = false
	wall_button = 0
	browser_layer.visible = false
	browser_view.visible = false
	crosshair_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _release_wall_button() -> void:
	if browser != null:
		match wall_button:
			MOUSE_BUTTON_LEFT: browser.call("set_mouse_left_up")
			MOUSE_BUTTON_RIGHT: browser.call("set_mouse_right_up")
			MOUSE_BUTTON_MIDDLE: browser.call("set_mouse_middle_up")
	wall_button = 0


func handle_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event is InputEventKey:
		if event.is_action_pressed(RoomInput.CANCEL):
			if browser_focused:
				_close_board()
			else:
				_leave_wall()
		elif event.is_action_released(RoomInput.CANCEL) or (event.is_echo() and event.is_action(RoomInput.CANCEL)):
			pass
		else:
			browser.call("set_key_pressed", event.unicode if event.unicode != 0 else event.keycode,
				event.pressed, event.shift_pressed, event.alt_pressed, event.is_command_or_control_pressed())
		get_viewport().set_input_as_handled()
	elif wall_keyboard_focused and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and wall_button == 0:
			wall_cursor_position = event.position
			interaction.mode = InteractionState.Mode.WALL_LOOK
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif not event.pressed and wall_looking:
			interaction.mode = InteractionState.Mode.WALL
			look_reset_requested.emit()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse(wall_cursor_position)
		get_viewport().set_input_as_handled()
	elif wall_keyboard_focused and event is InputEventMouseMotion and wall_looking:
		look_requested.emit(event.screen_relative)
		get_viewport().set_input_as_handled()
	elif wall_keyboard_focused and not wall_looking and (event is InputEventMouseMotion or event is InputEventMouseButton):
		var coordinates := _board_coordinates(event.position, wall_button != 0)
		if coordinates != Vector2.INF:
			wall_mouse_position = coordinates
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed and coordinates != Vector2.INF and wall_button == 0:
				wall_button = event.button_index
			elif not event.pressed and wall_button == event.button_index:
				BrowserInput.forward_mouse(browser, event, wall_mouse_position)
				wall_button = 0
				get_viewport().set_input_as_handled()
				return
			else:
				get_viewport().set_input_as_handled()
				return
		if coordinates != Vector2.INF:
			BrowserInput.forward_mouse(browser, event, coordinates)
		get_viewport().set_input_as_handled()


func _browser_input(event: InputEvent) -> void:
	if browser != null:
		BrowserInput.forward_mouse(browser, event, event.position)


func _on_browsers_ready(layer: CanvasLayer) -> void:
	browser_layer = layer
	_select_board(boards[0])
