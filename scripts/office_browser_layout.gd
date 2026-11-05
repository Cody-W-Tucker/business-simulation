extends RefCounted
## Board placement belongs to this office, not to the browser runtime.


static func populate(office: Node3D, builder: Node3D) -> void:
	for spec in [[5, "EXCALIDRAW", builder.EXCALIDRAW_URL], [2, "PROJECTS", builder.PROJECTS_URL], [0, "HOMEHUB", builder.HOMEHUB_URL], [4, "HOMEHUB", builder.HOMEHUB_URL], [6, "HOMEHUB", builder.HOMEHUB_URL]]:
		var wall: Node3D = office.get_node("ProjectsResearchWing/OctagonWall%d" % spec[0])
		for child in wall.get_children():
			if child.name in ["ResearchScreen", "ResearchPlaceholder"] or child is Label3D:
				child.visible = false
		var inward := signf(wall.basis.z.dot(Vector3(0, 0, -15) - wall.position))
		var board: Node3D = builder.make_browser_board(spec[1], spec[2], Vector2(3.0, 1.6875))
		board.reparent(wall, false)
		board.position = Vector3(0, 1.65, inward * 0.16)
		board.rotation.y = 0.0 if inward > 0 else PI
	var research: Node3D = office.get_node("ProjectsResearchWing")
	for side in [-1.0, 1.0]:
		var board: Node3D = builder.make_browser_board("HOMEHUB", builder.HOMEHUB_URL, Vector2(3.0, 1.6875))
		board.reparent(research, false)
		board.position = Vector3(side * 12.65, 1.65, -15)
		board.rotation.y = -side * PI / 2.0
