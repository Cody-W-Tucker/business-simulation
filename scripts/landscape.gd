extends Node3D

# One Godot unit represents one meter. Board sizes and positions live here so
# new browser walls can be added without changing input or browser management.
const EXCALIDRAW_URL := "https://draw.homehub.tv/"
const PROJECTS_URL := "https://opencode.homehub.tv/"

var boards: Array[Dictionary] = []
var wall_brightness := 0.88
var palace_material: StandardMaterial3D


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
	board.name = title.replace(" ", "_")
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


func _add_box_collision(body: StaticBody3D, size: Vector3, transform: Transform3D) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.transform = transform
	body.add_child(collision)


func _make_arch_curve() -> ArrayMesh:
	# One continuous extruded semicircle: no gaps between separate voussoirs.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 48
	for i in range(segments):
		var a := PI * float(i) / segments
		var b := PI * float(i + 1) / segments
		var points: Array[Vector3] = []
		for z in [-0.575, 0.575]:
			for radius in [4.4, 5.3]:
				for theta in [a, b]:
					points.append(Vector3(radius * cos(theta), 5.25 + radius * sin(theta), z))
		# Front, back, outside, inside; adjacent segments share exact edges.
		for indices in [[4, 6, 7, 4, 7, 5], [0, 1, 3, 0, 3, 2], [2, 3, 7, 2, 7, 6], [0, 4, 5, 0, 5, 1]]:
			for index in indices:
				surface.add_vertex(points[index])
	surface.generate_normals()
	return surface.commit()


func _make_arch(position: Vector3, angle: float) -> void:
	# A simple architectural blockout, behind the board's interactive surface.
	var arch := Node3D.new()
	arch.name = "RomanArch"
	arch.position = position
	arch.rotation.y = angle
	add_child(arch, true)
	var limestone := Color("c7b79c")
	for side in [-1.0, 1.0]:
		_box(arch, Vector3(1.15, 5.25, 1.15), Vector3(side * 4.85, 2.625, 0), limestone)
		_box(arch, Vector3(1.5, 0.4, 1.5), Vector3(side * 4.85, 0.2, 0), limestone)
		_box(arch, Vector3(1.5, 0.35, 1.5), Vector3(side * 4.85, 5.1, 0), limestone)
	var body := StaticBody3D.new()
	body.name = "ArchCollision"
	arch.add_child(body)
	for child in arch.get_children():
		if child is MeshInstance3D:
			child.material_override = palace_material
			_add_box_collision(body, child.mesh.size, child.transform)
	var curve := MeshInstance3D.new()
	curve.name = "ContinuousArch"
	curve.mesh = _make_arch_curve()
	curve.material_override = palace_material
	arch.add_child(curve)
	for i in range(17):
		var theta := PI * (float(i) + 0.5) / 17.0
		var origin := Vector3(4.85 * cos(theta), 5.25 + 4.85 * sin(theta), 0)
		var basis := Basis(Vector3.FORWARD, -(theta + PI / 2.0))
		_add_box_collision(body, Vector3(PI * 4.85 / 17.0 + 0.08, 0.9, 1.15), Transform3D(basis, origin))


func _make_courtyard_walls() -> void:
	var walls := Node3D.new()
	walls.name = "PalaceWalls"
	add_child(walls)
	for side in range(4):
		var section := Node3D.new()
		section.rotation.y = side * PI / 2.0
		walls.add_child(section)
		var body := StaticBody3D.new()
		section.add_child(body)
		# Two wall wings leave the central board and its arch unobstructed.
		for sign_side in [-1.0, 1.0]:
			# Alternating sides butt into the other pair rather than sharing top faces.
			var outer := 32.0 if side % 2 == 0 else 29.55
			var width := outer - 5.2
			var center := (outer + 5.2) / 2.0
			var block := _box(section, Vector3(width, 5.0, 2.4), Vector3(sign_side * center, 2.5, -30.75), Color.WHITE)
			block.material_override = palace_material
			_add_box_collision(body, block.mesh.size, block.transform)
			var coping_outer := 32.05 if side % 2 == 0 else 29.45
			var coping := _box(section, Vector3(coping_outer - 5.2, 0.35, 2.6), Vector3(sign_side * (coping_outer + 5.2) / 2.0, 5.175, -30.75), Color.WHITE)
			coping.material_override = palace_material
			# Avoid unstable thin-lip shadow-map artifacts close to the camera.
			coping.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_add_box_collision(body, coping.mesh.size, coping.transform)


func _make_ground() -> void:
	# One flat surface keeps the prototype's movement and board heights intact.
	var ground := MeshInstance3D.new()
	ground.name = "MeadowGround"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(150, 150)
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/meadow.gdshader")
	material.set_shader_parameter("meadow", preload("res://assets/ambientcg-grass/Grass001_2K-JPG_Color.jpg"))
	mesh.material = material
	ground.mesh = mesh
	add_child(ground)

	# A level courtyard extends just beyond the four board centres.
	var courtyard := MeshInstance3D.new()
	courtyard.name = "StoneCourtyard"
	var paving := PlaneMesh.new()
	paving.size = Vector2(64, 64)
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = preload("res://assets/polyhaven-landscape/stone_floor_diff_4k.jpg")
	stone.normal_enabled = true
	stone.normal_texture = preload("res://assets/polyhaven-landscape/stone_floor_nor_gl_4k.jpg")
	stone.normal_scale = 0.6
	stone.roughness = 1.0
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	stone.uv1_scale = Vector3(64.0 / 16.2, 64.0 / 16.2, 1)
	paving.material = stone
	courtyard.mesh = paving
	courtyard.position.y = 0.01
	add_child(courtyard)


func _make_tree_border() -> void:
	var trees := Node3D.new()
	trees.name = "TreeBorder"
	add_child(trees)
	var species: Array[PackedScene] = [
		preload("res://assets/terraintale-trees/oak_tree_large.glb"),
		preload("res://assets/terraintale-trees/ash_tree.glb"),
		preload("res://assets/terraintale-trees/pine_tree.glb"),
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7432
	# Overlapping, staggered rings conceal the edge from inside the playable area.
	for group in range(32):
		var direction := TAU * (float(group) + rng.randf_range(-0.12, 0.12)) / 32.0
		var center := Vector2(cos(direction), sin(direction)) * 62.0
		for i in range(4):
			var point := center + Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0))
			var tree := species[rng.randi_range(0, species.size() - 1)].instantiate() as Node3D
			tree.position = Vector3(point.x, 0, point.y)
			tree.rotation.y = rng.randf_range(0.0, TAU)
			tree.scale = Vector3.ONE * rng.randf_range(1.2, 1.9)
			trees.add_child(tree)
	# Keep the player inside the screen of trees, including while flying.
	var boundary := StaticBody3D.new()
	boundary.name = "WoodlandBoundary"
	add_child(boundary)
	for side in range(16):
		var angle := TAU * side / 16.0
		var origin := Vector3(sin(angle) * 55.0, 15.0, cos(angle) * 55.0)
		_add_box_collision(boundary, Vector3(22.0, 30.0, 1.0), Transform3D(Basis(Vector3.UP, angle), origin))


func build(brightness: float, shadows: bool = true) -> Array[Dictionary]:
	wall_brightness = brightness
	palace_material = StandardMaterial3D.new()
	palace_material.albedo_texture = preload("res://assets/polyhaven-landscape/white_sandstone_blocks_02_diff_1k.jpg")
	palace_material.normal_enabled = true
	palace_material.normal_texture = preload("res://assets/polyhaven-landscape/white_sandstone_blocks_02_nor_gl_1k.jpg")
	palace_material.normal_scale = 0.35
	palace_material.roughness = 1.0
	palace_material.uv1_triplanar = true
	palace_material.uv1_scale = Vector3(0.22, 0.22, 0.22)
	palace_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = preload("res://assets/polyhaven-landscape/meadow_2_4k.hdr")
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("c6d8d5")
	env.fog_depth_begin = 80.0
	env.fog_depth_end = 600.0
	env.fog_density = 0.25
	# The panorama is the distant landscape, not geometry to hide behind fog.
	env.fog_sky_affect = 0.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dce8f3")
	env.ambient_light_energy = 0.48
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 0.8
	light.shadow_enabled = shadows
	light.directional_shadow_max_distance = 100.0
	add_child(light)
	_make_ground()
	_make_tree_border()
	_make_courtyard_walls()
	# A single reversible trial, separate from the working board arches.
	var ruins := preload("res://assets/3td-ruins/ruined_arch.glb").instantiate() as Node3D
	ruins.name = "TrialRuinedArch"
	ruins.position = Vector3(-17, 0, -22)
	add_child(ruins)
	for data in [[Vector3(0, 0, -30.2), 0.0], [Vector3(-30.2, 0, 0), PI / 2.0], [Vector3(30.2, 0, 0), -PI / 2.0], [Vector3(0, 0, 30.2), PI]]:
		_make_arch(data[0], data[1])
	_make_browser_board("EXCALIDRAW", EXCALIDRAW_URL, Vector3(0, 2.5, -29.85), 0, Vector2(8.0, 4.5))
	_make_board("YOUR IDEAS", "A whiteboard for what's next", Vector3(-29.85, 2.7, 0), PI / 2.0)
	_make_browser_board("PROJECTS", PROJECTS_URL, Vector3(29.85, 2.7, 0), -PI / 2.0, Vector2(8.0, 4.5))
	_make_board("COMING SOON", "A space for something new", Vector3(0, 2.5, 29.85), PI, Vector2(8.0, 4.5))
	var office_door := Node3D.new()
	office_door.name = "OfficeDoor"
	# Against the south courtyard edge rather than freestanding in its center.
	office_door.position = Vector3(-17, 0, 29.4)
	office_door.rotation.y = PI
	add_child(office_door)
	_box(office_door, Vector3(2.1, 2.7, 0.3), Vector3(0, 1.35, 0), Color("c7b79c"))
	_box(office_door, Vector3(1.65, 2.3, 0.12), Vector3(0, 1.15, 0.2), Color("697888"))
	var sign := Label3D.new()
	sign.text = "OFFICE\n[E]"
	sign.font_size = 42
	sign.pixel_size = 0.005
	sign.position = Vector3(0, 1.55, 0.28)
	office_door.add_child(sign)
	return boards
