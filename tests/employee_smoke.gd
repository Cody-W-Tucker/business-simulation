extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _run() -> void:
	var world = load("res://main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var directory = world.employee_directory
	var roster = directory.roster
	if not directory.errors.is_empty() or roster.employees.size() != 29 or directory.characters.size() != 29:
		_fail("Roster and characters must each contain 29 employees")
		return
	for employee in roster.employees:
		var character: Node3D = directory.get_character(employee.id)
		var desk: Marker3D = directory.assigned_desks[employee.id]
		if character == null or not character.global_position.is_equal_approx(desk.global_position) or desk.get_meta("room") != employee.room or directory.get_employee(employee.id) != employee:
			_fail("Employee lookup or room assignment failed: " + str(employee.id))
			return
		var labels := character.find_children("*", "Label3D", true, false)
		if employee.room == "bullpen":
			if not labels.is_empty():
				_fail("Bullpen employee should not have an individual label: " + str(employee.id))
				return
			continue
		if labels.size() != 1 or labels[0].text != String(employee.display_name).to_upper() or labels[0].billboard != BaseMaterial3D.BILLBOARD_ENABLED:
			_fail("Employee label must show the role and face the camera: " + str(employee.id))
			return
	for spec in [["Sales", "SALES"], ["CustomerSupport", "CUSTOMER SUPPORT"]]:
		var team: Node = world.get_node("OfficeInterior/DepartmentsWing/" + spec[0])
		var team_labels := team.find_children("*", "Label3D", false, false)
		if team_labels.size() != 1 or team_labels[0].text != spec[1] or team_labels[0].billboard != BaseMaterial3D.BILLBOARD_ENABLED:
			_fail("Bullpen team label must face the camera: " + spec[0])
			return
	if directory.get_employee(17).department != directory.get_employee(24).department or directory.get_employee(17).room == directory.get_employee(24).room or directory.get_employee(24).department == directory.get_employee(28).department or directory.get_employee(24).room != directory.get_employee(28).room:
		_fail("Department and room must be independent")
		return
	if directory.get_character(999) != null or not directory.get_employee(999).is_empty():
		_fail("Unknown employee lookup should be empty")
		return
	var character: Node3D = directory.get_character(8)
	var original := character.global_position
	character.global_position += Vector3(1, 0, 0)
	if character.global_position.is_equal_approx(original):
		_fail("Live position must follow the character, not its desk")
		return
	var desired: Array[int] = roster.desired_agents()
	var reordered = roster.duplicate(true)
	reordered.employees.reverse()
	if desired.size() != 29 or desired != reordered.desired_agents():
		_fail("Agent inventory must be complete and independent of roster order")
		return
	var office = load("res://scenes/office_interior.tscn").instantiate()
	root.add_child(office)
	var other = load("res://scripts/employee_directory.gd").new()
	root.add_child(other)
	if not other.initialize(office, reordered):
		_fail("Reordered roster failed to initialize")
		return
	for employee in roster.employees:
		if other.assigned_desks[employee.id].get_meta("desk_number") != directory.assigned_desks[employee.id].get_meta("desk_number"):
			_fail("Desk assignments changed when roster was reordered")
			return
	var validator = load("res://scripts/employee_directory.gd").new()
	var invalid = roster.duplicate(true)
	invalid.employees[1]["id"] = invalid.employees[0].id
	invalid.employees[2]["id"] = "not a number"
	invalid.employees[3]["room"] = ""
	invalid.employees[4]["department"] = ""
	if validator.validate(office, invalid) or validator.errors.size() != 4:
		_fail("Invalid employee IDs, rooms and departments must be rejected")
		validator.free()
		return
	validator.free()
	var extra = roster.duplicate(true)
	extra.employees.append({"id": 30, "display_name": "Extra", "description": "Extra employee", "department": "sales", "room": "bullpen"})
	var extra_office = load("res://scenes/office_interior.tscn").instantiate()
	root.add_child(extra_office)
	var overflow = load("res://scripts/employee_directory.gd").new()
	root.add_child(overflow)
	if not overflow.initialize(extra_office, extra) or overflow.get_character(30) != null or overflow.characters.size() != 29 or extra.desired_agents().size() != 30:
		_fail("Desk shortage must leave only the extra employee unplaced and preserve the agent inventory")
		return
	print("PASS: simple roster, room allocation and deterministic agent inventory")
	quit(0)
