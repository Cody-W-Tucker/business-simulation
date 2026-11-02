extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	if not is_equal_approx(room.camera.position.y, 1.7) or room.get_node_or_null("CommunityAssets") == null:
		push_error("Player scale or community asset container is incorrect")
		quit(1)
		return
	if room.boards.size() != 2 or room.boards[0].size != Vector2(8.0, 4.5):
		push_error("Browser board definitions are incorrect")
		quit(1)
		return
	var landscape = room.boards[0].node.get_parent()
	var courtyard = landscape.get_node_or_null("StoneCourtyard")
	var meadow = landscape.get_node_or_null("MeadowGround")
	var tree_border = landscape.get_node_or_null("TreeBorder")
	var placeholder = landscape.get_node_or_null("COMING_SOON")
	var palace_walls = landscape.get_node_or_null("PalaceWalls")
	if landscape.get_node_or_null("TrialRuinedArch") == null:
		push_error("Trial ruined arch is missing")
		quit(1)
		return
	var arch_count := 0
	var world_environment: WorldEnvironment
	var sunlight: DirectionalLight3D
	for child in landscape.get_children():
		if child is WorldEnvironment:
			world_environment = child
		if str(child.name).begins_with("RomanArch"):
			arch_count += 1
		if child is DirectionalLight3D:
			sunlight = child
	if courtyard == null or courtyard.mesh.size != Vector2(64, 64) or meadow == null or meadow.mesh.size != Vector2(150, 150) or placeholder == null or palace_walls == null or arch_count != 4 or tree_border == null or tree_border.get_child_count() != 128 or world_environment == null or world_environment.environment.fog_sky_affect != 0.0:
		push_error("Courtyard, meadow, or unobscured sky is missing")
		quit(1)
		return
	if sunlight == null or not sunlight.shadow_enabled:
		push_error("Directional shadows are disabled")
		quit(1)
		return
	if not physics_interpolation or room.camera.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_OFF:
		push_error("Camera interpolation is not configured")
		quit(1)
		return
	room.camera.position = Vector3(2, 2.7, 3)
	room._sync_external_camera_position()
	if not room.player.position.is_equal_approx(Vector3(2, 1, 3)):
		push_error("Camera teleport did not synchronize the collision body")
		quit(1)
		return
	room.camera.position = Vector3(0, 1.7, 0)
	room._sync_external_camera_position()
	await physics_frame
	var at_pier := Transform3D(Basis.IDENTITY, Vector3(4.85, 0.0, -27.5))
	var at_opening := Transform3D(Basis.IDENTITY, Vector3(0, 0.0, -27.5))
	var at_wall := Transform3D(Basis.IDENTITY, Vector3(12, 0.0, -27.5))
	if not room.player.test_move(at_pier, Vector3(0, 0, -4)) or not room.player.test_move(at_wall, Vector3(0, 0, -5)) or room.player.test_move(at_opening, Vector3(0, 0, -5)):
		push_error("Arch pier collision or opening is incorrect")
		quit(1)
		return
	landscape._make_browser_board("TEST", "https://example.invalid/", Vector3(0, 1.7, -10), 0, Vector2(4, 2))
	var extra: Dictionary = room.boards[2]
	extra.mesh.position.z = 0.4
	room.camera.look_at(extra.node.to_global(Vector3(0, 0, 0.4)))
	var hit: Dictionary = room._target_board(true)
	if hit.is_empty() or hit.url != "https://example.invalid/":
		push_error("A newly defined board could not be targeted")
		quit(1)
		return
	var center: Vector2 = root.get_visible_rect().size / 2.0
	var surface_hit: Dictionary = room._board_hit(center, extra, false, true)
	if surface_hit.is_empty() or absf(surface_hit.distance - 9.6) > 0.01:
		push_error("Board hit testing did not use the mesh surface position")
		quit(1)
		return
	# v² / 2g is the approximate height of the ballistic jump.
	if room.jump_speed * room.jump_speed / (2.0 * 12.0) < 4.5:
		push_error("Jump is too small")
		quit(1)
		return
	print("PASS: scene scale, community asset container, boards, and jump settings")
	quit(0)
