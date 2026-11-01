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
	# v² / 2g is the approximate height of the ballistic jump.
	if room.jump_speed * room.jump_speed / (2.0 * 12.0) < 4.5:
		push_error("Jump is too small")
		quit(1)
		return
	print("PASS: scene scale, community asset container, boards, and jump settings")
	quit(0)
