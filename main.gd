extends Node3D

const RoomInput = preload("res://scripts/room_input.gd")
const PlayerMovement = preload("res://scripts/player_movement.gd")
const OFFICE_ORIGIN := Vector3(250, 0, 0)
const EYE_HEIGHT := 1.7
const PLAYER_HEIGHT := EYE_HEIGHT + 0.2

@export_range(60.0, 110.0, 1.0) var horizontal_fov := 90.0
@export_range(0.0, 50.0, 1.0) var look_smoothing := 25.0
@export_range(0.5, 1.0, 0.01) var wall_brightness := 0.88
@export_range(1.0, 20.0, 0.5) var jump_speed := 11.0

var camera: Camera3D
var player: CharacterBody3D
var last_camera_position := Vector3.ZERO
var pending_look := Vector2.ZERO
var browser_interaction: Node
var employee_directory: Node
var crosshair_layer: CanvasLayer
var vertical_speed := 0.0
var horizontal_velocity := Vector3.ZERO
var flying := false
var last_space_press := -1000


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("171e2b"))
	_build_crosshair()
	_build_room()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_sync_external_camera_position()
	# Physics supplies collision-safe positions while mouse look stays per-frame.
	camera.global_position = player.get_global_transform_interpolated().origin + Vector3.UP * EYE_HEIGHT
	last_camera_position = camera.position
	_apply_look(delta)


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
	if browser_interaction.is_active() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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


func _input(event: InputEvent) -> void:
	if browser_interaction != null:
		browser_interaction.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if browser_interaction.is_active():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_queue_look(event.screen_relative)
	if event.is_action_pressed(RoomInput.CANCEL):
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
	elif event is InputEventMouseButton and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	else:
		browser_interaction.handle_navigation(event)


func _queue_look(relative: Vector2) -> void:
	pending_look += relative * 0.00075


func _reset_look() -> void:
	pending_look = Vector2.ZERO


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
	var board_builder := preload("res://scripts/browser/boards.gd").new()
	board_builder.name = "BrowserBoards"
	add_child(board_builder)
	board_builder.wall_brightness = wall_brightness
	preload("res://scripts/office_browser_layout.gd").populate(office, board_builder)
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
	browser_interaction = preload("res://scripts/browser/interaction.gd").new()
	browser_interaction.name = "BrowserInteraction"
	add_child(browser_interaction)
	browser_interaction.look_requested.connect(_queue_look)
	browser_interaction.look_reset_requested.connect(_reset_look)
	browser_interaction.initialize(board_builder.boards, camera, crosshair_layer)


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
