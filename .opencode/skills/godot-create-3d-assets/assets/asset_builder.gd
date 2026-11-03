extends Node
## Copy into a Godot project's tools/ directory and tailor the contract.

const OUTPUT_PATH := "res://world/generated/example_asset.tscn"
const MANIFEST_PATH := "res://world/generated/example_asset.asset.json"


func _ready() -> void:
	var root := StaticBody3D.new()
	root.name = "ExampleAsset"
	add_child(root)
	build_asset(root)
	assign_owner(root, root)
	var expected := scene_metrics(root)

	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		_fail("Could not pack asset: %s" % error_string(pack_error))
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		_fail("Could not save asset: %s" % error_string(save_error))
		return

	var saved := ResourceLoader.load(OUTPUT_PATH, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene
	if saved == null:
		_fail("Could not reload saved asset: %s" % OUTPUT_PATH)
		return
	var round_trip := saved.instantiate() as Node3D
	if round_trip == null:
		_fail("Saved asset could not be instantiated")
		return
	add_child(round_trip)
	var actual := scene_metrics(round_trip)
	var compared := ["nodes", "mesh_instances", "multimesh_instances",
		"multimesh_elements", "collision_shapes", "surfaces", "triangles"]
	for key in compared:
		if expected[key] != actual[key]:
			round_trip.queue_free()
			_fail("Round-trip changed %s: %s -> %s" % [key, expected[key], actual[key]])
			return

	var manifest_error := write_manifest(actual)
	if manifest_error != OK:
		round_trip.queue_free()
		_fail("Could not save asset manifest: %s" % error_string(manifest_error))
		return
	print("asset metrics: %s" % JSON.stringify(actual))
	print("ASSET BUILT: %s" % OUTPUT_PATH)
	round_trip.queue_free()
	root.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)


func build_asset(root: StaticBody3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.28, 0.16, 0.07)
	material.roughness = 1.0
	add_box(root, "Body", Vector3(0.0, 0.5, 0.0), Vector3(2.0, 1.0, 1.0), material)
	add_box_collision(root, "BodyCollision", Vector3(0.0, 0.5, 0.0), Vector3(2.0, 1.0, 1.0))


func add_box(parent: Node3D, node_name: String, position: Vector3,
		size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance


func add_box_collision(parent: StaticBody3D, node_name: String,
		position: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)


func assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child.scene_file_path == "":
			assign_owner(child, owner)


func scene_metrics(root: Node3D) -> Dictionary:
	var metrics := {
		"nodes": 0,
		"mesh_instances": 0,
		"multimesh_instances": 0,
		"multimesh_elements": 0,
		"multimesh_buffer_floats": 0,
		"multimesh_invalid_buffers": 0,
		"multimesh_missing_custom_aabb": 0,
		"collision_shapes": 0,
		"surfaces": 0,
		"triangles": 0,
		"unique_materials": 0,
		"lights": 0,
		"particles": 0,
		"nonuniform_scales": 0,
	}
	var materials := {}
	accumulate_metrics(root, metrics, materials)
	metrics["unique_materials"] = materials.size()
	var bounds := merged_bounds(root)
	metrics["bounds"] = {
		"position": [bounds.position.x, bounds.position.y, bounds.position.z],
		"size": [bounds.size.x, bounds.size.y, bounds.size.z],
	}
	return metrics


func accumulate_metrics(node: Node, metrics: Dictionary, materials: Dictionary) -> void:
	metrics["nodes"] += 1
	if node is Node3D:
		var node_scale := (node as Node3D).transform.basis.get_scale().abs()
		if not is_equal_approx(node_scale.x, node_scale.y) or not is_equal_approx(node_scale.y, node_scale.z):
			metrics["nonuniform_scales"] += 1
	if node is CollisionShape3D:
		metrics["collision_shapes"] += 1
	if node is Light3D:
		metrics["lights"] += 1
	if node is GPUParticles3D or node is CPUParticles3D:
		metrics["particles"] += 1
	if node is MeshInstance3D:
		metrics["mesh_instances"] += 1
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh != null:
			metrics["surfaces"] += mesh.get_surface_count()
			for surface in mesh.get_surface_count():
				var material := mesh_instance.material_override
				if material == null:
					material = mesh.surface_get_material(surface)
				if material != null:
					materials[material.get_instance_id()] = true
			metrics["triangles"] += mesh.get_faces().size() / 3
	if node is MultiMeshInstance3D:
		var multimesh_instance := node as MultiMeshInstance3D
		var multimesh := multimesh_instance.multimesh
		if multimesh != null and multimesh.mesh != null:
			metrics["multimesh_instances"] += 1
			metrics["multimesh_elements"] += multimesh.instance_count
			var buffer_size := multimesh.get_buffer().size()
			metrics["multimesh_buffer_floats"] += buffer_size
			var stride := 12 + (4 if multimesh.use_colors else 0) \
				+ (4 if multimesh.use_custom_data else 0)
			if multimesh.instance_count > 0 and buffer_size < multimesh.instance_count * stride:
				metrics["multimesh_invalid_buffers"] += 1
			var authored_bounds := multimesh.custom_aabb
			if multimesh.instance_count > 0 and (authored_bounds.size.x <= 0.0 \
					or authored_bounds.size.y <= 0.0 or authored_bounds.size.z <= 0.0):
				metrics["multimesh_missing_custom_aabb"] += 1
			metrics["surfaces"] += multimesh.mesh.get_surface_count()
			metrics["triangles"] += multimesh.mesh.get_faces().size() / 3 * multimesh.instance_count
			for surface in multimesh.mesh.get_surface_count():
				var material := multimesh_instance.material_override
				if material == null:
					material = multimesh.mesh.surface_get_material(surface)
				if material != null:
					materials[material.get_instance_id()] = true
	for child in node.get_children():
		accumulate_metrics(child, metrics, materials)


func merged_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for found in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := found as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var relative := root.global_transform.affine_inverse() * mesh_instance.global_transform
		var transformed := relative * mesh_instance.get_aabb()
		bounds = transformed if not has_bounds else bounds.merge(transformed)
		has_bounds = true
	for found in root.find_children("*", "MultiMeshInstance3D", true, false):
		var multimesh_instance := found as MultiMeshInstance3D
		if multimesh_instance.multimesh == null or multimesh_instance.multimesh.mesh == null:
			continue
		var relative := root.global_transform.affine_inverse() * multimesh_instance.global_transform
		var transformed := relative * multimesh_instance.get_aabb()
		bounds = transformed if not has_bounds else bounds.merge(transformed)
		has_bounds = true
	return bounds


func write_manifest(metrics: Dictionary) -> Error:
	var manifest := {
		"schema_version": 2,
		"profile": "prop",
		"asset_name": "example_asset",
		"scene": OUTPUT_PATH,
		"builder": "res://tools/asset_builder.gd",
		"units": "meters",
		"forward": "-Z",
		"origin": "ground_center",
		"footprint_m": [2.0, 1.0],
		"height_m": 1.0,
		"interaction_sides": ["front"],
		"style_references": [],
		"collision": {"required": true, "strategy": "primitive_shapes"},
		"routes": [],
		"budgets": {
			"nodes": 40,
			"mesh_instances": 24,
			"multimesh_instances": 0,
			"multimesh_elements": 0,
			"multimesh_invalid_buffers": 0,
			"multimesh_missing_custom_aabb": 0,
			"collision_shapes": 4,
			"concave_collision_shapes": 0,
			"collision_triangles": 0,
			"surfaces": 32,
			"triangles": 20000,
			"unique_materials": 6,
			"lights": 2,
			"particles": 2,
			"nonuniform_scales": 0,
		},
		"review": {
			"center": [0.0, 0.5, 0.0],
			"radius": 4.0,
			"camera_height": 1.25,
			"required_views": ["front", "back", "left", "right", "context"],
		},
		"evidence": {"structural": [], "runtime": [], "performance": [], "visual": []},
		"source": {"kind": "godot_native", "license": "project-native"},
		"measured": metrics,
		"notes": [],
	}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "  "))
	return OK


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
