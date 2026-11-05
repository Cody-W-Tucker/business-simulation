extends Node
## Owns browser instances, their views, and the external preview fallback.

signal browsers_ready(layer: CanvasLayer)

const REFRESH_SECONDS := 60.0

var boards: Array[Dictionary] = []
var frame_rate := 1
var mouse_input: Callable
var cef: Node
var browser_pid := -1
var refresh_in := INF
var screenshot_path: String
var profile_path: String
var embedded_active := false


func start(board_list: Array[Dictionary], idle_frame_rate: int, on_mouse_input: Callable) -> void:
	boards = board_list
	frame_rate = idle_frame_rate
	mouse_input = on_mouse_input
	screenshot_path = ProjectSettings.globalize_path("user://excalidraw-preview.png")
	profile_path = ProjectSettings.globalize_path("user://preview-browser")
	if DisplayServer.get_name() != "headless":
		if OS.get_environment("ROOM_ENABLE_GDCEF") == "1":
			_start_embedded.call_deferred()
		else:
			_start_preview()


func _process(delta: float) -> void:
	if embedded_active:
		for board in boards:
			var view: TextureRect = board.get("view")
			if view != null and view.texture != null and board.material.albedo_texture != view.texture:
				board.material.albedo_texture = view.texture
				board.mesh.visible = true
		return
	if browser_pid > 0 and not OS.is_process_running(browser_pid):
		browser_pid = -1
		var image := Image.load_from_file(screenshot_path)
		if image != null and not image.is_empty():
			image.generate_mipmaps()
			boards[0].material.albedo_texture = ImageTexture.create_from_image(image)
			boards[0].mesh.visible = true
		refresh_in = REFRESH_SECONDS
	elif browser_pid < 0:
		refresh_in -= delta
		if refresh_in <= 0.0:
			_start_preview()


func _start_preview() -> void:
	# A failed capture must not masquerade as a fresh image.
	if FileAccess.file_exists(screenshot_path):
		DirAccess.remove_absolute(screenshot_path)
	browser_pid = OS.create_process("chromium", PackedStringArray([
		"--headless", "--disable-gpu", "--hide-scrollbars", "--no-first-run",
		"--no-default-browser-check", "--user-data-dir=" + profile_path,
		"--window-size=2560,1440", "--virtual-time-budget=10000",
		"--screenshot=" + screenshot_path, boards[0].url
	]))
	if browser_pid <= 0:
		browser_pid = -1
		refresh_in = REFRESH_SECONDS


func _start_embedded() -> void:
	if not ClassDB.class_exists("GdCEF"):
		var result := GDExtensionManager.load_extension("res://cef_artifacts/gdcef.gdextension")
		if result != GDExtensionManager.LOAD_STATUS_OK:
			push_warning("gdCEF unavailable; using browser fallback")
			_start_preview()
			return
	cef = ClassDB.instantiate("GdCEF")
	if cef == null:
		push_warning("gdCEF class unavailable; using browser fallback")
		_start_preview()
		return
	add_child(cef)
	var cache := ProjectSettings.globalize_path("user://gdcef-cache")
	DirAccess.make_dir_recursive_absolute(cache)
	if not cef.call("initialize", {"root_cache_path": cache, "cache_path": cache, "log_file": ProjectSettings.globalize_path("user://gdcef.log")}):
		push_warning("gdCEF initialization failed: " + str(cef.call("get_error")))
		_start_preview()
		return
	var layer := CanvasLayer.new()
	add_child(layer)
	for board in boards:
		var view := TextureRect.new()
		view.focus_mode = Control.FOCUS_ALL
		view.mouse_filter = Control.MOUSE_FILTER_STOP
		view.gui_input.connect(mouse_input)
		layer.add_child(view)
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		view.visible = false
		board["view"] = view
	await get_tree().process_frame
	for board in boards:
		var view: TextureRect = board.view
		var instance: Node = cef.call("create_browser", board.url, view, {"javascript": true, "webgl": true, "frame_rate": frame_rate})
		board["browser"] = instance
		if instance == null:
			push_warning("gdCEF browser creation failed for %s: %s" % [board.url, cef.call("get_error")])
		else:
			embedded_active = true
			view.resized.connect(_resize_browser.bind(instance, view))
	layer.visible = false
	browsers_ready.emit(layer)
	if not embedded_active:
		_start_preview()


func _resize_browser(instance: Node, view: TextureRect) -> void:
	instance.call("resize", view.size)


func _exit_tree() -> void:
	if cef != null:
		cef.call("shutdown")
	if browser_pid > 0 and OS.is_process_running(browser_pid):
		OS.kill(browser_pid)
