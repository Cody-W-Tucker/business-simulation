extends Node3D

const RoomInput = preload("res://scripts/room_input.gd")
const InteractionState = preload("res://scripts/interaction_state.gd")
const PlayerMovement = preload("res://scripts/player_movement.gd")
const BrowserInput = preload("res://scripts/browser_input.gd")
const REFRESH_SECONDS := 60.0
const BROWSER_FRAME_RATE := 120
const BOARD_REACH := 12.0
const OFFICE_ORIGIN := Vector3(250, 0, 0)

@export_range(60.0, 110.0, 1.0) var horizontal_fov := 90.0
@export_range(0.0, 50.0, 1.0) var look_smoothing := 25.0
@export_range(0.5, 1.0, 0.01) var wall_brightness := 0.88
@export_range(1.0, 20.0, 0.5) var jump_speed := 11.0

var camera: Camera3D
var player: CharacterBody3D
var last_camera_position := Vector3.ZERO
var pending_look := Vector2.ZERO
var preview_material: StandardMaterial3D
var preview_board: Node3D
var preview_mesh: MeshInstance3D
var cef: Node
var browser: Node
var browser_layer: CanvasLayer
var browser_view: TextureRect
var boards: Array[Dictionary] = []
var active_board: Dictionary = {}
var embedded_active := false
var crosshair_layer: CanvasLayer
var keyboard_hint: Label
var interaction := InteractionState.new()
var employee_directory: Node
var browser_focused: bool:
	get: return interaction.mode == InteractionState.Mode.FULL_WINDOW
var wall_keyboard_focused: bool:
	get: return interaction.is_wall()
var wall_looking: bool:
	get: return interaction.mode == InteractionState.Mode.WALL_LOOK
var wall_cursor_position := Vector2.ZERO
var wall_button := 0
var wall_mouse_position := Vector2.ZERO
var browser_pid := -1
var refresh_in := INF
var screenshot_path: String
var profile_path: String
var vertical_speed := 0.0
var horizontal_velocity := Vector3.ZERO
var flying := false
var last_space_press := -1000
const EYE_HEIGHT := 1.7
const PLAYER_HEIGHT := EYE_HEIGHT + 0.2


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("171e2b"))
	_build_room()
	_build_crosshair()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	screenshot_path = ProjectSettings.globalize_path("user://excalidraw-preview.png")
	profile_path = ProjectSettings.globalize_path("user://preview-browser")
	if DisplayServer.get_name() != "headless":
		if OS.get_environment("ROOM_ENABLE_GDCEF") == "1":
			_start_embedded_browser.call_deferred()
		else:
			_start_preview()


func _process(delta: float) -> void:
	_sync_external_camera_position()
	# Physics supplies collision-safe positions; the camera follows between ticks
	# while mouse look stays responsive at the display's render rate.
	camera.global_position = player.get_global_transform_interpolated().origin + Vector3.UP * EYE_HEIGHT
	last_camera_position = camera.position
	_apply_look(delta)
	if embedded_active:
		for board in boards:
			var view: TextureRect = board.get("view")
			if view != null and view.texture != null and board.material.albedo_texture != view.texture:
				board.material.albedo_texture = view.texture
				board.mesh.visible = true
		return
	if browser_pid > 0 and not OS.is_process_running(browser_pid):
		browser_pid = -1
		var image := Image.load_from_file(screenshot_path)
		if image != null and not image.is_empty():
			image.generate_mipmaps()
			boards[0].material.albedo_texture = ImageTexture.create_from_image(image)
			boards[0].mesh.visible = true
		refresh_in = REFRESH_SECONDS
	elif browser_pid < 0:
		refresh_in -= delta
		if refresh_in <= 0.0:
			_start_preview()


func _physics_process(delta: float) -> void:
	_sync_external_camera_position()
	_move_camera(delta)


func _sync_external_camera_position() -> void:
	# Preserve callers that deliberately reposition the camera, including tests.
	if not camera.position.is_equal_approx(last_camera_position):
		player.global_position = camera.global_position - Vector3.UP * EYE_HEIGHT
		player.reset_physics_interpolation()
		last_camera_position = camera.position


func _move_camera(delta: float) -> void:
	if browser_focused or wall_keyboard_focused or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var forward := Vector3(-sin(camera.rotation.y), 0, -cos(camera.rotation.y))
	var right := Vector3(cos(camera.rotation.y), 0, -sin(camera.rotation.y))
	var input := RoomInput.movement()
	var movement := right * input.x - forward * input.y
	var speed: float = PlayerMovement.RUN_SPEED if Input.is_action_pressed(RoomInput.FAST) else PlayerMovement.WALK_SPEED
	_move_player(movement, speed, delta)


func _is_on_jump_surface() -> bool:
	return PlayerMovement.is_on_jump_surface(self)


func _try_jump() -> bool:
	return PlayerMovement.try_jump(self)


func _move_player(movement: Vector3, speed: float, delta: float) -> void:
	PlayerMovement.move(self, movement, speed, delta)


func _start_preview() -> void:
	# Remove the previous image so a failed capture cannot masquerade as a fresh one.
	if FileAccess.file_exists(screenshot_path):
		DirAccess.remove_absolute(screenshot_path)
	browser_pid = OS.create_process("chromium", PackedStringArray([
		"--headless", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
		"--no-default-browser-check", "--user-data-dir=" + profile_path,
		"--window-size=2560,1440", "--virtual-time-budget=10000",
		"--screenshot=" + screenshot_path, boards[0].url
	]))
	if browser_pid <= 0:
		browser_pid = -1
		refresh_in = REFRESH_SECONDS


func _exit_tree() -> void:
	if cef != null:
		cef.call("shutdown")
	if browser_pid > 0 and OS.is_process_running(browser_pid):
		OS.kill(browser_pid)


func _unhandled_input(event: InputEvent) -> void:
	if browser_focused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_queue_look(event.screen_relative)
	if event.is_action_pressed(RoomInput.CANCEL):
		_release_wall_button()
		pending_look = Vector2.ZERO
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(RoomInput.JUMP):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var now := Time.get_ticks_msec()
			if now - last_space_press <= 350:
				flying = not flying
				vertical_speed = 0.0
				last_space_press = -1000
			else:
				last_space_press = now
				_try_jump()
	elif event.is_action_pressed(RoomInput.INTERACT):
		var target := _target_board(false)
		if not target.is_empty():
			_select_board(target)
			_open_board()
	if event is InputEventMouseButton:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
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
	preview_board = board.node
	preview_mesh = board.mesh
	preview_material = board.material
	browser = board.get("browser")
	browser_view = board.get("view")


func _focus_wall() -> void:
	if browser == null:
		OS.shell_open(active_board.url)
		return
	interaction.mode = InteractionState.Mode.WALL
	pending_look = Vector2.ZERO
	keyboard_hint.visible = true
	for child in crosshair_layer.get_children():
		if child is ColorRect:
			child.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	wall_cursor_position = get_viewport().get_visible_rect().size / 2.0
	Input.warp_mouse(wall_cursor_position)


func _leave_wall() -> void:
	_release_wall_button()
	pending_look = Vector2.ZERO
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
	_release_wall_button()
	pending_look = Vector2.ZERO
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


func _input(event: InputEvent) -> void:
	if not browser_focused and not wall_keyboard_focused:
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
			pending_look = Vector2.ZERO
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.warp_mouse(wall_cursor_position)
		get_viewport().set_input_as_handled()
	elif wall_keyboard_focused and event is InputEventMouseMotion and wall_looking:
		_queue_look(event.screen_relative)
		get_viewport().set_input_as_handled()
	elif wall_keyboard_focused and not wall_looking and (event is InputEventMouseMotion or event is InputEventMouseButton):
		var coordinates := _board_coordinates(event.position, wall_button != 0)
		if coordinates != Vector2.INF:
			wall_mouse_position = coordinates
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			if event.pressed and coordinates != Vector2.INF and wall_button == 0:
				wall_button = event.button_index
			elif not event.pressed and wall_button == event.button_index:
				_forward_browser_mouse(event, wall_mouse_position)
				wall_button = 0
				get_viewport().set_input_as_handled()
				return
			else:
				get_viewport().set_input_as_handled()
				return
		if coordinates != Vector2.INF:
			_forward_browser_mouse(event, coordinates)
		get_viewport().set_input_as_handled()


func _browser_input(event: InputEvent) -> void:
	if browser == null:
		return
	_forward_browser_mouse(event, event.position)


func _queue_look(relative: Vector2) -> void:
	pending_look += relative * 0.00075


func _apply_look(delta: float) -> void:
	if pending_look == Vector2.ZERO:
		return
	var weight := 1.0 if look_smoothing <= 0.0 else 1.0 - exp(-look_smoothing * delta)
	var step := pending_look * weight
	pending_look -= step
	if pending_look.length_squared() < 0.0000000001:
		pending_look = Vector2.ZERO
	camera.rotation.y -= step.x
	camera.rotation.x = clampf(camera.rotation.x - step.y, -1.2, 1.2)


func _forward_browser_mouse(event: InputEvent, position: Vector2) -> void:
	BrowserInput.forward_mouse(browser, event, position)


func _start_embedded_browser() -> void:
	if not ClassDB.class_exists("GdCEF"):
		var result := GDExtensionManager.load_extension("res://cef_artifacts/gdcef.gdextension")
		if result != GDExtensionManager.LOAD_STATUS_OK:
			push_warning("gdCEF unavailable; using browser fallback")
			_start_preview()
			return
	cef = ClassDB.instantiate("GdCEF")
	if cef == null:
		push_warning("gdCEF class unavailable; using browser fallback")
		_start_preview()
		return
	add_child(cef)
	var cache := ProjectSettings.globalize_path("user://gdcef-cache")
	DirAccess.make_dir_recursive_absolute(cache)
	if not cef.call("initialize", {"root_cache_path": cache, "cache_path": cache, "log_file": ProjectSettings.globalize_path("user://gdcef.log")}):
		push_warning("gdCEF initialization failed: " + str(cef.call("get_error")))
		_start_preview()
		return
	browser_layer = CanvasLayer.new()
	add_child(browser_layer)
	for board in boards:
		var view := TextureRect.new()
		view.focus_mode = Control.FOCUS_ALL
		view.mouse_filter = Control.MOUSE_FILTER_STOP
		view.gui_input.connect(_browser_input)
		browser_layer.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		view.visible = false
		board["view"] = view
	await get_tree().process_frame
	for board in boards:
		var view: TextureRect = board.view
		var instance: Node = cef.call("create_browser", board.url, view, {"javascript": true, "webgl": true, "frame_rate": BROWSER_FRAME_RATE})
		board["browser"] = instance
		if instance == null:
			push_warning("gdCEF browser creation failed for %s: %s" % [board.url, cef.call("get_error")])
		else:
			embedded_active = true
			view.resized.connect(_resize_browser.bind(instance, view))
	_select_board(boards[0])
	browser_layer.visible = false
	if not embedded_active:
		_start_preview()


func _resize_browser(instance: Node, view: TextureRect) -> void:
	instance.call("resize", view.size)


func _build_room() -> void:
	var office := preload("res://scenes/office_interior.tscn").instantiate() as Node3D
	office.position = OFFICE_ORIGIN
	add_child(office)
	employee_directory = preload("res://scripts/employee_directory.gd").new()
	employee_directory.name = "EmployeeDirectory"
	add_child(employee_directory)
	employee_directory.initialize(office, preload("res://data/employee_roster.tres"))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("171e2b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d9e2ed")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var board_builder := preload("res://scripts/browser_boards.gd").new()
	board_builder.name = "BrowserBoards"
	add_child(board_builder)
	board_builder.wall_brightness = wall_brightness
	for spec in [[0, "EXCALIDRAW", board_builder.EXCALIDRAW_URL], [2, "PROJECTS", board_builder.PROJECTS_URL]]:
		var wall: Node3D = office.get_node("ProjectsResearchWing/OctagonWall%d" % spec[0])
		for child in wall.get_children():
			if child.name in ["ResearchScreen", "ResearchPlaceholder"] or child is Label3D:
				child.visible = false
		var inward := signf(wall.basis.z.dot(Vector3(0, 0, -15) - wall.position))
		board_builder._make_browser_board(spec[1], spec[2], Vector3.ZERO, 0.0, Vector2(3.0, 1.6875))
		var board: Node3D = board_builder.boards.back().node
		board.reparent(wall, false)
		board.position = Vector3(0, 1.65, inward * 0.16)
		board.rotation.y = 0.0 if inward > 0 else PI
	boards = board_builder.boards
	_select_board(boards[0])
	camera = Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.position = OFFICE_ORIGIN + Vector3(0, EYE_HEIGHT, 2.5)
	camera.current = true
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = horizontal_fov
	add_child(camera)
	player = CharacterBody3D.new()
	player.name = "PlayerCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = PLAYER_HEIGHT
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = PLAYER_HEIGHT / 2.0
	player.add_child(shape)
	add_child(player)
	player.position = OFFICE_ORIGIN + Vector3(0, 0, 2.5)
	last_camera_position = camera.position


func _build_crosshair() -> void:
	crosshair_layer = CanvasLayer.new()
	add_child(crosshair_layer)
	for bar in [Rect2(-7, -1, 14, 2), Rect2(-1, -7, 2, 14)]:
		var line := ColorRect.new()
		line.color = Color(0.15, 0.2, 0.25, 0.85)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.set_anchors_preset(Control.PRESET_CENTER)
		line.offset_left = bar.position.x
		line.offset_top = bar.position.y
		line.offset_right = bar.end.x
		line.offset_bottom = bar.end.y
		crosshair_layer.add_child(line)
	keyboard_hint = Label.new()
	keyboard_hint.text = "Board: mouse to draw · hold right mouse to look · Esc to return"
	keyboard_hint.position = Vector2(20, 20)
	keyboard_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keyboard_hint.visible = false
	crosshair_layer.add_child(keyboard_hint)
