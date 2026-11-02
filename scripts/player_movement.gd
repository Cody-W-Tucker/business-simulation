extends RefCounted
## Movement math is kept separate from browser interaction and input routing.


static func is_on_jump_surface(room: Node3D) -> bool:
	return room.vertical_speed <= 0.0 and (room.player.position.y <= 0.001 or room.player.is_on_floor())


static func try_jump(room: Node3D) -> bool:
	if not room.flying and is_on_jump_surface(room):
		room.vertical_speed = room.jump_speed
		return true
	return false


static func move(room: Node3D, movement: Vector3, speed: float, delta: float) -> void:
	if room.flying or is_on_jump_surface(room):
		room.horizontal_velocity = movement.normalized() * speed
	if room.flying:
		var vertical_input := Input.get_action_strength("room_jump") - Input.get_action_strength("room_descend")
		var flight_speed := 12.0 if Input.is_action_pressed("room_fast") else 6.0
		room.vertical_speed = vertical_input * flight_speed
	else:
		room.vertical_speed -= 12.0 * delta
	room.player.velocity = Vector3(room.horizontal_velocity.x, room.vertical_speed, room.horizontal_velocity.z)
	room.player.move_and_slide()
	room.horizontal_velocity = Vector3(room.player.velocity.x, 0, room.player.velocity.z)
	room.vertical_speed = room.player.velocity.y
	room.player.position.y = clampf(room.player.position.y, 0.0, 24.5 - room.EYE_HEIGHT)
	if room.player.position.y <= 0.0 and room.vertical_speed < 0.0:
		room.vertical_speed = 0.0
