extends Node3D

# One Godot unit represents one meter. Board sizes and positions live here so
# new browser walls can be added without changing input or browser management.
const EXCALIDRAW_URL := "https://draw.homehub.tv/"
const PROJECTS_URL := "https://opencode.homehub.tv/"

var boards: Array[Dictionary] = []
var wall_brightness := 0.88


func _box(parent: Node3D, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material = material
	instance.mesh = mesh
	instance.position = position
	parent.add_child(instance)
	return instance


func _make_board(title: String, subtitle: String, position: Vector3, angle: float, board_size := Vector2(5.0, 2.84)) -> Node3D:
	var board := Node3D.new()
	board.position = position
	board.rotation.y = angle
	add_child(board)
	_box(board, Vector3(board_size.x + 0.3, board_size.y + 0.3, 0.14), Vector3.ZERO, Color("334155"))
	_box(board, Vector3(board_size.x, board_size.y, 0.04), Vector3(0, 0, 0.09), Color("f3f3ee"))
	var heading := Label3D.new()
	heading.text = title
	heading.font_size = 42
	heading.pixel_size = 0.008
	heading.modulate = Color("293a4a")
	heading.position = Vector3(0, 0.35, 0.13)
	board.add_child(heading)
	var description := Label3D.new()
	description.text = subtitle
	description.font_size = 22
	description.pixel_size = 0.008
	description.modulate = Color("758494")
	description.position = Vector3(0, -0.25, 0.13)
	board.add_child(description)
	return board


func _make_browser_board(title: String, url: String, position: Vector3, angle: float, size: Vector2) -> void:
	var node := _make_board(title, "Loading browser...", position, angle, size)
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(wall_brightness, wall_brightness, wall_brightness)
	quad.material = material
	mesh.mesh = quad
	mesh.position.z = 0.15
	mesh.visible = false
	node.add_child(mesh)
	boards.append({"node": node, "size": size, "mesh": mesh, "material": material, "url": url})


func _make_distant_hills() -> void:
	# A stationary, low-detail silhouette gives the horizon depth without
	# animated shaders or an additional downloaded asset pack.
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var segments := 128
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		var height := 30.0 + 10.0 * sin(angle * 5.0 + 0.4) + 6.0 * sin(angle * 11.0) + 3.0 * cos(angle * 19.0)
		var x := sin(angle) * 350.0
		var z := cos(angle) * 350.0
		vertices.append(Vector3(x, -8.0, z))
		vertices.append(Vector3(x, height, z))
		if i < segments:
			var base := i * 2
			indices.append_array(PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color("80999c")
	mesh.surface_set_material(0, material)
	var hills := MeshInstance3D.new()
	hills.mesh = mesh
	add_child(hills)


func build(brightness: float) -> Array[Dictionary]:
	wall_brightness = brightness
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("779aaf")
	sky_material.sky_horizon_color = Color("c6d8d5")
	sky_material.ground_horizon_color = Color("c6d8d5")
	sky_material.ground_bottom_color = Color("91aaa3")
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("c6d8d5")
	env.fog_depth_begin = 80.0
	env.fog_depth_end = 600.0
	env.fog_density = 0.75
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce8f3")
	env.ambient_light_energy = 0.85
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 0.8
	add_child(light)
	_box(self, Vector3(1000, 0.2, 1000), Vector3(0, -0.1, 0), Color("91aaa3"))
	_make_distant_hills()
	_make_browser_board("EXCALIDRAW", EXCALIDRAW_URL, Vector3(0, 2.5, -29.85), 0, Vector2(8.0, 4.5))
	_make_board("YOUR IDEAS", "A whiteboard for what's next", Vector3(-29.85, 2.7, 0), PI / 2.0)
	_make_browser_board("PROJECTS", PROJECTS_URL, Vector3(29.85, 2.7, 0), -PI / 2.0, Vector2(8.0, 4.5))
	return boards
