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
