extends Node3D

const EXCALIDRAW_URL := "https://draw.homehub.tv/"
const REFRESH_SECONDS := 60.0

var camera: Camera3D
var preview_material: StandardMaterial3D
var preview_board: Node3D
var preview_mesh: MeshInstance3D
var cef: Node
var browser: Node
var browser_layer: CanvasLayer
var browser_view: TextureRect
var crosshair_layer: CanvasLayer
var browser_focused := false
var browser_pid := -1
var refresh_in := INF
var screenshot_path: String
var profile_path: String
var vertical_speed := 0.0
var flying := false
var last_space_press := -1000
const EYE_HEIGHT := 2.5


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
	_move_camera(delta)
	if browser != null:
		if browser_view.texture != null and preview_material.albedo_texture != browser_view.texture:
			preview_material.albedo_texture = browser_view.texture
			preview_mesh.visible = true
		return
	if browser_pid > 0 and not OS.is_process_running(browser_pid):
		browser_pid = -1
		var image := Image.load_from_file(screenshot_path)
		if image != null and not image.is_empty():
			image.generate_mipmaps()
			preview_material.albedo_texture = ImageTexture.create_from_image(image)
			preview_mesh.visible = true
		refresh_in = REFRESH_SECONDS
	elif browser_pid < 0:
		refresh_in -= delta
		if refresh_in <= 0.0:
			_start_preview()


func _move_camera(delta: float) -> void:
	if browser_focused or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var forward := Vector3(-sin(camera.rotation.y), 0, -cos(camera.rotation.y))
	var right := Vector3(cos(camera.rotation.y), 0, -sin(camera.rotation.y))
	var movement := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		movement += forward
	if Input.is_key_pressed(KEY_S):
		movement -= forward
	if Input.is_key_pressed(KEY_D):
		movement += right
	if Input.is_key_pressed(KEY_A):
		movement -= right
	if movement != Vector3.ZERO:
		var speed := 12.0 if Input.is_key_pressed(KEY_SHIFT) else 6.0
		camera.position += movement.normalized() * speed * delta
		camera.position.x = clampf(camera.position.x, -29.3, 29.3)
		camera.position.z = clampf(camera.position.z, -29.3, 29.3)
	if flying:
		var vertical_input := int(Input.is_key_pressed(KEY_SPACE)) - int(Input.is_key_pressed(KEY_C))
		var flight_speed := 12.0 if Input.is_key_pressed(KEY_SHIFT) else 6.0
		camera.position.y = clampf(camera.position.y + vertical_input * flight_speed * delta, EYE_HEIGHT, 24.5)
		return
	vertical_speed -= 12.0 * delta
	camera.position.y += vertical_speed * delta
	if camera.position.y < EYE_HEIGHT:
		camera.position.y = EYE_HEIGHT
		vertical_speed = 0.0


func _start_preview() -> void:
	# Remove the previous image so a failed capture cannot masquerade as a fresh one.
	if FileAccess.file_exists(screenshot_path):
		DirAccess.remove_absolute(screenshot_path)
	browser_pid = OS.create_process("chromium", PackedStringArray([
		"--headless", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
		"--no-default-browser-check", "--user-data-dir=" + profile_path,
		"--window-size=2560,1440", "--virtual-time-budget=10000",
		"--screenshot=" + screenshot_path, EXCALIDRAW_URL
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
		camera.rotation.y -= event.screen_relative.x * 0.00075
		camera.rotation.x = clampf(camera.rotation.x - event.screen_relative.y * 0.00075, -1.2, 1.2)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
			KEY_SPACE:
				if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
					var now := Time.get_ticks_msec()
					if now - last_space_press <= 350:
						flying = not flying
						vertical_speed = 0.0
						last_space_press = -1000
					else:
						last_space_press = now
						if not flying and camera.position.y <= EYE_HEIGHT:
							vertical_speed = 5.0
			KEY_E:
				if _aiming_at_board():
					_open_board()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if _aiming_at_board():
			_open_board()


func _aiming_at_board() -> bool:
		var center := get_viewport().get_visible_rect().size / 2.0
		var origin := camera.project_ray_origin(center)
		var direction := camera.project_ray_normal(center)
		var local_origin := preview_board.to_local(origin)
		var local_direction := preview_board.global_transform.basis.inverse() * direction
		if absf(local_direction.z) > 0.0001:
			var distance := -local_origin.z / local_direction.z
			var hit := local_origin + local_direction * distance
			return distance > 0.0 and absf(hit.x) <= 4.0 and absf(hit.y) <= 2.25
		return false


func _open_board() -> void:
	if browser == null:
		OS.shell_open(EXCALIDRAW_URL)
		return
	browser_focused = true
	browser_layer.visible = true
	crosshair_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	browser_view.grab_focus()


func _close_board() -> void:
	browser_focused = false
	browser_layer.visible = false
	crosshair_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if not browser_focused:
		return
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			_close_board()
		else:
			browser.call("set_key_pressed", event.unicode if event.unicode != 0 else event.keycode,
				event.pressed, event.shift_pressed, event.alt_pressed, event.is_command_or_control_pressed())
		get_viewport().set_input_as_handled()


func _browser_input(event: InputEvent) -> void:
	if browser == null:
		return
	if event is InputEventMouseMotion:
		browser.call("set_mouse_moved", int(event.position.x), int(event.position.y))
	elif event is InputEventMouseButton:
		browser.call("set_mouse_moved", int(event.position.x), int(event.position.y))
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				browser.call("set_mouse_left_down" if event.pressed else "set_mouse_left_up")
			MOUSE_BUTTON_RIGHT:
				browser.call("set_mouse_right_down" if event.pressed else "set_mouse_right_up")
			MOUSE_BUTTON_MIDDLE:
				browser.call("set_mouse_middle_down" if event.pressed else "set_mouse_middle_up")
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					browser.call("set_mouse_wheel_vertical", 2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -2, event.shift_pressed, event.ctrl_pressed, event.alt_pressed)


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
	browser_view = TextureRect.new()
	browser_view.focus_mode = Control.FOCUS_ALL
	browser_view.mouse_filter = Control.MOUSE_FILTER_STOP
	browser_view.gui_input.connect(_browser_input)
	browser_layer.add_child(browser_view)
	browser_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	browser = cef.call("create_browser", EXCALIDRAW_URL, browser_view, {"javascript": true, "webgl": true})
	if browser == null:
		push_warning("gdCEF browser creation failed: " + str(cef.call("get_error")))
		browser_layer.visible = false
		_start_preview()
		return
	browser_view.resized.connect(func(): browser.call("resize", browser_view.size))
	browser_layer.visible = false


func _box(parent: Node3D, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material = material
	instance.mesh = mesh
	instance.position = position
	parent.add_child(instance)
	return instance


func _make_board(title: String, subtitle: String, position: Vector3, angle: float, board_size := Vector2(5.0, 2.84)) -> Node3D:
	var board := Node3D.new()
	board.position = position
	board.rotation.y = angle
	add_child(board)
	_box(board, Vector3(board_size.x + 0.3, board_size.y + 0.3, 0.14), Vector3.ZERO, Color("334155"))
	_box(board, Vector3(board_size.x, board_size.y, 0.04), Vector3(0, 0, 0.09), Color("f3f3ee"))
	var heading := Label3D.new()
	heading.text = title
	heading.font_size = 42
	heading.pixel_size = 0.008
	heading.modulate = Color("293a4a")
	heading.position = Vector3(0, 0.35, 0.13)
	board.add_child(heading)
	var description := Label3D.new()
	description.text = subtitle
	description.font_size = 22
	description.pixel_size = 0.008
	description.modulate = Color("758494")
	description.position = Vector3(0, -0.25, 0.13)
	board.add_child(description)
	return board


func _build_room() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("202a38")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce8f3")
	env.ambient_light_energy = 0.85
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 0.8
	add_child(light)
	_box(self, Vector3(60, 0.2, 60), Vector3(0, -0.1, 0), Color("657888"))
	_box(self, Vector3(60, 25, 0.2), Vector3(0, 12.5, -30), Color("d8e0df"))
	_box(self, Vector3(60, 25, 0.2), Vector3(0, 12.5, 30), Color("d8e0df"))
	_box(self, Vector3(0.2, 25, 60), Vector3(-30, 12.5, 0), Color("c7d3d4"))
	_box(self, Vector3(0.2, 25, 60), Vector3(30, 12.5, 0), Color("c7d3d4"))
	_box(self, Vector3(60, 0.15, 60), Vector3(0, 25, 0), Color("e4e9e6"))
	preview_board = _make_board("EXCALIDRAW", "Loading preview...", Vector3(0, 2.5, -29.85), 0, Vector2(8.0, 4.5))
	preview_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(8.0, 4.5)
	preview_material = StandardMaterial3D.new()
	preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	preview_material.albedo_color = Color.WHITE
	quad.material = preview_material
	preview_mesh.mesh = quad
	preview_mesh.position.z = 0.15
	preview_mesh.visible = false
	preview_board.add_child(preview_mesh)
	_make_board("YOUR IDEAS", "A whiteboard for what's next", Vector3(-29.85, 2.7, 0), PI / 2.0)
	_make_board("PROJECTS", "Another space to make your own", Vector3(29.85, 2.7, 0), -PI / 2.0)
	camera = Camera3D.new()
	camera.position = Vector3(0, 2.5, 0)
	camera.current = true
	camera.fov = 45
	add_child(camera)


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
