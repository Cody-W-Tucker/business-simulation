extends Resource
## Job definitions are shared; staffing identifies individual runtime employees.
## Role and employee IDs must remain stable and never be reused.

@export var employees: Array[Dictionary] = []
@export var staffing: Dictionary = {}


func staffed_employees() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for role in employees:
		for employee_id in staffing.get(role.id, [role.id]):
			var employee: Dictionary = role.duplicate(true)
			employee["role_id"] = role.id
			employee["id"] = employee_id
			result.append(employee)
	return result


func desired_agents() -> Array[int]:
	var result: Array[int] = []
	for employee in staffed_employees():
		result.append(employee.id)
	result.sort()
	return result
