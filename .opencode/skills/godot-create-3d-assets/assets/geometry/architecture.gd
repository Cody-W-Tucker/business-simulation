class_name GodotAssetArchitecture
extends RefCounted


static func wall_with_opening(parent: Node3D, prefix: String, center: Vector3,
		wall_size: Vector3, opening_width: float, opening_height: float,
		surface: Material = null) -> Array[MeshInstance3D]:
	var parts: Array[MeshInstance3D] = []
	var side_width := (wall_size.x - opening_width) * 0.5
	if side_width <= 0.0 or opening_height >= wall_size.y:
		push_error("Opening must fit inside wall")
		return parts
	var side_y := center.y
	parts.append(GodotAssetPrimitives.box(parent, prefix + "Left",
		center + Vector3(-(opening_width + side_width) * 0.5, 0.0, 0.0),
		Vector3(side_width, wall_size.y, wall_size.z), surface))
	parts.append(GodotAssetPrimitives.box(parent, prefix + "Right",
		center + Vector3((opening_width + side_width) * 0.5, 0.0, 0.0),
		Vector3(side_width, wall_size.y, wall_size.z), surface))
	var header_height := wall_size.y - opening_height
	parts.append(GodotAssetPrimitives.box(parent, prefix + "Header",
		Vector3(center.x, side_y + (wall_size.y - header_height) * 0.5, center.z),
		Vector3(opening_width, header_height, wall_size.z), surface))
	return parts


static func straight_stairs(parent: Node3D, prefix: String, start: Vector3,
		width: float, total_run: float, total_rise: float, steps: int,
		surface: Material = null) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var count := maxi(1, steps)
	var tread := total_run / count
	var rise := total_rise / count
	for index in count:
		var height := rise * (index + 1)
		var position := start + Vector3(0.0, height * 0.5, -tread * (index + 0.5))
		result.append(GodotAssetPrimitives.box(parent, "%s%02d" % [prefix, index],
			position, Vector3(width, height, tread + 0.02), surface))
	return result


static func gable(parent: Node3D, node_name: String, center: Vector3,
		width: float, height: float, depth: float, surface: Material = null) -> MeshInstance3D:
	var vertices := PackedVector3Array([
		Vector3(-width * 0.5, 0.0, -depth * 0.5), Vector3(width * 0.5, 0.0, -depth * 0.5), Vector3(0.0, height, -depth * 0.5),
		Vector3(width * 0.5, 0.0, depth * 0.5), Vector3(-width * 0.5, 0.0, depth * 0.5), Vector3(0.0, height, depth * 0.5),
		Vector3(-width * 0.5, 0.0, depth * 0.5), Vector3(-width * 0.5, 0.0, -depth * 0.5), Vector3(0.0, height, -depth * 0.5),
		Vector3(-width * 0.5, 0.0, depth * 0.5), Vector3(0.0, height, -depth * 0.5), Vector3(0.0, height, depth * 0.5),
		Vector3(width * 0.5, 0.0, -depth * 0.5), Vector3(width * 0.5, 0.0, depth * 0.5), Vector3(0.0, height, depth * 0.5),
		Vector3(width * 0.5, 0.0, -depth * 0.5), Vector3(0.0, height, depth * 0.5), Vector3(0.0, height, -depth * 0.5)
	])
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in vertices:
		tool.set_smooth_group(-1)
		tool.add_vertex(vertex)
	tool.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = tool.commit()
	instance.position = center
	instance.material_override = surface
	parent.add_child(instance)
	return instance
