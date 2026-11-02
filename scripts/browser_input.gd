extends RefCounted
## Translate mouse events for gdCEF. Keyboard events retain their existing path.


static func forward_mouse(browser: Node, event: InputEvent, position: Vector2) -> void:
	if event is InputEventMouseMotion:
		browser.call("set_mouse_moved", int(position.x), int(position.y))
	elif event is InputEventMouseButton:
		browser.call("set_mouse_moved", int(position.x), int(position.y))
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				browser.call("set_mouse_left_down" if event.pressed else "set_mouse_left_up")
			MOUSE_BUTTON_RIGHT:
				browser.call("set_mouse_right_down" if event.pressed else "set_mouse_right_up")
			MOUSE_BUTTON_MIDDLE:
				browser.call("set_mouse_middle_down" if event.pressed else "set_mouse_middle_up")
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					browser.call("set_mouse_wheel_vertical", 2 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -2, event.shift_pressed, event.ctrl_pressed, event.alt_pressed)
