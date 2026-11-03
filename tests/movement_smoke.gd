extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	room.set_physics_process(false)
	await physics_frame
	room._move_player(Vector3.FORWARD, 12.0, 1.0 / 60.0)
	if not room._try_jump():
		_fail("Could not jump from courtyard")
		return
	for i in range(12):
		await physics_frame
		room._move_player(Vector3.RIGHT if i < 6 else Vector3.ZERO, 6.0, 1.0 / 60.0)
		if not room.horizontal_velocity.is_equal_approx(Vector3.FORWARD * 12.0):
			_fail("Airborne inputs changed takeoff momentum")
			return
	if room.player.position.z > -0.8 or room.player.position.y < 1.0:
		_fail("Jump did not preserve horizontal momentum")
		return
	if room._try_jump():
		_fail("Jump incorrectly allowed in midair")
		return
	# Place the player above the north wall, then actually land on its coping.
	room.camera.position = Vector3(12, 9.7, -30.75)
	room._sync_external_camera_position()
	room.horizontal_velocity = Vector3.ZERO
	room.vertical_speed = 0.0
	var landed := false
	for i in range(120):
		await physics_frame
		room._move_player(Vector3.ZERO, 6.0, 1.0 / 60.0)
		if room.player.is_on_floor():
			landed = true
			break
	if not landed or room.player.position.y < 5.0:
		_fail("Did not land on wall")
		return
	var wall_height: float = room.player.position.y
	if not room._try_jump():
		_fail("Could not jump from wall")
		return
	for i in range(10):
		await physics_frame
		room._move_player(Vector3.ZERO, 6.0, 1.0 / 60.0)
	if room.player.position.y < wall_height + 0.5:
		_fail("Wall jump did not lift the player")
		return
	# Flight uses twice the running speed in both axes, irrespective of Shift.
	room.player.position = Vector3(0, 10, 0)
	room.flying = true
	for fast in [false, true]:
		if fast:
			Input.action_press("room_fast")
		Input.action_press("room_jump")
		await physics_frame
		room._move_player(Vector3.RIGHT, 12.0 if fast else 6.0, 1.0 / 60.0)
		if not is_equal_approx(room.horizontal_velocity.x, 24.0) or not is_equal_approx(room.vertical_speed, 24.0):
			_fail("Flight speed must be twice running speed with or without Shift")
			return
		Input.action_release("room_jump")
		Input.action_release("room_fast")
	Input.action_press("room_descend")
	await physics_frame
	room._move_player(Vector3.ZERO, 6.0, 1.0 / 60.0)
	Input.action_release("room_descend")
	if not is_equal_approx(room.vertical_speed, -24.0):
		_fail("Flight descent speed must be twice running speed")
		return
	print("PASS: ground jump, airborne momentum, wall jump and flight speeds")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
