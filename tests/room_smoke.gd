extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	room.set_physics_process(false)
	await physics_frame
	if not room.player.position.is_equal_approx(Vector3(250, 0, 2.5)) or room.get_node_or_null("CommunityAssets") == null:
		push_error("Reception spawn or community asset container is incorrect")
		quit(1)
		return
	if room.boards.size() != 2 or room.boards[0].size != Vector2(3.0, 1.6875):
		push_error("Browser board definitions are incorrect")
		quit(1)
		return
	if room.find_child("StoneCourtyard", true, false) != null:
		push_error("Deprecated courtyard is still active")
		quit(1)
		return
	if not physics_interpolation or room.camera.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_OFF:
		push_error("Camera interpolation is not configured")
		quit(1)
		return
	room.camera.position = Vector3(252, 2.7, 3)
	room._sync_external_camera_position()
	if not room.player.position.is_equal_approx(Vector3(252, 1, 3)):
		push_error("Camera teleport did not synchronize the collision body")
		quit(1)
		return
	# Aim from the center of the research hub at each real screen.
	room.camera.position = Vector3(250, 1.7, -15)
	room._sync_external_camera_position()
	for board in room.boards:
		if not String(board.node.get_parent().get_path()).contains("ProjectsResearchWing"):
			push_error("Browser is not in the research hub")
			quit(1)
			return
		room.camera.look_at(board.node.to_global(Vector3(0, 0, 0.15)))
		var target: Dictionary = room._target_board(true)
		if target.is_empty() or target.url != board.url:
			push_error("Research browser could not be targeted: " + board.url)
			quit(1)
			return
		var hit: Dictionary = room._board_hit(root.get_visible_rect().size / 2.0, board, false, true)
		if hit.is_empty() or hit.coordinates.distance_to(Vector2(1280, 720)) > 1.0:
			push_error("Browser center coordinates are incorrect")
			quit(1)
			return
	if room.jump_speed * room.jump_speed / (2.0 * 12.0) < 4.5:
		push_error("Jump is too small")
		quit(1)
		return
	print("PASS: reception spawn, research browsers, targeting, and jump settings")
	quit(0)
