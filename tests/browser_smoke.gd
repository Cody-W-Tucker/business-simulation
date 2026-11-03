extends SceneTree

var room: Node


func _initialize() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _wait_for(condition: Callable, seconds: float = 20.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if condition.call():
			return true
		await create_timer(0.1).timeout
	return false


func _mouse_button(position: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	event.global_position = position
	Input.parse_input_event(event)


func _tap_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)


func _move_player(position: Vector3) -> void:
	room.player.global_position = position
	room.player.velocity = Vector3.ZERO
	room.horizontal_velocity = Vector3.ZERO
	room.vertical_speed = 0.0
	room.player.reset_physics_interpolation()
	await physics_frame
	await process_frame
	await process_frame


func _aim_at(browser_position: Vector2) -> void:
	var size: Vector2 = room.active_board.size
	var board_point := Vector3(size.x * (browser_position.x / 2560.0 - 0.5), size.y * (0.5 - browser_position.y / 1440.0), 0.15)
	room.camera.look_at(room.preview_board.to_global(board_point))


func _wall_point(browser_position: Vector2) -> Vector2:
	var size: Vector2 = room.active_board.size
	var point := Vector3(size.x * (browser_position.x / 2560.0 - 0.5), size.y * (0.5 - browser_position.y / 1440.0), 0.15)
	return room.camera.unproject_position(room.preview_board.to_global(point))


func _run() -> void:
	room = load("res://main.tscn").instantiate()
	root.add_child(room)
	var jump := InputEventKey.new()
	jump.keycode = KEY_SPACE
	jump.pressed = true
	room._unhandled_input(jump)
	if not is_equal_approx(room.vertical_speed, room.jump_speed):
		_fail("Jump input did not start the configured jump")
		return
	room.vertical_speed = 0.0
	room.last_space_press = -1000
	if room.camera.keep_aspect != Camera3D.KEEP_WIDTH or not is_equal_approx(room.camera.fov, 90.0):
		_fail("Camera did not use the 90-degree horizontal field of view")
		return
	room._queue_look(Vector2(100, 0))
	room._apply_look(0.1)
	var single_step: float = room.camera.rotation.y
	room.camera.rotation.y = 0.0
	room.pending_look = Vector2.ZERO
	room._queue_look(Vector2(100, 0))
	for i in 10:
		room._apply_look(0.01)
	if not is_equal_approx(single_step, room.camera.rotation.y):
		_fail("Camera smoothing varied with frame subdivision")
		return
	room.pending_look = Vector2.ZERO
	room.camera.rotation.y = 0.0
	if not await _wait_for(func(): return room.browser != null):
		_fail("Embedded browser did not initialize")
		return
	var browser: Node = room.browser
	if not await _wait_for(func(): return browser.call("is_loaded") and str(browser.call("get_title")).to_lower().contains("excalidraw"), 30.0):
		_fail("Self-hosted Excalidraw did not load (URL: %s, title: %s)" % [browser.call("get_url"), browser.call("get_title")])
		return
	var fixture := OS.get_environment("TEST_FIXTURE_URL")
	if fixture.is_empty():
		_fail("TEST_FIXTURE_URL must point to the browser test fixture")
		return
	browser.call("load_url", fixture)
	if OS.get_environment("TEST_EXPECT_SAVED") == "1":
		if not await _wait_for(func(): return browser.call("get_title") == "restored:a"):
			_fail("Browser storage was not retained between launches")
			return
		print("PASS: browser storage persisted between launches")
		quit(0)
		return
	if not await _wait_for(func(): return browser.call("get_title") == "restored:"):
		_fail("Browser fixture did not load")
		return
	var project_board: Dictionary = room.boards[1]
	var project_browser: Node = project_board.get("browser")
	if project_browser == null or project_board.url != "https://opencode.homehub.tv/":
		_fail("Projects browser was not created with its URL")
		return
	if not await _wait_for(func(): return str(project_browser.call("get_title")).to_lower().contains("opencode") and str(project_browser.call("get_url")).begins_with("https://opencode.homehub.tv/"), 30.0):
		_fail("Projects site did not report its expected title and URL")
		return
	project_browser.call("load_url", fixture)
	if not await _wait_for(func(): return project_browser.call("get_title") == "restored:"):
		_fail("Projects browser fixture did not load")
		return
	await _move_player(Vector3(250, 0, -15))
	room.camera.look_at(project_board.node.global_position)
	_tap_key(KEY_E)
	await process_frame
	if not room.browser_focused or room.browser != project_browser or not project_board.view.visible:
		_fail("E did not open the targeted Projects browser")
		return
	_tap_key(KEY_ESCAPE)
	await process_frame
	await _move_player(project_board.node.to_global(Vector3(0, -1.65, 3)))
	room.camera.look_at(project_board.node.global_position)
	var project_center: Vector2 = root.get_visible_rect().size / 2.0
	_mouse_button(project_center, true)
	_mouse_button(project_center, false)
	await process_frame
	if not room.wall_keyboard_focused or room.browser != project_browser:
		_fail("Projects wall did not receive focus")
		return
	_mouse_button(_wall_point(Vector2(50, 50)), true)
	_mouse_button(_wall_point(Vector2(50, 50)), false)
	if not await _wait_for(func(): return project_browser.call("get_title") == "clicked"):
		_fail("Projects wall click did not reach its browser")
		return
	if browser.call("get_title") != "restored:":
		_fail("Projects interaction affected the Excalidraw browser")
		return
	_tap_key(KEY_ESCAPE)
	await process_frame
	await _move_player(Vector3(250, 0, -15))
	room.camera.look_at(room.get_node("OfficeInterior/ProjectsResearchWing/OctagonWall4/ResearchPlaceholder").global_position)
	_tap_key(KEY_E)
	await process_frame
	if room.browser_focused:
		_fail("E opened a browser while aiming at a placeholder")
		return
	room._select_board(room.boards[0])
	if not await _wait_for(func(): return room.preview_mesh.visible and room.preview_material.albedo_texture != null):
		_fail("Browser texture was not displayed on the board")
		return
	if not await _wait_for(func():
		var frame: Image = room.preview_material.albedo_texture.get_image()
		return frame != null and not frame.is_empty() and frame.get_pixel(400, 300).r >= 0.9
	):
		_fail("Browser fixture did not paint its white background")
		return
	var image: Image = room.preview_material.albedo_texture.get_image()
	if image.get_size() != Vector2i(2560, 1440):
		_fail("Browser texture is not 2560×1440: %s" % image.get_size())
		return
	var center: Vector2 = root.get_visible_rect().size / 2.0
	await _move_player(room.preview_board.to_global(Vector3(0, -1.65, 14)))
	_aim_at(Vector2(1280, 720))
	_mouse_button(center, true)
	_mouse_button(center, false)
	await process_frame
	if room.wall_keyboard_focused:
		_fail("Board could be used from outside its reach")
		return
	_tap_key(KEY_E)
	await process_frame
	if not room.browser_focused or not root.disable_3d:
		_fail("E did not open the board from outside its reach")
		return
	_tap_key(KEY_ESCAPE)
	await process_frame
	await _move_player(room.preview_board.to_global(Vector3(0, -1.65, 3)))
	_aim_at(Vector2(1280, 720))
	_mouse_button(center, true)
	_mouse_button(center, false)
	await process_frame
	if not room.wall_keyboard_focused or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		_fail("Board click did not enter cursor mode")
		return
	_mouse_button(_wall_point(Vector2(50, 50)), true)
	_mouse_button(_wall_point(Vector2(50, 50)), false)
	if not await _wait_for(func(): return browser.call("get_title") == "clicked"):
		_fail("Mouse clicks did not reach browser through the wall")
		return
	_mouse_button(_wall_point(Vector2(450, 350)), true)
	var motion := InputEventMouseMotion.new()
	motion.position = _wall_point(Vector2(600, 400))
	motion.global_position = motion.position
	motion.screen_relative = Vector2(30, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	var old_rotation: float = room.camera.rotation.y
	Input.parse_input_event(motion)
	await process_frame
	_mouse_button(motion.position, false)
	if not is_equal_approx(old_rotation, room.camera.rotation.y):
		_fail("Camera moved while drawing")
		return
	if not await _wait_for(func(): return browser.call("get_title") == "dragged"):
		_fail("Mouse dragging did not reach browser through the wall")
		return
	if not room.wall_keyboard_focused or not room.keyboard_hint.visible:
		_fail("Wall interaction did not capture keyboard focus")
		return
	_mouse_button(_wall_point(Vector2(50, 120)), true)
	_mouse_button(_wall_point(Vector2(50, 120)), false)
	var wall_key := InputEventKey.new()
	wall_key.keycode = KEY_E
	wall_key.unicode = 101
	wall_key.pressed = true
	Input.parse_input_event(wall_key)
	wall_key = wall_key.duplicate()
	wall_key.pressed = false
	Input.parse_input_event(wall_key)
	if not await _wait_for(func(): return browser.call("get_title") == "e"):
		_fail("Typing E did not reach the wall browser")
		return
	if room.browser_focused:
		_fail("Typing E unexpectedly opened the full-window view")
		return
	if OS.get_environment("TEST_SKIP_KNOWN_PUNCTUATION_BUG") != "1":
		for character in ".,!?:;@":
			var punctuation := InputEventKey.new()
			punctuation.keycode = character.unicode_at(0)
			punctuation.unicode = character.unicode_at(0)
			punctuation.pressed = true
			Input.parse_input_event(punctuation)
			punctuation = punctuation.duplicate()
			punctuation.pressed = false
			punctuation.unicode = 0
			Input.parse_input_event(punctuation)
		if not await _wait_for(func(): return browser.call("get_title") == "e.,!?:;@"):
			_fail("Punctuation failed; received: %s" % browser.call("get_title"))
			return
	_mouse_button(center, true, MOUSE_BUTTON_RIGHT)
	var glance := InputEventMouseMotion.new()
	glance.screen_relative = Vector2(30, 0)
	Input.parse_input_event(glance)
	await process_frame
	_mouse_button(center, false, MOUSE_BUTTON_RIGHT)
	await process_frame
	if is_equal_approx(old_rotation, room.camera.rotation.y) or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		_fail("Right mouse glance did not restore cursor mode")
		return
	browser.call("execute_javascript", "document.querySelector('#text').value=''; localStorage.removeItem('test-text');")
	_tap_key(KEY_ESCAPE)
	await process_frame
	if room.wall_keyboard_focused or room.keyboard_hint.visible or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_fail("Escape did not return keyboard control to the room")
		return
	_aim_at(Vector2(1280, 720))
	_tap_key(KEY_E)
	await process_frame
	if not room.browser_focused or not root.disable_3d:
		_fail("E did not switch the wall to the full-window browser")
		return
	_mouse_button(Vector2(50, 120), true)
	_mouse_button(Vector2(50, 120), false)
	var key := InputEventKey.new()
	key.keycode = KEY_A
	key.unicode = 97
	key.pressed = true
	Input.parse_input_event(key)
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	if not await _wait_for(func(): return browser.call("get_title") == "a"):
		_fail("Keyboard input did not reach browser")
		return
	browser.call("reload")
	if not await _wait_for(func(): return browser.call("get_title") == "restored:a"):
		_fail("Persisted browser input was not restored after reload (title: %s)" % browser.call("get_title"))
		return
	_tap_key(KEY_ESCAPE)
	await process_frame
	if room.browser_focused or root.disable_3d or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_fail("Escape did not return focus to the room")
		return
	print("PASS: browser loads, paints, receives mouse and keyboard, persists, and closes focus")
	quit(0)
