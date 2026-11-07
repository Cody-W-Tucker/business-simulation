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


func _has_label(node: Node, text: String) -> bool:
	if node is Label3D and text in node.text:
		return true
	for child in node.get_children():
		if _has_label(child, text):
			return true
	return false


func _run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	room.set_physics_process(false)
	await physics_frame
	var office: Node3D = room.get_node_or_null("OfficeInterior")
	if office == null or office.get_node_or_null("ProjectsResearchWing") == null or office.get_node_or_null("DepartmentsWing") == null:
		_fail("Office or placeholder monitors missing")
		return
	if office.find_children("*ThinClient*", "Node3D", true, false).size() != 23 or office.find_children("*DevelopmentWorkstation*", "Node3D", true, false).size() != 3:
		_fail("The office must contain 23 thin clients and three development workstations")
		return
	if office.get_node_or_null("DepartmentsWing/ITEngineeringandOperations/NetworkCloset/ServerRack/CollisionShape3D") == null or office.get_node_or_null("DepartmentsWing/ITEngineeringandOperations/NetworkCloset/NetworkSwitch") == null:
		_fail("The network closet must contain a collidable server rack and switch")
		return
	var closet := office.get_node("DepartmentsWing/ITEngineeringandOperations/NetworkCloset")
	var closet_frames: Array[MeshInstance3D] = []
	var frame_material := (closet.get_node("FrontFrame") as MeshInstance3D).get_active_material(0)
	for child in closet.get_children():
		if child is MeshInstance3D and (child.get_active_material(0) == frame_material or child.name == "EntryLintel"):
			closet_frames.append(child)
	if closet_frames.size() != 11:
		_fail("Network closet must retain all posts, rails and its lintel")
		return
	for i in range(closet_frames.size()):
		var bounds: AABB = closet_frames[i].transform * closet_frames[i].get_aabb()
		for j in range(i + 1, closet_frames.size()):
			var other_bounds: AABB = closet_frames[j].transform * closet_frames[j].get_aabb()
			var overlap := bounds.intersection(other_bounds)
			if overlap.size.x > 0.00001 and overlap.size.y > 0.00001 and overlap.size.z > 0.00001:
				_fail("Network closet frame meshes overlap: %s and %s (%s, %s)" % [closet_frames[i].name, closet_frames[j].name, bounds, other_bounds])
				return
	var threshold_wall: MeshInstance3D = office.get_node("DepartmentStairs/EastMiddleWall")
	var upper_floor: MeshInstance3D = office.get_node("DepartmentsWing/DepartmentsCommonFloor")
	var wall_top := threshold_wall.global_position.y + (threshold_wall.mesh as BoxMesh).size.y / 2.0
	var floor_top := upper_floor.global_position.y + (upper_floor.mesh as BoxMesh).size.y / 2.0
	if floor_top - wall_top < 0.01:
		_fail("Stair threshold wall cap overlaps the upstairs floor surface")
		return
	var ramp := office.get_node("DepartmentStairs/StraightFlight").find_child("WalkingSurface", true, false) as MeshInstance3D
	var landing := office.get_node("DepartmentStairs/UpperLanding") as MeshInstance3D
	var ramp_bounds: AABB = ramp.global_transform * ramp.get_aabb()
	var landing_top := landing.global_position.y + (landing.mesh as BoxMesh).size.y / 2.0
	if ramp_bounds.end.y > landing_top - 0.02:
		_fail("Visible stair ramp protrudes above the upper landing")
		return
	var tread_nodes := office.get_node("DepartmentStairs/StraightFlight").find_children("Step", "MeshInstance3D", true, false)
	var tread_heights: Array[float] = []
	var landing_bounds: AABB = landing.global_transform * landing.get_aabb()
	var top_tread_bounds := AABB()
	for tread_node in tread_nodes:
		var tread: MeshInstance3D = tread_node
		var bounds: AABB = tread.global_transform * tread.get_aabb()
		tread_heights.append(bounds.end.y)
		if top_tread_bounds.size == Vector3.ZERO or bounds.end.y > top_tread_bounds.end.y:
			top_tread_bounds = bounds
	tread_heights.sort()
	if tread_heights.size() < 2 or top_tread_bounds.position.z > landing_bounds.end.z + 0.005:
		_fail("Landing does not reach the top tread: top=%s landing=%s" % [top_tread_bounds, landing_bounds])
		return
	var rise := tread_heights[1] - tread_heights[0]
	if absf(landing_top - top_tread_bounds.end.y - rise - 0.005) > 0.001:
		_fail("Landing is not one equal rise above the top tread")
		return
	var west_wall := office.get_node("DepartmentStairs/WestWall") as MeshInstance3D
	var east_wall := office.get_node("DepartmentStairs/EastMiddleWall") as MeshInstance3D
	var west_bounds: AABB = west_wall.global_transform * west_wall.get_aabb()
	var east_bounds: AABB = east_wall.global_transform * east_wall.get_aabb()
	if top_tread_bounds.position.x > west_bounds.end.x + 0.001 or top_tread_bounds.end.x < east_bounds.position.x - 0.001:
		_fail("Stair treads do not reach both enclosure walls")
		return
	for i in range(2, tread_heights.size()):
		if absf(tread_heights[i] - tread_heights[i - 1] - rise) > 0.001:
			_fail("Stair tread rises are not equal")
			return
	for spec in [["DeliverySpecialists", 2], ["WebDevelopmentandContentDesign", 2], ["ServiceDelivery", 2]]:
		var module: Node = office.get_node_or_null("CustomersWing/" + spec[0])
		if module == null or _count_staff(module) != spec[1] or (spec[0] != "ServiceDelivery" and module.get_node_or_null("WhiteboardPlaceholder") == null):
			_fail("Incorrect specialist office: " + spec[0])
			return
		for i in range(spec[1]):
			if module.get_node_or_null("Desk%d" % (i + 1)) == null:
				_fail("Missing specialist desk: " + spec[0])
				return
		if module.get_node_or_null("Desk%d" % (spec[1] + 1)) != null:
			_fail("Unexpected vacant specialist desk: " + spec[0])
			return
		if spec[1] == 2 and module.get_node_or_null("WorkstationDivider1") == null:
			_fail("Missing specialist workstation divider: " + spec[0])
			return
	var conference := office.get_node_or_null("CustomersWing/SpecialistConference")
	if conference == null or _count_staff(conference) != 0 or conference.find_children("Glass*", "MeshInstance3D").size() < 2:
		_fail("Specialist conference room must have glass and no staff desks")
		return
	var reception_glass := conference.get_node_or_null("ReceptionGlassNorth") as MeshInstance3D
	if office.get_node_or_null("CustomersWing/TeamMeeting") != null or reception_glass == null or (reception_glass.mesh.material as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_ALPHA or conference.get_node_or_null("ReceptionDoorOpen") != null or conference.get_node_or_null("ReceptionGlassSouth") != null:
		_fail("Conference must extend to reception with a transparent shared wall")
		return
	for child in conference.get_children():
		if child is MeshInstance3D and (child.name.begins_with("ReceptionGlassPost") or child.name in ["ReceptionGlassNorth", "ReceptionGlassSouth", "ReceptionGlassTopRail"]):
			if child.position.y + (child.mesh as BoxMesh).size.y / 2.0 > 2.401:
				_fail("Reception glass and frames must stop below the wall header")
				return
	var exterior_wall := conference.get_node_or_null("WestExteriorWall") as MeshInstance3D
	if exterior_wall == null or (exterior_wall.mesh.material as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or (exterior_wall.mesh as BoxMesh).size != Vector3(0.2, 3, 3.5) or exterior_wall.position != Vector3(-16, 1.5, 1.25):
		_fail("Conference exterior must have an opaque full-height west wall")
		return
	var table := conference.get_node_or_null("Table") as MeshInstance3D
	if conference.find_children("GlassEdgeRail*", "MeshInstance3D").size() != 4 or office.get_node("DepartmentsWing").find_children("ConferenceGlassEdgeRail*", "MeshInstance3D").size() != 4:
		_fail("Both conference rooms must have top and bottom trim on each glass pane")
		return
	for rail in conference.find_children("GlassEdgeRail*", "MeshInstance3D") + office.get_node("DepartmentsWing").find_children("ConferenceGlassEdgeRail*", "MeshInstance3D"):
		if not is_equal_approx((rail.mesh as BoxMesh).size.y, 0.06):
			_fail("Conference glass edge rails must be slim")
			return
	if conference.get_node_or_null("GlassWallEndFrame") == null or office.get_node_or_null("DepartmentsWing/ConferenceGlassWallEndNorth") == null or office.get_node_or_null("DepartmentsWing/ConferenceGlassWallEndSouth") == null:
		_fail("Glass-to-wall junctions must have visible end frames")
		return
	if conference.get_node_or_null("GlassCornerUpperFrame") != null:
		_fail("Reception wall corner must not have an offset upper strip")
		return
	if table == null or (table.mesh as BoxMesh).size.x != 12.0 or table.position.x != -4.0:
		_fail("Conference table must extend toward reception while leaving doorway clearance")
		return
	if office.get_node_or_null("CustomersWing/ProjectManagerBoard") == null or office.get_node_or_null("CustomersWing/ServiceDelivery/WhiteboardPlaceholder") != null:
		_fail("Service delivery data board placement is incorrect")
		return
	var web_office := office.get_node("CustomersWing/WebDevelopmentandContentDesign")
	if not _has_label(web_office, "WEBSITE DEVELOPER") or not _has_label(web_office, "CONTENT AND DESIGN"):
		_fail("Website development and content/design must share an office")
		return
	for node_path in ["CustomersWing/UnassignedOffice", "CustomersWing/WebsiteDeveloper", "CustomersWing/ContentWriter", "CustomersWing/Developers", "DepartmentsWing/UnassignedOffice", "DepartmentsWing/InformationTechnology", "DepartmentsWing/ProductEngineeringandOperations"]:
		if office.get_node_or_null(node_path) != null:
			_fail("Obsolete office remains: " + node_path)
			return
	for node_path in ["ReceptionHub/ReceptionistPlaceholder", "DepartmentsWing/CFO", "DepartmentsWing/Sales", "DepartmentsWing/SalesSupportandMarketing", "DepartmentsWing/ITEngineeringandOperations", "DepartmentsWing/ClientServices", "DepartmentsWing/PeopleHRandLegal", "DepartmentsWing/CEODesk", "DepartmentsWing/ConferenceTable"]:
		if office.get_node_or_null(node_path) == null:
			_fail("Missing department or reception object: " + node_path)
			return
	if _count_staff(office.get_node("DepartmentsWing")) != 19 or _count_staff(office.get_node("ProjectsResearchWing")) != 0 or _count_staff(office.get_node("CustomersWing")) != 6:
		_fail("Knowledge-office staff placeholder count is incorrect")
		return
	for spec in [["CFO", 1], ["SalesSupportandMarketing", 4], ["PeopleHRandLegal", 2], ["ITEngineeringandOperations", 4], ["COO", 1]]:
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
	for spec in [["SalesSupportandMarketing/StaffPlaceholder2", "MARKETING MANAGER"], ["SalesSupportandMarketing/StaffPlaceholder3", "CLIENT SERVICES MANAGER"], ["SalesSupportandMarketing/StaffPlaceholder4", "PRODUCT MANAGER"], ["ITEngineeringandOperations/StaffPlaceholder1", "IT"]]:
		var labels := office.get_node("DepartmentsWing/" + spec[0]).find_children("*", "Label3D", true, false)
		if labels.size() != 1 or (labels[0] as Label3D).text != spec[1]:
			_fail("Incorrect reassigned staff placeholder: " + spec[0])
			return
	var it_room := office.get_node("DepartmentsWing/ITEngineeringandOperations") as Node3D
	var first_staff := it_room.get_node("StaffPlaceholder1") as Node3D
	var last_staff := it_room.get_node("StaffPlaceholder4") as Node3D
	if absf(first_staff.position.x + last_staff.position.x) > 0.001:
		_fail("IT office workstations are not centered")
		return
	if _wall_present(room, Vector3(259, 5.7, -23.5), Vector3(263, 5.7, -23.5)):
		_fail("Former IT office partition still divides the combined room")
		return
	for spec in [["Sales", 4], ["ClientServices", 2]]:
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
	if _wall_present(room, Vector3(261, 1.5, 5), Vector3(265, 1.5, 5)):
		_fail("Former meeting room partition still divides the conference room")
		return
	if _wall_present(room, Vector3(254, 1.5, 3.5), Vector3(256, 1.5, 3.5)) or not _wall_present(room, Vector3(254, 1.5, 4.8), Vector3(256, 1.5, 4.8)):
		_fail("Reception doorway must be open and the adjacent wall solid")
		return
	if not _wall_present(room, Vector3(254, 1.5, 7), Vector3(256, 1.5, 7)):
		_fail("Conference exterior wall must block movement")
		return
	if _wall_present(room, Vector3(277, 1.65, 0), Vector3(277, 1.65, -1.7)):
		_fail("Project manager data board is obscured from the corridor")
		return
	# The 3 m reception opening has clear walking space and walls on both sides.
	for spec in [[2.0, false], [3.0, false], [4.0, false], [0.8, true], [4.9, true]]:
		var start := Vector3(246, 0, spec[0])
		if room.player.test_move(Transform3D(Basis.IDENTITY, start), Vector3(-2, 0, 0)) != spec[1]:
			_fail("Reception stair opening or side wall failed at z=%s" % spec[0])
			return
	for z in [-9.0, -11.0, -14.0, -17.0]:
		if not _wall_present(room, Vector3(244, 2.5, z), Vector3(244, 3.5, z)):
			_fail("Research ceiling remains open at z=%s" % z)
			return
	# Check openings and adjacent solid walls, using the actual player capsule.
	for route in [
		[Vector3(246.85, 4, -20), Vector3(0, 0, -3), false],
		[Vector3(246.85, 4, -23), Vector3(0, 0, 3), false],
		[Vector3(249, 4, -22), Vector3(-1.2, 0, 0), true],
		[Vector3(247.2, 4, -14.5), Vector3(0, 0, -3), false],
		[Vector3(281.2, 4, -14.5), Vector3(0, 0, -3), false],
		[Vector3(254, 0, 0), Vector3(2, 0, 0), false],
		[Vector3(254, 0, 3.5), Vector3(2, 0, 0), false],
		[Vector3(256, 0, 3.5), Vector3(-2, 0, 0), false],
		[Vector3(260, 0, 7), Vector3(14, 0, 0), false],
		[Vector3(254, 0, 4.85), Vector3(2, 0, 0), true],
		[Vector3(250, 0, -4), Vector3(0, 0, -2), false],
		[Vector3(261, 0, -1), Vector3(0, 0, -2), false],
		[Vector3(264, 0, -1), Vector3(0, 0, -2), true],
		[Vector3(250, 0, -7), Vector3(0, 0, -2), false],
		[Vector3(256, 0, 0), Vector3(21, 0, 0), false],
		[Vector3(277, 0, 0), Vector3(-21, 0, 0), false],
		[Vector3(277, 0, 0), Vector3(5, 0, 0), false],
		[Vector3(282, 0, 0), Vector3(-5, 0, 0), false],
		[Vector3(277, 0, 3), Vector3(4, 0, 0), true],
		[Vector3(282, 0, 0), Vector3(4, 0, 0), true],
		[Vector3(261, 0, -3), Vector3(0, 0, 2), false],
		[Vector3(271, 0, 1), Vector3(0, 0, 2), false],
		[Vector3(267, 0, 1), Vector3(0, 0, 2), true],
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
	# Walk the single flight in both directions with the actual player controller.
	room.player.position = Vector3(246.0, 0, 3)
	room.vertical_speed = 0.0
	room.horizontal_velocity = Vector3.ZERO
	for target in [Vector3(243.4, 0, 3), Vector3(243.4, 0, -6.3), Vector3(247, 0, -6.3)]:
		if not await _walk_to(room, target):
			_fail("Could not walk upstairs toward %s; player at %s" % [target, room.player.position])
			return
	if room.player.position.y < 3.8:
		_fail("Staircase did not reach second floor: %s" % room.player.position)
		return
	for side in [-1.0, 1.0]:
		var start := Vector3(243.4, 2.0, -1.65)
		if not room.player.test_move(Transform3D(Basis.IDENTITY, start), Vector3(side * 2.0, 0, 0)):
			_fail("Stair flight wall is open on side %s" % side)
			return
	# Each bullpen desk has a walk-in opening and a tall, solid panel beside it.
	for team_path in ["Sales", "ClientServices"]:
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
	# Private offices retain their open entries and solid outer walls.
	for path in ["CFO", "SalesSupportandMarketing", "PeopleHRandLegal", "ITEngineeringandOperations", "COO"]:
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
		for z in ([-19.0 if x >= 27 else -25.0, 5.0 if x >= 11 and x < 19 else 11.0]):
			if not _wall_present(room, Vector3(250 + x, 5.5, z - 0.6), Vector3(250 + x, 5.5, z + 0.6)):
				_fail("Exterior wall gap at x=%d z=%s" % [x, z])
				return
	for z in range(-18, 5):
		for x in [-5.0, 35.0]:
			# The upstairs stair entry is not an exterior wall.
			if x == -5.0 and z in [-8, -7, -6, -5]:
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
	for target in [Vector3(243.4, 0, -6.3), Vector3(243.4, 0, 3), Vector3(246, 0, 3)]:
		if not await _walk_to(room, target):
			_fail("Could not walk downstairs toward %s; player at %s" % [target, room.player.position])
			return
	if room.player.position.y > 0.3:
		_fail("Staircase did not return to reception: %s" % room.player.position)
		return
	print("PASS: office structure, reception spawn, doorway and partition collision")
	quit(0)
