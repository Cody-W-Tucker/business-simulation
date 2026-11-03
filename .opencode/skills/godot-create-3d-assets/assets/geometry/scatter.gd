class_name GodotAssetScatter
extends RefCounted


static func points_in_ellipse(seed_value: int, count: int, radii: Vector2,
		minimum_spacing: float = 0.0, exclusions: Array[AABB] = []) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array[Vector3] = []
	var attempts := 0
	var maximum_attempts := maxi(count * 80, 100)
	while result.size() < count and attempts < maximum_attempts:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var radial := sqrt(rng.randf())
		var point := Vector3(cos(angle) * radii.x * radial, 0.0,
			sin(angle) * radii.y * radial)
		var rejected := false
		for exclusion in exclusions:
			if exclusion.has_point(point):
				rejected = true
				break
		if rejected:
			continue
		for existing in result:
			if Vector2(existing.x - point.x, existing.z - point.z).length() < minimum_spacing:
				rejected = true
				break
		if not rejected:
			result.append(point)
	return result


static func partitioned_multimeshes(parent: Node3D, prefix: String, mesh: Mesh,
		transforms: Array[Transform3D], partition_size: float,
		material_override: Material = null) -> Array[MultiMeshInstance3D]:
	var partitions := {}
	var cell_size := maxf(partition_size, 1.0)
	for item in transforms:
		var key := Vector2i(floori(item.origin.x / cell_size), floori(item.origin.z / cell_size))
		if not partitions.has(key):
			partitions[key] = []
		partitions[key].append(item)
	var result: Array[MultiMeshInstance3D] = []
	var keys: Array = partitions.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y))
	for key: Vector2i in keys:
		var cell_transforms: Array = partitions[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = cell_transforms.size()
		var bounds := AABB()
		var has_bounds := false
		for index in cell_transforms.size():
			var item: Transform3D = cell_transforms[index]
			multimesh.set_instance_transform(index, item)
			var transformed := item * mesh.get_aabb()
			bounds = transformed if not has_bounds else bounds.merge(transformed)
			has_bounds = true
		multimesh.custom_aabb = bounds.grow(0.25)
		var instance := MultiMeshInstance3D.new()
		instance.name = "%s_%d_%d" % [prefix, key.x, key.y]
		instance.multimesh = multimesh
		instance.material_override = material_override
		parent.add_child(instance)
		result.append(instance)
	return result
