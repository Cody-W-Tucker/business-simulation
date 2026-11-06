extends Resource
## Functional tools that can support duties, not mandatory tools or permissions.
## Owner is accountable for the tool; maintainer supports the underlying system.
## A null maintainer means no separate maintainer is assigned.

@export var tools: Array[Dictionary] = []


func tools_for_duty(role_id: int, duty_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tool in tools:
		if {"role_id": role_id, "duty_id": duty_id} in tool.duties:
			result.append(tool.duplicate(true))
	return result
