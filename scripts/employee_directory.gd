extends Node
## Runtime lookup; the character transform is authoritative for live position.

var roster: Resource
var desks: Dictionary = {}
var assigned_desks: Dictionary = {}
var characters: Dictionary = {}
var errors: Array[String] = []


func initialize(office: Node3D, definitions: Resource) -> bool:
	if not characters.is_empty():
		push_error("EmployeeDirectory cannot be initialized twice")
		return false
	if not validate(office, definitions):
		for error in errors:
			push_error(error)
		return false
	var sorted: Array = roster.employees.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	var next_desk := {}
	for employee in sorted:
		var room: String = employee.room
		var index: int = next_desk.get(room, 0)
		next_desk[room] = index + 1
		if not desks.has(room) or index >= desks[room].size():
			push_warning("No available desk in room '%s' for employee %d" % [room, employee.id])
			continue
		var marker: Marker3D = desks[room][index]
		var character := _make_placeholder(employee)
		marker.add_child(character)
		characters[employee.id] = character
		assigned_desks[employee.id] = marker
	return true


func validate(office: Node3D, definitions: Resource) -> bool:
	roster = definitions
	desks.clear()
	errors.clear()
	_index_desks(office)
	for room in desks:
		desks[room].sort_custom(func(a: Marker3D, b: Marker3D) -> bool: return a.get_meta("desk_number") < b.get_meta("desk_number"))
	var by_id := {}
	for employee in roster.employees:
		var id = employee.get("id")
		if not id is int or id <= 0 or by_id.has(id):
			errors.append("Invalid or duplicate employee ID: " + str(id))
		else:
			by_id[id] = employee
		for field in ["display_name", "description", "department", "room"]:
			if not employee.get(field) is String or String(employee.get(field, "")).strip_edges().is_empty():
				errors.append("Missing %s for employee %s" % [field, str(id)])
	var roots := 0
	for employee in roster.employees:
		var manager = employee.get("manager_id")
		if not manager is int or manager < 0 or (manager != 0 and not by_id.has(manager)):
			errors.append("Invalid manager for employee %s" % str(employee.get("id")))
			continue
		if manager == 0:
			roots += 1
		var seen := {}
		var current = employee.get("id")
		while current is int and current != 0 and by_id.has(current):
			if seen.has(current):
				errors.append("Reporting cycle involving employee %s" % str(employee.get("id")))
				break
			seen[current] = true
			current = by_id[current].get("manager_id")
	if roots != 1:
		errors.append("Roster must have exactly one top-level employee")
	return errors.is_empty()


func _index_desks(node: Node) -> void:
	if node.has_meta("room"):
		var room := String(node.get_meta("room"))
		var number = node.get_meta("desk_number", 0)
		if room.is_empty() or not node is Marker3D or not number is int or number <= 0:
			errors.append("Invalid desk marker: " + str(node.get_path()))
		else:
			if not desks.has(room):
				desks[room] = []
			for existing in desks[room]:
				if existing.get_meta("desk_number") == number:
					errors.append("Duplicate desk %d in room %s" % [number, room])
			desks[room].append(node)
	for child in node.get_children():
		_index_desks(child)


func get_employee(id: int) -> Dictionary:
	for employee in roster.employees:
		if employee.get("id") == id:
			return employee.duplicate(true)
	return {}


func get_direct_reports(manager_id: int) -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	for employee in roster.employees:
		if employee.get("manager_id") == manager_id:
			reports.append(employee.duplicate(true))
	reports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	return reports


func get_character(id: int) -> Node3D:
	var character: Node3D = characters.get(id)
	return character if is_instance_valid(character) else null


func _make_placeholder(employee: Dictionary) -> Node3D:
	var person := Node3D.new()
	person.name = "Employee"
	person.set_meta("employee_id", employee.id)
	for spec in [
		["Base", Vector3(0.8, 0.12, 0.8), Vector3(0, 0.06, 0), "737e87"],
		["Leg1", Vector3(0.17, 0.3, 0.22), Vector3(-0.16, 0.26, 0), "737e87"],
		["Leg2", Vector3(0.17, 0.3, 0.22), Vector3(0.16, 0.26, 0), "737e87"],
		["Body", Vector3(0.55, 1.0, 0.35), Vector3(0, 0.9, 0), "96a3a4"],
		["Head", Vector3(0.4, 0.4, 0.4), Vector3(0, 1.6, 0), "c5b29c"]]:
		var part := MeshInstance3D.new()
		part.name = spec[0]
		var mesh := BoxMesh.new()
		mesh.size = spec[1]
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(spec[3])
		material.roughness = 0.9
		mesh.material = material
		part.mesh = mesh
		part.position = spec[2]
		person.add_child(part)
	if employee.room == "bullpen":
		return person
	var label := Label3D.new()
	label.text = String(employee.display_name).to_upper()
	label.position = Vector3(0, 2.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.pixel_size = 0.0025
	label.modulate = Color("344454")
	person.add_child(label)
	return person
