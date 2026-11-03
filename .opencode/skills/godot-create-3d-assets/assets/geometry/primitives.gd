class_name GodotAssetPrimitives
extends RefCounted


static func material(color: Color, roughness: float = 1.0,
		metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


static func box(parent: Node3D, node_name: String, position: Vector3,
		size: Vector3, surface: Material = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = surface
	parent.add_child(instance)
	return instance


static func cylinder(parent: Node3D, node_name: String, position: Vector3,
		radius: float, height: float, surface: Material = null,
		radial_segments: int = 12) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = maxi(3, radial_segments)
	instance.mesh = mesh
	instance.position = position
	instance.material_override = surface
	parent.add_child(instance)
	return instance


static func box_collision(parent: CollisionObject3D, node_name: String,
		position: Vector3, size: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)
	return collision


static func capsule_collision(parent: CollisionObject3D, node_name: String,
		position: Vector3, radius: float, height: float) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(height, radius * 2.0)
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)
	return collision


static func assign_generated_owners(root: Node) -> void:
	for child in root.get_children():
		child.owner = root
		if child.scene_file_path.is_empty():
			_assign_descendant_owner(child, root)


static func _assign_descendant_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		if child.scene_file_path.is_empty():
			_assign_descendant_owner(child, owner)
