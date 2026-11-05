extends SceneTree


func _initialize() -> void:
	var office: Node3D = load("res://scenes/office_interior.tscn").instantiate()
	var builder: Node3D = load("res://scripts/browser/boards.gd").new()
	root.add_child(office)
	root.add_child(builder)
	load("res://scripts/office_browser_layout.gd").populate(office, builder)
	if builder.boards.size() != 7:
		push_error("Office layout must create seven browser surfaces without the main scene")
		quit(1)
		return
	for board in builder.boards:
		if not office.is_ancestor_of(board.node) or board.node.get_parent() == builder:
			push_error("Each browser surface must be placed in the office")
			quit(1)
			return
	print("PASS: office browser layout works independently of the world and browser runtime")
	quit(0)
