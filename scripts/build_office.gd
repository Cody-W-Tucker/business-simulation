extends SceneTree
## One-shot builder for the reusable office interior. Run from the preview shell.

var building: Node3D
var materials := {}


func _initialize() -> void:
	_build_wings.call_deferred()


func _material(color: String) -> StandardMaterial3D:
	if not materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(color)
		mat.roughness = 0.9
		if color == "a5c6d1":
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.18
		materials[color] = mat
	return materials[color]


func _box(parent: Node3D, label: String, size: Vector3, pos: Vector3, color: String, solid := false) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	node.mesh = mesh
	node.position = pos
	parent.add_child(node)
	node.owner = building
	if solid:
		var body := StaticBody3D.new()
		body.name = "Collision"
		node.add_child(body)
		body.owner = building
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		collision.owner = building


func _label(parent: Node3D, text: String, pos: Vector3, size := 0.004, angle := 0.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.rotation.y = angle
	label.font_size = 42
	label.pixel_size = size
	label.modulate = Color("344454")
	parent.add_child(label)
	label.owner = building


func _group(title: String) -> Node3D:
	var group := Node3D.new()
	group.name = title
	building.add_child(group)
	group.owner = building
	return group


func _slab(parent: Node3D, name_: String, center: Vector3, size: Vector2) -> void:
	_box(parent, name_ + "Floor", Vector3(size.x, 0.2, size.y), center + Vector3(0, -0.1, 0), "b4b2a9", true)
	_box(parent, name_ + "Ceiling", Vector3(size.x, 0.2, size.y), center + Vector3(0, 3.1, 0), "ebe9df", true)


func _light(parent: Node3D, pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_energy = 0.65
	light.omni_range = 10.0
	parent.add_child(light)
	light.owner = building


func _person_placeholder(parent: Node3D, node_name: String, title: String, pos: Vector3, label_angle: float) -> void:
	# A deliberately abstract, noninteractive stand-in, not a working NPC.
	var person := Node3D.new()
	person.name = node_name
	person.position = pos
	parent.add_child(person)
	person.owner = building
	_box(person, "Base", Vector3(0.8, 0.12, 0.8), Vector3(0, 0.06, 0), "737e87")
	for x in [-0.16, 0.16]:
		_box(person, "Leg", Vector3(0.17, 0.3, 0.22), Vector3(x, 0.26, 0), "737e87")
	_box(person, "Body", Vector3(0.55, 1.0, 0.35), Vector3(0, 0.9, 0), "96a3a4")
	_box(person, "Head", Vector3(0.4, 0.4, 0.4), Vector3(0, 1.6, 0), "c5b29c")
	var label_pos := Vector3(0, 2.2, 0)
	label_pos += Vector3(sin(label_angle), 0, cos(label_angle)) * 0.25
	_label(person, title + "\nPLACEHOLDER", label_pos, 0.0025, label_angle)


func _department(parent: Node3D, title: String, center: Vector3, angle: float, roles: Array, width: float = 8.0) -> void:
	# Small rooms sized for the one or two people actually assigned here.
	var department := Node3D.new()
	department.name = title.replace(" ", "")
	department.position = center
	department.rotation.y = angle
	parent.add_child(department)
	department.owner = building
	_slab(department, "Department", Vector3.ZERO, Vector2(width, 6))
	_box(department, "FarWall", Vector3(width, 3, 0.2), Vector3(0, 1.5, -3), "ddd9ce", true)
	for x in [-width / 2.0, width / 2.0]:
		_box(department, "SideWall", Vector3(0.2, 3, 6), Vector3(x, 1.5, 0), "ddd9ce", true)
	var pier_width := (width - 3.0) / 2.0
	for x in [-(3.0 + pier_width) / 2.0, (3.0 + pier_width) / 2.0]:
		_box(department, "EntryWall", Vector3(pier_width, 3, 0.2), Vector3(x, 1.5, 3), "ddd9ce", true)
	_box(department, "EntryLintel", Vector3(3, 0.6, 0.2), Vector3(0, 2.7, 3), "ddd9ce", true)
	_label(department, title.to_upper(), Vector3(0, 2.68, 3.13), 0.003, 0.0)
	var board_x := -(width / 2.0 + 1.5) / 2.0
	_box(department, "WhiteboardFrame", Vector3(1.8, 1.0, 0.08), Vector3(board_x, 1.65, 3.16), "303b48")
	_box(department, "WhiteboardPlaceholder", Vector3(1.65, 0.85, 0.03), Vector3(board_x, 1.65, 3.22), "e5e9e9")
	_label(department, "DATA PLACEHOLDER", Vector3(board_x, 1.65, 3.25), 0.0022)
	if roles.size() > 1:
		for pair in range(roles.size() / 2):
			var pair_x := (pair - (roles.size() / 2.0 - 1.0) / 2.0) * 8.0
			_box(department, "WorkstationDivider%d" % (pair + 1), Vector3(0.12, 1.55, 2.3), Vector3(pair_x, 0.775, -1.6), "96a3a4", true)
		if roles.size() > 2:
			_box(department, "PairBackDivider", Vector3(0.12, 1.55, 2.3), Vector3(0, 0.775, -1.6), "96a3a4", true)
	for i in range(roles.size()):
		var pair_x := (floori(i / 2.0) - (roles.size() / 2.0 - 1.0) / 2.0) * 8.0 if roles.size() > 1 else 0.0
		var side := -1.0 if i % 2 == 0 else 1.0
		var desk_x := pair_x + side * 0.65 if roles.size() > 1 else -1.2
		var person_x := pair_x + side * 2.1 if roles.size() > 1 else -2.7
		_box(department, "Desk%d" % (i + 1), Vector3(1.1, 0.12, 1.8), Vector3(desk_x, 0.75, -1.65), "c5b29c", true)
		_box(department, "DeskReturn%d" % (i + 1), Vector3(1.5, 0.12, 0.55), Vector3((desk_x + person_x) / 2.0, 0.75, -2.55), "c5b29c")
		_box(department, "DeskLeg%d" % (i + 1), Vector3(0.1, 0.7, 0.1), Vector3(desk_x, 0.35, -1.3), "737e87")
		_box(department, "Monitor%d" % (i + 1), Vector3(0.08, 0.5, 0.7), Vector3(desk_x - side * 0.4, 1.15, -1.65), "303b48")
		_box(department, "Files%d" % (i + 1), Vector3(0.45, 0.3, 0.35), Vector3(person_x, 0.98, -2.55), "737e87")
		_person_placeholder(department, "StaffPlaceholder%d" % (i + 1), roles[i], Vector3(person_x, 0, -1.4), -side * PI / 2.0)
	_light(department, Vector3(0, 2.75, 0))


func _stair_flight(parent: Node3D, flight_name: String, start: Vector3, end: Vector3) -> void:
	# The smooth collision surface follows the visible treads. This lets the
	# existing capsule controller walk without a separate step-climbing system.
	var direction := end - start
	var horizontal := Vector2(direction.x, direction.z).length()
	var heading := Node3D.new()
	heading.name = flight_name
	heading.position = (start + end) / 2.0
	heading.rotation.y = atan2(-direction.z, direction.x)
	parent.add_child(heading)
	heading.owner = building
	var flight := Node3D.new()
	flight.rotation.z = atan2(direction.y, horizontal)
	heading.add_child(flight)
	flight.owner = building
	var length := direction.length()
	_box(flight, "WalkingSurface", Vector3(length + 0.1, 0.12, 1.8), Vector3(0, -0.06, 0), "a38a72", true)
	# Inner guards prevent a fall into the open center while leaving both
	# quarter-turn landings open to the next flight.
	_box(flight, "InnerGuard", Vector3(length - 0.15, 0.9, 0.1), Vector3(0, 0.51, 0.97), "96a3a4", true)
	var steps := ceili(length / 0.5)
	for i in range(steps):
		var tread := Node3D.new()
		tread.name = "Tread"
		tread.position = Vector3(-length / 2 + (i + 0.5) * length / steps, 0.015, 0)
		tread.rotation.z = -flight.rotation.z
		flight.add_child(tread)
		tread.owner = building
		_box(tread, "Step", Vector3(length / steps, 0.12, 1.8), Vector3(0, 0, 0), "c5b29c")


func _build_wings() -> void:
	building = Node3D.new()
	building.name = "OfficeInterior"
	var hub := _group("ReceptionHub")
	var customers := _group("CustomersWing")
	var research := _group("ProjectsResearchWing")
	var departments := _group("DepartmentsWing")
	# All rooms share the existing 1 m = 1 unit scale and 3 m ceiling.
	_slab(hub, "Hub", Vector3.ZERO, Vector2(10, 10))
	# Doors: south exit, north research, east customers, west departments.
	_box(hub, "ExitWall", Vector3(4, 3, 0.2), Vector3(3, 1.5, 5), "ddd9ce", true)
	for x in [-4.5, -1.5]:
		_box(hub, "WindowSide", Vector3(1, 3, 0.2), Vector3(x, 1.5, 5), "ddd9ce", true)
	_box(hub, "WindowSillWall", Vector3(2, 1, 0.2), Vector3(-3, 0.5, 5), "ddd9ce", true)
	_box(hub, "WindowHeadWall", Vector3(2, 0.6, 0.2), Vector3(-3, 2.7, 5), "ddd9ce", true)
	_box(hub, "WindowPane", Vector3(2, 1.4, 0.04), Vector3(-3, 1.7, 5), "a5c6d1", true)
	_box(hub, "WindowSill", Vector3(2.12, 0.1, 0.3), Vector3(-3, 1.02, 5), "eae5d9")
	_box(hub, "WindowHeader", Vector3(2.12, 0.1, 0.3), Vector3(-3, 2.38, 5), "eae5d9")
	_box(hub, "ExitLintel", Vector3(2, 0.6, 0.2), Vector3(0, 2.7, 5), "ddd9ce", true)
	_box(hub, "ReturnDoor", Vector3(1.85, 2.35, 0.08), Vector3(0, 1.175, 4.95), "697888")
	_label(hub, "COURTYARD\n[E]", Vector3(0, 1.6, 4.89), 0.004, PI)
	for x in [-3.25, 3.25]:
		_box(hub, "NorthWall", Vector3(3.5, 3, 0.2), Vector3(x, 1.5, -5), "ddd9ce", true)
	_box(hub, "NorthLintel", Vector3(3, 0.6, 0.2), Vector3(0, 2.7, -5), "ddd9ce", true)
	for x in [-5.0, 5.0]:
		for z in [-3.5, 3.5]:
			_box(hub, "SideWall", Vector3(0.2, 3, 3), Vector3(x, 1.5, z), "ddd9ce", true)
		_box(hub, "SideLintel", Vector3(0.2, 0.6, 4), Vector3(x, 2.7, 0), "ddd9ce", true)
	_box(hub, "ReceptionDesk", Vector3(2.2, 1, 0.8), Vector3(-2.6, 0.5, -2.8), "a38a72", true)
	_box(hub, "ReceptionTop", Vector3(2.35, 0.1, 0.9), Vector3(-2.6, 1.05, -2.8), "e5e0d4")
	_label(hub, "RECEPTION", Vector3(-2.6, 0.65, -2.34), 0.004)
	_person_placeholder(hub, "ReceptionistPlaceholder", "RECEPTIONIST", Vector3(-2.6, 0, -3.8), 0.0)
	_label(hub, "PROJECTS / RESEARCH", Vector3(0, 2.65, -4.88), 0.003)
	_label(hub, "SPECIALISTS", Vector3(4.88, 2.65, 0), 0.004, -PI / 2)
	_label(hub, "DEPARTMENTS", Vector3(-4.88, 2.65, 0), 0.004, PI / 2)
	_light(hub, Vector3(0, 2.75, 0))
	# Four rooms on each side of a long corridor. First north room is the customer.
	_slab(customers, "Customers", Vector3(17, 0, 0), Vector2(24, 16))
	for z in [-8.0, 8.0]:
		_box(customers, "OuterWall", Vector3(24, 3, 0.2), Vector3(17, 1.5, z), "ddd9ce", true)
	# The corridor terminates in the project manager's office, with a clear doorway.
	for z in [-4.75, 4.75]:
		_box(customers, "CorridorEnd", Vector3(0.2, 3, 6.5), Vector3(29, 1.5, z), "ddd9ce", true)
	_box(customers, "ManagerEntranceLintel", Vector3(0.2, 0.6, 3), Vector3(29, 2.7, 0), "ddd9ce", true)
	_label(customers, "PROJECT MANAGER", Vector3(28.87, 2.68, 0), 0.003, -PI / 2)
	for side in [-1.0, 1.0]:
		for x in [5.0, 11.0, 17.0, 23.0, 29.0]:
			_box(customers, "RoomDivider", Vector3(0.2, 3, 6), Vector3(x, 1.5, side * 5), "ddd9ce", true)
		for i in range(4):
			var x := 8.0 + i * 6.0
			for dx in [-2.025, 2.025]:
				_box(customers, "CorridorWall", Vector3(1.95, 3, 0.2), Vector3(x + dx, 1.5, side * 2), "ddd9ce", true)
			_box(customers, "RoomLintel", Vector3(2.1, 0.6, 0.2), Vector3(x, 2.7, side * 2), "ddd9ce", true)
			var titles := ["ACCOUNT MANAGER", "WEBSITE DEVELOPER", "CONTENT WRITER", "CONSULTANT"] if side < 0 else ["DEVELOPER", "DEVELOPER", "DELIVERY LEAD", "KNOWLEDGE SPECIALIST"]
			var title: String = titles[i]
			_label(customers, title, Vector3(x, 2.68, side * 1.87), 0.0028, 0.0 if side < 0 else PI)
			if not (side < 0 and i == 0):
				_box(customers, "SpecialistDesk", Vector3(2, 0.12, 0.7), Vector3(x, 0.75, side * 6.8), "c5b29c", true)
				_box(customers, "SpecialistBoard", Vector3(2, 1, 0.08), Vector3(x, 1.8, side * 7.8), "e5e9e9")
				_person_placeholder(customers, "StaffPlaceholder%s%d" % ["North" if side < 0 else "South", i], title, Vector3(x, 0, side * 5.3), 0.0 if side < 0 else PI)
			_light(customers, Vector3(x, 2.75, side * 4.5))
	for x in [9.0, 21.0]:
		_light(customers, Vector3(x, 2.75, 0))
	# Brokerage: three wall boards, desk and files on the right, account manager on the left.
	_box(customers, "CustomerDesk", Vector3(0.9, 0.12, 2.6), Vector3(10.15, 0.75, -5.1), "c5b29c", true)
	for z in [-6.2, -4.0]:
		_box(customers, "CustomerDeskLeg", Vector3(0.12, 0.7, 0.12), Vector3(10.15, 0.35, z), "737e87")
	_box(customers, "CustomerFiles", Vector3(0.65, 1.15, 0.75), Vector3(10.45, 0.575, -7.2), "96a3a4", true)
	_label(customers, "FILES", Vector3(10.45, 1.05, -6.81), 0.0025)
	_person_placeholder(customers, "AccountManagerPlaceholder", "ACCOUNT MANAGER", Vector3(6.6, 0, -5.25), 0.0)
	for i in range(3):
		var x := 6.6 + i * 1.4
		_box(customers, "Monitor%d" % (i + 1), Vector3(1.2, 0.85, 0.09), Vector3(x, 1.65, -7.82), "303b48")
		_box(customers, "Screen%d" % (i + 1), Vector3(1.1, 0.75, 0.02), Vector3(x, 1.65, -7.76), "e5e9e9")
		_label(customers, "WHITEBOARD %d" % (i + 1), Vector3(x, 1.65, -7.74), 0.0025)
	# A distinct room beyond the corridor. Its three browser placeholders sit behind the desk.
	_slab(customers, "ManagerOffice", Vector3(33, 0, 0), Vector2(8, 8))
	for z in [-4.0, 4.0]:
		_box(customers, "ManagerSideWall", Vector3(8, 3, 0.2), Vector3(33, 1.5, z), "ddd9ce", true)
	_box(customers, "ManagerBackWall", Vector3(0.2, 3, 8), Vector3(37, 1.5, 0), "ddd9ce", true)
	_box(customers, "ManagerDesk", Vector3(0.9, 0.12, 3.5), Vector3(34.15, 0.75, 0), "c5b29c", true)
	for z in [-1.55, 1.55]:
		_box(customers, "ManagerDeskLeg", Vector3(0.12, 0.7, 0.12), Vector3(34.15, 0.35, z), "737e87")
	_person_placeholder(customers, "ProjectManagerPlaceholder", "PROJECT MANAGER", Vector3(35.25, 0, 2.45), -PI / 2)
	for i in range(3):
		var z := -1.4 + i * 1.4
		_box(customers, "ManagerBrowser%d" % (i + 1), Vector3(0.09, 0.85, 1.2), Vector3(36.82, 1.65, z), "303b48")
		_box(customers, "ManagerBrowserScreen%d" % (i + 1), Vector3(0.02, 0.75, 1.1), Vector3(36.76, 1.65, z), "e5e9e9")
		_label(customers, "BROWSER %d" % (i + 1), Vector3(36.74, 1.65, z), 0.0025, -PI / 2)
	_light(customers, Vector3(33, 2.75, 0))
	# Octagonal research hub: eight equal sides, with a three-metre entry in the south side.
	_slab(research, "ResearchLink", Vector3(0, 0, -6.5), Vector2(3, 3))
	for x in [-1.5, 1.5]:
		_box(research, "LinkWall", Vector3(0.2, 3, 3), Vector3(x, 1.5, -6.5), "ddd9ce", true)
	_slab(research, "Research", Vector3(0, 0, -15.25), Vector2(13.9, 14.5))
	for i in range(8):
		var a := PI / 8.0 + TAU * i / 8.0
		var b := PI / 8.0 + TAU * (i + 1) / 8.0
		var p := Vector3(7.5 * cos(a), 0, -15 + 7.5 * sin(a))
		var q := Vector3(7.5 * cos(b), 0, -15 + 7.5 * sin(b))
		var segment := Node3D.new()
		segment.name = "OctagonWall%d" % i
		segment.position = (p + q) / 2.0
		segment.rotation.y = atan2(-(q.z - p.z), q.x - p.x)
		research.add_child(segment)
		segment.owner = building
		var length := p.distance_to(q)
		if i in [1, 3, 7]:
			var edge := (length - 3.0) / 2.0
			for sign_ in [-1.0, 1.0]:
				_box(segment, "EntryPier", Vector3(edge, 3, 0.2), Vector3(sign_ * (3.0 + edge) / 2.0, 1.5, 0), "ddd9ce", true)
			_box(segment, "EntryLintel", Vector3(3, 0.6, 0.2), Vector3(0, 2.7, 0), "ddd9ce", true)
		else:
			_box(segment, "Wall", Vector3(length + 0.02, 3, 0.2), Vector3(0, 1.5, 0), "ddd9ce", true)
			var inward := signf(segment.basis.z.dot(Vector3(0, 0, -15) - segment.position))
			_box(segment, "ResearchScreen", Vector3(3.2, 1.5, 0.08), Vector3(0, 1.65, inward * 0.16), "303b48")
			_box(segment, "ResearchPlaceholder", Vector3(3.0, 1.3, 0.03), Vector3(0, 1.65, inward * 0.22), "e5e9e9")
			_label(segment, "RESEARCH PLACEHOLDER", Vector3(0, 1.65, inward * 0.25), 0.003, 0.0 if inward > 0 else PI)
	_light(research, Vector3(0, 2.7, -15))
	# Two open spokes leave space for future research rooms beyond the central hub.
	for side in [-1.0, 1.0]:
		_slab(research, "ResearchSpoke", Vector3(side * 9.95, 0, -15), Vector2(6, 5))
		for z in [-17.5, -12.5]:
			_box(research, "SpokeSide", Vector3(6, 3, 0.2), Vector3(side * 9.95, 1.5, z), "ddd9ce", true)
		_box(research, "SpokeEnd", Vector3(0.2, 3, 5), Vector3(side * 12.95, 1.5, -15), "ddd9ce", true)
		_box(research, "SpokeScreenFrame", Vector3(0.08, 1.5, 3.2), Vector3(side * 12.79, 1.65, -15), "303b48")
		_box(research, "SpokeScreen", Vector3(0.03, 1.3, 3), Vector3(side * 12.73, 1.65, -15), "e5e9e9")
		_label(research, "RESEARCH PLACEHOLDER", Vector3(side * 12.70, 1.65, -15), 0.003, -side * PI / 2.0)
		_light(research, Vector3(side * 10, 2.7, -15))
	# Three flights and two quarter-turn landings connect reception to floor 2.
	var stairs := _group("DepartmentStairs")
	_box(stairs, "StairFloor", Vector3(10, 0.2, 10), Vector3(-10, -0.1, -3), "b4b2a9", true)
	_stair_flight(stairs, "FirstFlight", Vector3(-5, 0, 1), Vector3(-13, 4.0 / 3, 1))
	_stair_flight(stairs, "SecondFlight", Vector3(-14, 4.0 / 3, 0), Vector3(-14, 8.0 / 3, -6))
	_stair_flight(stairs, "ThirdFlight", Vector3(-13, 8.0 / 3, -7), Vector3(-6, 4, -7))
	_box(stairs, "FirstLanding", Vector3(2.1, 0.2, 2.1), Vector3(-14, 4.0 / 3 - 0.1, 1), "c5b29c", true)
	_box(stairs, "SecondLanding", Vector3(2.1, 0.2, 2.1), Vector3(-14, 8.0 / 3 - 0.1, -7), "c5b29c", true)
	_box(stairs, "FinalLanding", Vector3(1.2, 0.2, 2), Vector3(-5.6, 3.9, -7), "c5b29c", true)
	_box(stairs, "WestWall", Vector3(0.2, 7, 10.2), Vector3(-15, 3.5, -3), "ddd9ce", true)
	for z in [-8.0, 2.0]:
		_box(stairs, "StairWall", Vector3(10, 7, 0.2), Vector3(-10, 3.5, z), "ddd9ce", true)
	_box(stairs, "EastWall", Vector3(0.2, 7, 6), Vector3(-5, 3.5, -3), "ddd9ce", true)
	_box(stairs, "EastLowerWall", Vector3(0.2, 3.8, 2), Vector3(-5, 1.9, -7), "ddd9ce", true)
	_box(stairs, "FloorEdge", Vector3(0.2, 0.6, 2), Vector3(-5, 3.5, 1), "ddd9ce", true)
	_box(stairs, "StairCeiling", Vector3(10, 0.2, 10), Vector3(-10, 7.1, -3), "ebe9df", true)
	_light(stairs, Vector3(-12, 5.5, -3))
	# Three offices north, four south, and a shorter shared bullpen.
	departments.position.y = 4.0
	_slab(departments, "DepartmentsCommon", Vector3(15, 0, -7), Vector2(40, 24))
	_department(departments, "Sales and Support Managers", Vector3(-1, 0, -22), 0.0, ["SALES MANAGER", "CUSTOMER SUPPORT MANAGER"])
	_department(departments, "Information Technology", Vector3(7, 0, -22), 0.0, ["IT"])
	_department(departments, "People HR and Legal", Vector3(15, 0, -22), 0.0, ["PEOPLE AND HR", "LEGAL AND COMPLIANCE"])
	_department(departments, "Product Engineering and Operations", Vector3(27, 0, -22), 0.0, ["PRODUCT", "ENGINEER", "ENGINEER", "OPERATIONS"], 16.0)
	_department(departments, "Marketing", Vector3(-1, 0, 8), PI, ["MARKETING MANAGER", "MARKETING ASSISTANT"])
	_department(departments, "CFO", Vector3(23, 0, 8), PI, ["CFO"])
	_department(departments, "COO", Vector3(31, 0, 8), PI, ["COO"])
	_box(departments, "CommonSouthWall", Vector3(16, 3, 0.2), Vector3(11, 1.5, 5), "ddd9ce", true)
	for z in [-13.5, -0.5]:
		_box(departments, "CommonWestWall", Vector3(0.2, 3, 11), Vector3(-5, 1.5, z), "ddd9ce", true)
	_box(departments, "StairEntryLintel", Vector3(0.2, 0.6, 2), Vector3(-5, 2.7, -7), "ddd9ce", true)
	var teams := ["Sales", "Customer Support"]
	var team_staff := [4, 2]
	for i in range(2):
		var team := Node3D.new()
		team.name = teams[i].replace(" ", "")
		team.position = Vector3(3 + i * 10, 0, -4)
		departments.add_child(team)
		team.owner = building
		_label(team, teams[i].to_upper(), Vector3(0, 2.3, 0), 0.003)
		var filled := 0
		for x in [-1.6, 1.6]:
			for side in [-1.0, 1.0]:
				if filled >= team_staff[i]:
					continue
				var cubicle := Node3D.new()
				cubicle.name = "Cubicle%d" % (filled + 1)
				cubicle.position = Vector3(x, 0, side * 1.6)
				team.add_child(cubicle)
				cubicle.owner = building
				# 1.8 m panels enclose each desk on all sides, with a single
				# 1.2 m walk-in opening facing the outer aisle.
				for wall_x in [-1.6, 1.6]:
					_box(cubicle, "SidePartition", Vector3(0.1, 1.8, 3.2), Vector3(wall_x, 0.9, 0), "96a3a4", true)
				_box(cubicle, "BackPartition", Vector3(3.2, 1.8, 0.1), Vector3(0, 0.9, -side * 1.6), "96a3a4", true)
				for wall_x in [-1.1, 1.1]:
					_box(cubicle, "EntryPartition", Vector3(1, 1.8, 0.1), Vector3(wall_x, 0.9, side * 1.6), "96a3a4", true)
				_box(cubicle, "Desk", Vector3(1.8, 0.12, 0.75), Vector3(0, 0.75, -side * 0.95), "c5b29c", true)
				for leg_x in [-0.7, 0.7]:
					_box(cubicle, "DeskLeg", Vector3(0.1, 0.7, 0.1), Vector3(leg_x, 0.35, -side * 0.95), "737e87")
				_box(cubicle, "Monitor", Vector3(0.7, 0.45, 0.08), Vector3(0, 1.15, -side * 1.15), "303b48")
				if filled < team_staff[i]:
					_person_placeholder(cubicle, "StaffPlaceholder", teams[i].to_upper(), Vector3.ZERO, 0.0 if side > 0 else PI)
					filled += 1
	for x in [3.0, 19.0, 31.0]:
		_light(departments, Vector3(x, 2.75, -7))
	# Split the former conference footprint between the CEO and conference room.
	_slab(departments, "Conference", Vector3(39, 0, -7), Vector2(8, 24))
	for z in [-19.0, 5.0]:
		_box(departments, "ConferenceSide", Vector3(8, 3, 0.2), Vector3(39, 1.5, z), "ddd9ce", true)
	_box(departments, "ConferenceEnd", Vector3(0.2, 3, 24), Vector3(43, 1.5, -7), "ddd9ce", true)
	for x in [36.5, 41.5]:
		_box(departments, "CEODivider", Vector3(3, 3, 0.2), Vector3(x, 1.5, -7), "ddd9ce", true)
	_box(departments, "CEODividerLintel", Vector3(2, 0.6, 0.2), Vector3(39, 2.7, -7), "ddd9ce", true)
	for segment in [[-17.5, 3.0], [-10.5, 7.0]]:
		_box(departments, "CEOWall", Vector3(0.2, 3, segment[1]), Vector3(35, 1.5, segment[0]), "ddd9ce", true)
	for segment in [[-4.0, 6.0], [3.0, 4.0]]:
		_box(departments, "ConferenceGlass", Vector3(0.08, 3, segment[1]), Vector3(35, 1.5, segment[0]), "a5c6d1", true)
	for z in [-19.0, -16.0, -14.0, -7.0, -1.0, 1.0, 5.0]:
		_box(departments, "ConferenceFrame", Vector3(0.16, 3, 0.12), Vector3(35, 1.5, z), "737e87")
	_box(departments, "ConferenceLintel", Vector3(0.2, 0.6, 2), Vector3(35, 2.7, -15), "ddd9ce", true)
	_box(departments, "ConferenceDoorOpen", Vector3(1.7, 2.3, 0.08), Vector3(35.95, 1.15, -13.95), "a5c6d1")
	_label(departments, "CEO", Vector3(34.87, 2.68, -15), 0.003, -PI / 2)
	_box(departments, "ConferenceEntryLintel", Vector3(0.2, 0.6, 2), Vector3(35, 2.7, 0), "ddd9ce", true)
	_label(departments, "CONFERENCE", Vector3(34.87, 2.68, 0), 0.003, -PI / 2)
	_box(departments, "CEODesk", Vector3(1, 0.12, 2), Vector3(39.3, 0.75, -13), "c5b29c", true)
	for dx in [-0.35, 0.35]:
		for dz in [-0.8, 0.8]:
			_box(departments, "CEODeskLeg", Vector3(0.1, 0.7, 0.1), Vector3(39.3 + dx, 0.35, -13 + dz), "737e87")
	_box(departments, "CEODeskReturn", Vector3(2, 0.12, 0.6), Vector3(40.5, 0.75, -14), "c5b29c")
	_box(departments, "CEOMonitor", Vector3(0.08, 0.5, 0.8), Vector3(39, 1.15, -13), "303b48")
	_box(departments, "CEOFiles", Vector3(0.5, 0.35, 0.4), Vector3(41.1, 0.98, -14), "737e87")
	_person_placeholder(departments, "StaffPlaceholderCEO", "CEO", Vector3(41.5, 0, -13), PI / 2.0)
	_box(departments, "CEOBoard", Vector3(0.08, 1.4, 3), Vector3(42.85, 1.8, -13), "e5e9e9")
	_box(departments, "ConferenceTable", Vector3(3.4, 0.12, 2), Vector3(39, 0.75, -1), "c5b29c", true)
	for x in [37.6, 40.4]:
		for z in [-1.8, -0.2]:
			_box(departments, "ConferenceTableLeg", Vector3(0.12, 0.7, 0.12), Vector3(x, 0.35, z), "737e87")
	for x in [37.8, 39.0, 40.2]:
		for z in [-2.7, 0.7]:
			_box(departments, "ConferenceChair", Vector3(0.55, 0.48, 0.55), Vector3(x, 0.24, z), "96a3a4")
	_light(departments, Vector3(39, 2.75, -7))
	_light(departments, Vector3(39, 2.75, -14))
	var packed := PackedScene.new()
	if packed.pack(building) != OK or ResourceSaver.save(packed, "res://scenes/office_interior.tscn") != OK:
		push_error("Office scene save failed")
		quit(1)
		return
	print("OFFICE_BUILD_COMPLETE")
	building.free()
	quit(0)


func _build() -> void:
	building = Node3D.new()
	building.name = "OfficeInterior"
	# Entry: x -4..4; customer room: x 4..12. Floor level is y=0.
	_box(building, "Floor", Vector3(16, 0.2, 8), Vector3(4, -0.1, 0), "b4b2a9", true)
	_box(building, "Ceiling", Vector3(16, 0.2, 8), Vector3(4, 3.1, 0), "ebe9df", true)
	# Two windows expose the existing panorama; their sills and lintels retain collision.
	for wall in [[-3.5, 1.0], [6.0, 12.0]]:
		_box(building, "NorthWall", Vector3(wall[1], 3, 0.2), Vector3(wall[0], 1.5, -4), "ddd9ce", true)
	for window in [[-1.5, 3.0]]:
		var center: float = window[0]
		var width: float = window[1]
		_box(building, "WindowSillWall", Vector3(width, 1.0, 0.2), Vector3(center, 0.5, -4), "ddd9ce", true)
		_box(building, "WindowHeadWall", Vector3(width, 0.6, 0.2), Vector3(center, 2.7, -4), "ddd9ce", true)
		_box(building, "WindowPane", Vector3(width, 1.4, 0.04), Vector3(center, 1.7, -4), "a5c6d1", true)
		_box(building, "WindowSill", Vector3(width + 0.12, 0.1, 0.3), Vector3(center, 1.02, -4), "eae5d9")
		_box(building, "WindowHeader", Vector3(width + 0.12, 0.1, 0.3), Vector3(center, 2.38, -4), "eae5d9")
	_box(building, "SouthWallLeft", Vector3(3.1, 3, 0.2), Vector3(-2.45, 1.5, 4), "ddd9ce", true)
	_box(building, "SouthWallRight", Vector3(5.1, 3, 0.2), Vector3(3.45, 1.5, 4), "ddd9ce", true)
	_box(building, "SouthWallEnd", Vector3(1.5, 3, 0.2), Vector3(11.25, 1.5, 4), "ddd9ce", true)
	_box(building, "CustomerWindowSillWall", Vector3(4.5, 1, 0.2), Vector3(8.25, 0.5, 4), "ddd9ce", true)
	_box(building, "CustomerWindowHeadWall", Vector3(4.5, 0.6, 0.2), Vector3(8.25, 2.7, 4), "ddd9ce", true)
	_box(building, "CustomerWindowPane", Vector3(4.5, 1.4, 0.04), Vector3(8.25, 1.7, 4), "a5c6d1", true)
	_box(building, "CustomerWindowSill", Vector3(4.62, 0.1, 0.3), Vector3(8.25, 1.02, 4), "eae5d9")
	_box(building, "CustomerWindowHeader", Vector3(4.62, 0.1, 0.3), Vector3(8.25, 2.38, 4), "eae5d9")
	_box(building, "ExitLintel", Vector3(1.8, 0.6, 0.2), Vector3(0, 2.7, 4), "ddd9ce", true)
	_box(building, "WestWall", Vector3(0.2, 3, 8), Vector3(-4, 1.5, 0), "ddd9ce", true)
	_box(building, "EastWall", Vector3(0.2, 3, 8), Vector3(12, 1.5, 0), "ddd9ce", true)
	# Customer door at x=4, z=-1.2; keep the opening clear for the player.
	_box(building, "PartitionFront", Vector3(0.2, 3, 3.7), Vector3(4, 1.5, -2.15), "ddd9ce", true)
	_box(building, "PartitionRear", Vector3(0.2, 3, 2.5), Vector3(4, 1.5, 2.75), "ddd9ce", true)
	_box(building, "PartitionLintel", Vector3(0.2, 0.6, 1.8), Vector3(4, 2.7, 0.6), "ddd9ce", true)
	for z in [-0.32, 1.52]:
		_box(building, "DoorTrim", Vector3(0.28, 2.4, 0.1), Vector3(4, 1.2, z), "5a6570")
	_box(building, "DoorHeader", Vector3(0.28, 0.12, 1.95), Vector3(4, 2.42, 0.6), "5a6570")
	_label(building, "BROKERAGE SPECIALISTS", Vector3(3.86, 2.68, 0.6), 0.003, -PI / 2)
	# The customer door is held open for the first version, leaving the route clear.
	_box(building, "CustomerDoorOpen", Vector3(1.6, 2.3, 0.08), Vector3(4.85, 1.15, 1.58), "7d8992")
	_label(building, "BROKERAGE\nSPECIALISTS", Vector3(4.85, 1.6, 1.63), 0.0028)
	# Door surface teleports back to courtyard; interaction is provided by main.gd.
	_box(building, "ReturnDoor", Vector3(1.7, 2.35, 0.08), Vector3(0, 1.175, 3.96), "697888")
	_label(building, "COURTYARD\n[E]", Vector3(0, 1.6, 3.9), 0.004, PI)
	_box(building, "ReceptionDesk", Vector3(2.3, 1.0, 0.8), Vector3(-1.7, 0.5, -1.4), "a38a72", true)
	_box(building, "ReceptionTop", Vector3(2.45, 0.1, 0.9), Vector3(-1.7, 1.05, -1.4), "e5e0d4")
	_label(building, "RECEPTION", Vector3(-1.7, 0.65, -0.94), 0.004)
	_box(building, "Worktop", Vector3(5.2, 0.12, 0.9), Vector3(8, 0.75, -3.35), "c5b29c", true)
	for x in [5.6, 10.4]:
		_box(building, "DeskLeg", Vector3(0.12, 0.7, 0.75), Vector3(x, 0.35, -3.35), "737e87")
	for i in range(3):
		var x := 6.5 + i * 1.5
		_box(building, "Monitor%d" % (i + 1), Vector3(1.18, 0.7, 0.09), Vector3(x, 1.38, -3.78), "303b48")
		_box(building, "Screen%d" % (i + 1), Vector3(1.08, 0.6, 0.02), Vector3(x, 1.38, -3.72), "e5e9e9")
		_label(building, "PLACEHOLDER %d" % (i + 1), Vector3(x, 1.38, -3.70), 0.0025)
		_box(building, "MonitorStand", Vector3(0.08, 0.28, 0.08), Vector3(x, 0.92, -3.68), "303b48")
	_box(building, "Bench", Vector3(1.8, 0.5, 0.65), Vector3(9.6, 0.25, 2.5), "96a3a4", true)
	for x in [-1.5, 8.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 2.75, 0)
		light.light_energy = 0.7
		light.omni_range = 9.0
		building.add_child(light)
		light.owner = building
	var packed := PackedScene.new()
	if packed.pack(building) != OK or ResourceSaver.save(packed, "res://scenes/office_interior.tscn") != OK:
		push_error("Office scene save failed")
		quit(1)
		return
	print("OFFICE_BUILD_COMPLETE")
	building.free()
	quit(0)
