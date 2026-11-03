extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _walk_to(room: Node3D, target: Vector3) -> bool:
	for i in range(600):
		var offset: Vector3 = target - room.player.position
		offset.y = 0
		if offset.length() < 0.18:
			return true
		await physics_frame
		room._move_player(offset.normalized(), 2.0, 1.0 / 60.0)
	return false


func _wall_present(room: Node3D, from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [room.player.get_rid()]
	return not room.player.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _count_staff(node: Node) -> int:
	var count := 1 if String(node.name).begins_with("StaffPlaceholder") else 0
	for child in node.get_children():
		count += _count_staff(child)
	return count


func _run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	room.set_physics_process(false)
	await physics_frame
	var office: Node3D = room.get_node_or_null("OfficeInterior")
	if office == null or office.get_node_or_null("CustomersWing/Monitor1") == null or office.get_node_or_null("CustomersWing/Monitor2") == null or office.get_node_or_null("CustomersWing/Monitor3") == null or office.get_node_or_null("ProjectsResearchWing") == null or office.get_node_or_null("DepartmentsWing") == null:
		_fail("Office or placeholder monitors missing")
		return
	for node_path in ["CustomersWing/CustomerDesk", "CustomersWing/CustomerFiles", "CustomersWing/AccountManagerPlaceholder", "CustomersWing/ManagerDesk", "CustomersWing/ProjectManagerPlaceholder", "CustomersWing/ManagerBrowser1", "CustomersWing/ManagerBrowser2", "CustomersWing/ManagerBrowser3"]:
		if office.get_node_or_null(node_path) == null:
			_fail("Missing customer or project manager room object: " + node_path)
			return
	for node_path in ["ReceptionHub/ReceptionistPlaceholder", "DepartmentsWing/CFO", "DepartmentsWing/Sales", "DepartmentsWing/Marketing", "DepartmentsWing/ProductEngineeringandOperations", "DepartmentsWing/CustomerSupport", "DepartmentsWing/PeopleHRandLegal", "DepartmentsWing/InformationTechnology", "DepartmentsWing/SalesandSupportManagers", "DepartmentsWing/CEODesk", "DepartmentsWing/ConferenceTable"]:
		if office.get_node_or_null(node_path) == null:
			_fail("Missing department or reception object: " + node_path)
			return
	if _count_staff(office.get_node("DepartmentsWing")) != 20 or _count_staff(office.get_node("ProjectsResearchWing")) != 0 or _count_staff(office.get_node("CustomersWing")) != 7:
		_fail("Knowledge-office staff placeholder count is incorrect")
		return
	for spec in [["CFO", 1], ["Marketing", 2], ["SalesandSupportManagers", 2], ["InformationTechnology", 1], ["PeopleHRandLegal", 2], ["ProductEngineeringandOperations", 4], ["COO", 1]]:
		var module := office.get_node("DepartmentsWing/" + spec[0])
		if _count_staff(module) != spec[1] or module.get_node_or_null("Desk%d" % spec[1]) == null or module.get_node_or_null("Desk%d" % (spec[1] + 1)) != null or module.get_node_or_null("WhiteboardPlaceholder") == null:
			_fail("Incorrect private office staffing or furnishings: " + spec[0])
			return
		if spec[1] > 1 and module.get_node_or_null("WorkstationDivider1") == null:
			_fail("Shared office missing workstation divider: " + spec[0])
			return
		if module.get_node("WhiteboardPlaceholder").position.z <= 3.0:
			_fail("Office data board must face the bullpen: " + spec[0])
			return
	for spec in [["Sales", 4], ["CustomerSupport", 2]]:
		var team := office.get_node("DepartmentsWing/" + spec[0])
		if _count_staff(team) != spec[1]:
			_fail("Incorrect bullpen staffing: " + spec[0])
			return
		var cubicles := 0
		for child in team.get_children():
			if String(child.name).begins_with("Cubicle"):
				cubicles += 1
		if cubicles != spec[1]:
			_fail("Incorrect bullpen cubicles: " + spec[0])
			return
	if not room.player.position.is_equal_approx(Vector3(250, 0, 2.5)):
		_fail("Player did not spawn in reception")
		return
	await physics_frame
	# Check openings and adjacent solid walls, using the actual player capsule.
	for route in [
		[Vector3(254, 0, 0), Vector3(2, 0, 0), false],
		[Vector3(250, 0, -4), Vector3(0, 0, -2), false],
		[Vector3(258, 0, -1), Vector3(0, 0, -2), false],
		[Vector3(260, 0, -1), Vector3(0, 0, -2), true],
		[Vector3(250, 0, -7), Vector3(0, 0, -2), false],
		[Vector3(256, 0, 0), Vector3(21, 0, 0), false],
		[Vector3(277, 0, 0), Vector3(-21, 0, 0), false],
		[Vector3(277, 0, 0), Vector3(5, 0, 0), false],
		[Vector3(282, 0, 0), Vector3(-5, 0, 0), false],
		[Vector3(277, 0, 3), Vector3(4, 0, 0), true],
		[Vector3(282, 0, 0), Vector3(4, 0, 0), true],
		[Vector3(258, 0, -3), Vector3(0, 0, 2), false],
		[Vector3(250, 0, -10), Vector3(0, 0, 3), false],
		[Vector3(244.5, 0, -15), Vector3(-3, 0, 0), false],
		[Vector3(255.5, 0, -15), Vector3(3, 0, 0), false],
	]:
		if room.player.test_move(Transform3D(Basis.IDENTITY, route[0]), route[1]) != route[2]:
			_fail("Unexpected wall or opening in route: %s" % [route])
			return
	for x in [-0.8, 0.0, 0.8]:
		for side in [-1.0, 1.0]:
			var start := Vector3(250 + x, 0, 4.95 + side)
			if not room.player.test_move(Transform3D(Basis.IDENTITY, start), Vector3(0, 0, -side * 2.0)):
				_fail("Closed return door permits walking through at %s" % start)
				return
	# Jump against the reception ceiling: the near plane must remain below it.
	room.player.position = Vector3(250, 0, 0)
	room.vertical_speed = 0.0
	room.horizontal_velocity = Vector3.ZERO
	await physics_frame
	room._move_player(Vector3.ZERO, 0.0, 1.0 / 60.0)
	if not room._try_jump():
		_fail("Could not start office ceiling jump")
		return
	var hit_ceiling := false
	for i in range(90):
		await physics_frame
		room._move_player(Vector3.ZERO, 0.0, 1.0 / 60.0)
		if room.player.position.y + room.EYE_HEIGHT + room.camera.near >= 3.0:
			_fail("Camera near plane crossed the office ceiling")
			return
		if room.player.is_on_ceiling():
			hit_ceiling = true
	if not hit_ceiling:
		_fail("Office ceiling was not encountered during jump")
		return
	# Walk all three flights and both turns with the actual player controller.
	room.player.position = Vector3(246.0, 0, 1)
	room.vertical_speed = 0.0
	room.horizontal_velocity = Vector3.ZERO
	for target in [Vector3(236, 0, 1), Vector3(236, 0, -7), Vector3(246, 0, -7)]:
		if not await _walk_to(room, target):
			_fail("Could not walk upstairs toward %s; player at %s" % [target, room.player.position])
			return
	if room.player.position.y < 3.8:
		_fail("Staircase did not reach second floor: %s" % room.player.position)
		return
	# Each bullpen desk has a walk-in opening and a tall, solid panel beside it.
	for team_path in ["Sales", "CustomerSupport"]:
		var team: Node3D = office.get_node("DepartmentsWing/" + team_path)
		for cubicle in team.get_children():
			if not String(cubicle.name).begins_with("Cubicle"):
				continue
			var x: float = cubicle.position.x
			var side: float = signf(cubicle.position.z)
			if true:
				for dx in [0.0, 1.1]:
					var start: Vector3 = team.global_transform * Vector3(x + dx, 0, side * 4.2)
					var motion := Vector3(0, 0, -side * 2.4)
					if room.player.test_move(Transform3D(Basis.IDENTITY, start), motion) != (dx != 0.0):
						_fail("Bullpen cubicle opening or partition failed: %s at %s" % [team_path, start])
						return
				var inside: Vector3 = team.global_transform * Vector3(x, 1.6, side * 1.6)
				for delta in [Vector3(1.8, 0, 0), Vector3(-1.8, 0, 0), Vector3(0, 0, -side * 1.8)]:
					if not _wall_present(room, inside, inside + delta):
						_fail("Bullpen cubicle side or rear is open: %s" % team_path)
						return
	# The six private offices retain their open entries and solid outer walls.
	for path in ["CFO", "Marketing", "SalesandSupportManagers", "InformationTechnology", "PeopleHRandLegal", "ProductEngineeringandOperations", "COO"]:
		var module: Node3D = office.get_node("DepartmentsWing/" + path)
		for dx in [0.0, 3.0]:
			var start: Vector3 = module.global_transform * Vector3(dx, 0, 4.0)
			var motion: Vector3 = module.global_basis * Vector3(0, 0, -2.0)
			if room.player.test_move(Transform3D(Basis.IDENTITY, start), motion) != (dx != 0.0):
				_fail("Department entry or wall failed: %s at %s" % [path, start])
				return
		var rear: Vector3 = module.global_transform * Vector3(0, 0, -2.7)
		if not room.player.test_move(Transform3D(Basis.IDENTITY, rear), module.global_basis * Vector3(0, 0, -1)):
			_fail("Department exterior wall is open: " + path)
			return
	for route in [
		[Vector3(284, 4, -15), Vector3(4, 0, 0), false],
		[Vector3(284, 4, 0), Vector3(2, 0, 0), false],
		[Vector3(284, 4, -18), Vector3(3, 0, 0), true],
		[Vector3(284, 4, 4), Vector3(3, 0, 0), true],
		[Vector3(284, 4, -7), Vector3(2, 0, 0), true],
		[Vector3(289, 4, -9), Vector3(0, 0, 4), false],
		[Vector3(289, 4, -5), Vector3(0, 0, -4), false],
		[Vector3(287, 4, -8), Vector3(0, 0, 2), true],
		[Vector3(246, 4, -12), Vector3(-2, 0, 0), true],
	]:
		if room.player.test_move(Transform3D(Basis.IDENTITY, route[0]), route[1]) != route[2]:
			_fail("Conference door or glass failed: %s" % [route])
			return
	# Sweep rays at head height over the complete upper exterior perimeter,
	# including room junctions, instead of sampling just a few wall centers.
	for x in range(-4, 35):
		for z in ([-25.0, 5.0 if x >= 3 and x < 19 else 11.0]):
			if not _wall_present(room, Vector3(250 + x, 5.5, z - 0.6), Vector3(250 + x, 5.5, z + 0.6)):
				_fail("Exterior wall gap at x=%d z=%s" % [x, z])
				return
	for z in range(-18, 5):
		for x in [-5.0, 35.0]:
			# The intentional upstairs entry at x=-5, z=-7 is not an exterior wall.
			if x == -5.0 and z in [-8, -7, -6]:
				continue
			if x == 35.0 and z in [-16, -15, -14, -1, 0, 1]:
				continue
			if not _wall_present(room, Vector3(250 + x - 0.6, 5.5, z), Vector3(250 + x + 0.6, 5.5, z)):
				_fail("Exterior wall gap at x=%s z=%d" % [x, z])
				return
	for z in range(-18, 5):
		if not _wall_present(room, Vector3(292.4, 5.5, z), Vector3(293.6, 5.5, z)):
			_fail("Conference exterior wall gap at z=%d" % z)
			return
	for x in range(36, 43):
		for z in [-19.0, 5.0]:
			if not _wall_present(room, Vector3(250 + x, 5.5, z - 0.6), Vector3(250 + x, 5.5, z + 0.6)):
				_fail("Conference side wall gap at %s, %s" % [x, z])
				return
	for route in [
		[Vector3(236, 2.67, -7), Vector3(-2, 0, 0)],
		[Vector3(236, 2.67, -7), Vector3(0, 0, -2)],
		[Vector3(236, 1.33, 1), Vector3(-2, 0, 0)],
		[Vector3(236, 1.33, 1), Vector3(0, 0, 2)],
	]:
		if not room.player.test_move(Transform3D(Basis.IDENTITY, route[0]), route[1]):
			_fail("Stairwell perimeter is open: %s" % [route])
			return
	for target in [Vector3(236, 0, -7), Vector3(236, 0, 1), Vector3(246, 0, 1)]:
		if not await _walk_to(room, target):
			_fail("Could not walk downstairs toward %s; player at %s" % [target, room.player.position])
			return
	if room.player.position.y > 0.3:
		_fail("Staircase did not return to reception: %s" % room.player.position)
		return
	print("PASS: office structure, reception spawn, doorway and partition collision")
	quit(0)
