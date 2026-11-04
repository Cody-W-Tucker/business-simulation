extends Resource
## Authored definitions only. Employee IDs must remain stable and never be reused.

@export var employees: Array[Dictionary] = []


func desired_agents() -> Array[int]:
	var result: Array[int] = []
	for employee in employees:
		result.append(employee.id)
	result.sort()
	return result
