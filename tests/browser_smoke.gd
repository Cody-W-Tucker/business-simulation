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


func _mouse_button(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	Input.parse_input_event(event)


func _run() -> void:
	room = load("res://main.tscn").instantiate()
	root.add_child(room)
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
	if not await _wait_for(func(): return room.preview_mesh.visible and room.preview_material.albedo_texture != null):
		_fail("Browser texture was not displayed on the board")
		return
	var image: Image = room.preview_material.albedo_texture.get_image()
	if image == null or image.is_empty() or image.get_pixel(400, 300).r < 0.9:
		_fail("Browser fixture did not paint its white background")
		return
	if image.get_size() != Vector2i(2560, 1440):
		_fail("Browser texture is not 2560×1440: %s" % image.get_size())
		return
	var engage := InputEventKey.new()
	engage.keycode = KEY_E
	engage.pressed = true
	Input.parse_input_event(engage)
	await process_frame
	if not room.browser_focused or Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		_fail("E did not focus the board and release the cursor")
		return
	_mouse_button(Vector2(50, 50), true)
	_mouse_button(Vector2(50, 50), false)
	if not await _wait_for(func(): return browser.call("get_title") == "clicked"):
		_fail("Mouse clicks did not reach browser")
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
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	if room.browser_focused or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_fail("Escape did not return focus to the room")
		return
	print("PASS: browser loads, paints, receives mouse and keyboard, persists, and closes focus")
	quit(0)
