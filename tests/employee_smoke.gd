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
	var duty_roster = load("res://data/duty_roster.tres")
	var duties: Array = duty_roster.duties_for_role(1)
	if duties.is_empty() or not duty_roster.duties_for_role(999).is_empty():
		_fail("Receptionist duties must be available by role ID; unknown IDs must be empty")
		return
	var covered_ids: Array[int] = []
	var duty_ids := {}
	var role_ids: Array[int] = []
	for role in roster.employees:
		role_ids.append(role.id)
	role_ids.sort()
	if role_ids != range(1, 22):
		_fail("Role IDs must be sequential from 1 through 21")
		return
	for entry in duty_roster.employees:
		if entry.role_id in covered_ids or entry.duties.is_empty() or entry.sources.is_empty():
			_fail("Duty roster entries must have unique roles, duties, and sources")
			return
		covered_ids.append(entry.role_id)
		var role_duty_ids: Array[int] = []
		for duty in entry.duties:
			if not duty is Dictionary or not duty.has("id") or not duty.has("name") or not duty.has("description"):
				_fail("Duties must have IDs, names, and descriptions")
				return
			if duty.id is not int or duty.id < 0 or duty.name is not String or duty.name.is_empty() or duty.description is not String or duty.description.is_empty() or duty.id in role_duty_ids:
				_fail("Duty IDs must be unique nonnegative integers and names and descriptions must be nonempty")
				return
			role_duty_ids.append(duty.id)
		duty_ids[entry.role_id] = role_duty_ids
	for role in roster.employees:
		if role.id not in covered_ids:
			_fail("Missing role duties: " + str(role.id))
			return
	var tool_roster = load("res://data/tool_roster.tres")
	var tool_ids: Array[String] = []
	for tool in tool_roster.tools:
		if tool.id.is_empty() or tool.id in tool_ids or tool.display_name.is_empty() or tool.duties.is_empty():
			_fail("Tools must have unique IDs, names, and supported duties")
			return
		if not tool.has("owner_role_id") or tool.owner_role_id not in role_ids or not tool.has("maintainer_role_id") or (tool.maintainer_role_id != null and tool.maintainer_role_id not in role_ids):
			_fail("Tool owner and optional maintainer must reference existing roles: " + tool.id)
			return
		tool_ids.append(tool.id)
		var last_role := -1
		var last_duty := -1
		for ref in tool.duties:
			if not duty_ids.has(ref.role_id) or ref.duty_id not in duty_ids[ref.role_id]:
				_fail("Tool references unknown duty: " + str(ref))
				return
			if ref.role_id < last_role or (ref.role_id == last_role and ref.duty_id <= last_duty):
				_fail("Tool duty references must be unique and sorted by role and duty: " + tool.id)
				return
			last_role = ref.role_id
			last_duty = ref.duty_id
	for role_id in duty_ids:
		for duty_id in duty_ids[role_id]:
			if tool_roster.tools_for_duty(role_id, duty_id).is_empty():
				_fail("Duty lacks a supporting tool: %d/%d" % [role_id, duty_id])
				return
	if tool_roster.tools_for_duty(7, 0).size() != 4 or not tool_roster.tools_for_duty(999, 0).is_empty():
		_fail("Tool lookup must return all supporting tools and handle unknown duties")
		return
	var hardware_roster = load("res://data/hardware_roster.tres")
	var hardware_ids: Array[String] = []
	var endpoint_roles: Array[int] = []
	var servers := 0
	for item in hardware_roster.hardware:
		if item.id.is_empty() or item.id in hardware_ids or item.owner_role_id not in role_ids or item.maintainer_role_id not in role_ids:
			_fail("Hardware IDs and responsible roles must be valid")
			return
		hardware_ids.append(item.id)
		if item.hosts_all_tools:
			servers += item.quantity
		for role_id in item.role_ids:
			if role_id not in role_ids or role_id in endpoint_roles:
				_fail("Each client role must have exactly one hardware type")
				return
			endpoint_roles.append(role_id)
	endpoint_roles.sort()
	if servers != 1 or endpoint_roles != role_ids:
		_fail("One shared server and client hardware for every role are required")
		return
	var communication_roster = load("res://data/communication_roster.tres")
	var route_ids: Array[String] = []
	for route in communication_roster.routes:
		if route.id.is_empty() or route.id in route_ids or route.situation.is_empty() or route.guidance.is_empty() or route.role_path.size() < 2:
			_fail("Communication routes must be unique and describe a situation and handoff")
			return
		route_ids.append(route.id)
		for role_id in route.role_path:
			if role_id not in role_ids:
				_fail("Communication route references unknown role: " + str(role_id))
				return
	if directory.get_employee(9).role_id != directory.get_employee(10).role_id or directory.get_employee(21).role_id != directory.get_employee(24).role_id or directory.get_employee(25).role_id != directory.get_employee(26).role_id:
		_fail("Employees in shared roles must reference the same role definition")
		return
	if directory.get_employee(11).role_id != 10 or directory.get_employee(20).role_id != 19 or directory.get_employee(21).role_id != 20 or directory.get_employee(25).role_id != 21:
		_fail("Sequential role IDs must retain their original employee assignments")
		return
	if duty_roster.duties_for_role(directory.get_employee(21).role_id) != duty_roster.duties_for_role(directory.get_employee(24).role_id):
		_fail("Employees in a shared role must have the same duties")
		return
	if not directory.errors.is_empty() or roster.employees.size() != 21 or directory.characters.size() != 26:
		_fail("Roster must contain 21 roles and the office must contain 26 employees")
		return
	for relation in [[2, 19], [16, 19], [3, 2], [5, 2], [6, 2], [7, 2], [9, 11], [10, 11], [11, 19], [25, 16], [26, 16]]:
		if directory.get_employee(relation[0]).manager_id != relation[1]:
			_fail("Incorrect reporting relationship: " + str(relation))
			return
	if directory.get_direct_reports(16).size() != 2 or directory.get_direct_reports(16)[0].id != 25:
		_fail("Direct reports must be derived from the roster in ID order")
		return
	if directory.get_employee(2).room != "service_delivery" or directory.get_employee(7).room != "service_delivery" or directory.assigned_desks[2] == directory.assigned_desks[7] or directory.assigned_desks[2].get_parent() != directory.assigned_desks[7].get_parent():
		_fail("Service Delivery Manager and Project Manager must share an office with separate desks")
		return
	for employee in roster.staffed_employees():
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
	for spec in [["Sales", "SALES"], ["ClientServices", "CLIENT SERVICES"]]:
		var team: Node = world.get_node("OfficeInterior/DepartmentsWing/" + spec[0])
		var team_labels := team.find_children("*", "Label3D", false, false)
		if team_labels.size() != 1 or team_labels[0].text != spec[1] or team_labels[0].billboard != BaseMaterial3D.BILLBOARD_ENABLED:
			_fail("Bullpen team label must face the camera: " + spec[0])
			return
	if directory.get_employee(14).department != directory.get_employee(21).department or directory.get_employee(14).room == directory.get_employee(21).room or directory.get_employee(21).department == directory.get_employee(25).department or directory.get_employee(21).room != directory.get_employee(25).room:
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
	if desired.size() != 26 or desired != reordered.desired_agents() or desired != range(1, 27):
		_fail("Agent inventory must be complete and independent of roster order")
		return
	var office = load("res://scenes/office_interior.tscn").instantiate()
	root.add_child(office)
	var other = load("res://scripts/employee_directory.gd").new()
	root.add_child(other)
	if not other.initialize(office, reordered):
		_fail("Reordered roster failed to initialize")
		return
	for employee in roster.staffed_employees():
		if other.assigned_desks[employee.id].get_meta("desk_number") != directory.assigned_desks[employee.id].get_meta("desk_number"):
			_fail("Desk assignments changed when roster was reordered")
			return
	var validator = load("res://scripts/employee_directory.gd").new()
	var invalid = roster.duplicate(true)
	invalid.employees[1]["id"] = invalid.employees[0].id
	invalid.employees[2]["id"] = "not a number"
	invalid.employees[3]["room"] = ""
	invalid.employees[4]["department"] = ""
	if validator.validate(office, invalid) or validator.errors.size() < 4:
		_fail("Invalid employee IDs, rooms and departments must be rejected")
		validator.free()
		return
	validator.free()
	var hierarchy_validator = load("res://scripts/employee_directory.gd").new()
	var broken = roster.duplicate(true)
	broken.employees[0]["manager_id"] = 999
	if hierarchy_validator.validate(office, broken):
		_fail("Unknown managers must be rejected")
		return
	broken = roster.duplicate(true)
	broken.employees[0]["manager_id"] = 1
	if hierarchy_validator.validate(office, broken):
		_fail("Reporting cycles must be rejected")
		return
	hierarchy_validator.free()
	var extra = roster.duplicate(true)
	extra.employees.append({"id": 30, "display_name": "Extra", "description": "Extra employee", "department": "sales", "room": "bullpen", "manager_id": 14})
	var extra_office = load("res://scenes/office_interior.tscn").instantiate()
	root.add_child(extra_office)
	var overflow = load("res://scripts/employee_directory.gd").new()
	root.add_child(overflow)
	if not overflow.initialize(extra_office, extra) or overflow.get_character(30) != null or overflow.characters.size() != 26 or extra.desired_agents().size() != 27:
		_fail("Desk shortage must leave only the extra employee unplaced and preserve the agent inventory")
		return
	print("PASS: simple roster, room allocation and deterministic agent inventory")
	quit(0)
