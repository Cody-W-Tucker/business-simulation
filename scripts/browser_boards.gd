extends Node3D

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
