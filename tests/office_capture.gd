extends SceneTree
## Off-desktop visual review; writes fresh images to the supplied directory.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a7c3d2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce8f3")
	env.ambient_light_energy = 0.48
	env_node.environment = env
	world.add_child(env_node)
	var office: Node = load("res://scenes/office_interior.tscn").instantiate()
	world.add_child(office)
	var camera := Camera3D.new()
	camera.fov = 80
	world.add_child(camera)
	camera.current = true
	var output := OS.get_cmdline_user_args()[0]
	for view in [
		["entry", Vector3(0, 1.7, 2.5), Vector3(0, 1.6, -4)],
		["customers", Vector3(6, 1.7, 0), Vector3(25, 1.6, 0)],
		["brokerage", Vector3(8, 1.7, -2.8), Vector3(8.5, 1.4, -6.4)],
		["manager_hall", Vector3(24, 1.7, 0), Vector3(32, 1.6, 0)],
		["manager_office", Vector3(30, 1.7, 0), Vector3(35.5, 1.45, 0)],
		["research", Vector3(0, 1.7, -9), Vector3(0, 1.6, -16)],
		["specialist", Vector3(14, 1.7, -2.8), Vector3(14, 1.5, -7)],
		["stairs_lower", Vector3(-5.5, 1.8, 1), Vector3(-14, 3, 1)],
		["stairs_middle", Vector3(-14, 3.1, 0.5), Vector3(-14, 4.5, -7)],
		["stairs_upper", Vector3(-13.5, 4.4, -7), Vector3(-4.5, 5.7, -7)],
		["departments", Vector3(-3, 5.7, -7), Vector3(26, 5.5, -4)],
		["bullpen", Vector3(18, 5.7, 2), Vector3(8, 5.4, -4)],
		["cubicle_entry", Vector3(11.4, 5.7, 0.4), Vector3(11.4, 5.4, -3)],
		["cubicle_inside", Vector3(11.4, 5.7, -1.5), Vector3(11.4, 5.3, -4)],
		["department_north", Vector3(27, 5.7, -18), Vector3(27, 5.4, -24)],
		["department_south", Vector3(-1, 5.7, 4), Vector3(-1, 5.4, 10)],
		["cfo", Vector3(23, 5.7, 4), Vector3(23, 5.4, 10)],
		["office_boards", Vector3(20, 5.7, -14), Vector3(27, 5.5, -19)],
		["bullpen_manager", Vector3(-1, 5.7, -18), Vector3(-1, 5.4, -24)],
		["ceo", Vector3(36.5, 5.7, -15), Vector3(41, 5.4, -13)],
		["ceo_conference", Vector3(39, 5.7, -9), Vector3(39, 5.4, -3)],
		["conference_glass", Vector3(29, 5.7, 0), Vector3(35, 5.4, -3)],
		["conference_wall", Vector3(25, 5.7, -10), Vector3(35, 5.5, -7)],
		["conference", Vector3(36.3, 5.7, 0), Vector3(40, 5.4, -1)]
	]:
		camera.position = view[1]
		camera.look_at(view[2])
		for frame in range(10):
			await process_frame
		var image := root.get_texture().get_image()
		if image == null or image.is_empty() or image.save_png(output.path_join(view[0] + ".png")) != OK:
			push_error("Office screenshot failed")
			quit(1)
			return
	print("OFFICE_CAPTURE_COMPLETE")
	quit(0)
