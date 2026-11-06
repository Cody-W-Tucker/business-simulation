extends Resource
## Duty IDs are stable within a role; never renumber or reuse them.
## These records do not grant agent permissions.

@export var employees: Array[Dictionary] = []


func duties_for_role(role_id: int) -> Array:
	for role in employees:
		if role_id == role.role_id:
			return role.duties.duplicate(true)
	return []
