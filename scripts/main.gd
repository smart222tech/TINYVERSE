extends Node2D

const VIEW_W := 720.0
const VIEW_H := 1280.0
const LANES := [150.0, 360.0, 570.0]
const PLAYER_Y := 980.0
const RUN_SPEED := 470.0
const LEVEL_SECONDS := 32.0
const FOOD_INTERVAL := 0.82

var rng := RandomNumberGenerator.new()
var game_started := false
var game_over := false
var elapsed := 0.0
var spawn_clock := 0.0
var distance := 0.0
var lane := 1
var player_x := 360.0
var body_value := 50.0
var target_value := 30.0
var target_is_slim := true
var burgers := 0
var salads := 0
var foods: Array[Dictionary] = []
var feedback := ""
var feedback_timer := 0.0
var last_touch_x := -1.0
var ui: CanvasLayer
var hud_label: Label
var target_label: Label
var progress_bar: ProgressBar
var feedback_label: Label
var result_panel: PanelContainer
var result_label: Label
var start_panel: PanelContainer
var left_button: Button
var right_button: Button
var start_button: Button
var restart_button: Button

func _ready() -> void:
	rng.randomize()
	_build_ui()
	_show_start()
	queue_redraw()

func _process(delta: float) -> void:
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0:
			feedback = ""
			_update_ui()
	if game_started and not game_over:
		elapsed += delta
		distance = clampf(elapsed / LEVEL_SECONDS, 0.0, 1.0)
		spawn_clock += delta
		while spawn_clock >= FOOD_INTERVAL:
			spawn_clock -= FOOD_INTERVAL
			_spawn_food()
		for i in range(foods.size() - 1, -1, -1):
			var item := foods[i]
			item["y"] = float(item["y"]) + RUN_SPEED * delta
			var item_y := float(item["y"])
			if item_y >= PLAYER_Y - 30.0 and item_y <= PLAYER_Y + 42.0:
				if int(item["lane"]) == lane:
					_collect_food(item)
					foods.remove_at(i)
					continue
			if item_y > VIEW_H + 100.0:
				foods.remove_at(i)
			else:
				foods[i] = item
		player_x = lerpf(player_x, LANES[lane], minf(1.0, delta * 14.0))
		if elapsed >= LEVEL_SECONDS:
			_finish_level()
		_update_ui()
	queue_redraw()

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var title := Label.new()
	title.text = "FOOD DASH"
	title.position = Vector2(24, 26)
	title.size = Vector2(360, 58)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	title.add_theme_color_override("font_shadow_color", Color("#643c57"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	root.add_child(title)

	hud_label = Label.new()
	hud_label.position = Vector2(28, 92)
	hud_label.size = Vector2(664, 38)
	hud_label.add_theme_font_size_override("font_size", 20)
	hud_label.add_theme_color_override("font_color", Color("#ffffff"))
	root.add_child(hud_label)

	target_label = Label.new()
	target_label.position = Vector2(28, 140)
	target_label.size = Vector2(664, 42)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.add_theme_font_size_override("font_size", 23)
	target_label.add_theme_color_override("font_color", Color("#fff3b0"))
	root.add_child(target_label)

	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(28, 192)
	progress_bar.size = Vector2(664, 18)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	root.add_child(progress_bar)

	feedback_label = Label.new()
	feedback_label.position = Vector2(90, 825)
	feedback_label.size = Vector2(540, 58)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_color", Color("#ffffff"))
	feedback_label.add_theme_color_override("font_shadow_color", Color("#4d2c48"))
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 3)
	root.add_child(feedback_label)

	left_button = _make_button("◀  LEFT", Vector2(38, 1100), Vector2(300, 112), Color("#69c7f4"))
	left_button.pressed.connect(func(): _change_lane(-1))
	root.add_child(left_button)
	right_button = _make_button("RIGHT  ▶", Vector2(382, 1100), Vector2(300, 112), Color("#ff9bba"))
	right_button.pressed.connect(func(): _change_lane(1))
	root.add_child(right_button)

	start_panel = PanelContainer.new()
	start_panel.position = Vector2(70, 390)
	start_panel.size = Vector2(580, 390)
	start_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.12, 0.23, 0.96), 30))
	root.add_child(start_panel)
	var start_content := VBoxContainer.new()
	start_content.alignment = BoxContainer.ALIGNMENT_CENTER
	start_content.add_theme_constant_override("separation", 20)
	start_panel.add_child(start_content)
	var intro := Label.new()
	intro.text = "🍔  BURGER = BIGGER\n🥗  SALAD = SLIMMER\n\nCollect food and match the\ntarget shape at the finish!"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_size_override("font_size", 27)
	intro.add_theme_color_override("font_color", Color.WHITE)
	start_content.add_child(intro)
	start_button = Button.new()
	start_button.text = "START RUN"
	start_button.custom_minimum_size = Vector2(0, 82)
	start_button.add_theme_font_size_override("font_size", 30)
	start_button.add_theme_color_override("font_color", Color("#3d2940"))
	start_button.add_theme_stylebox_override("normal", _panel_style(Color("#ffe078"), 22))
	start_button.add_theme_stylebox_override("pressed", _panel_style(Color("#f5bd52"), 22))
	start_button.pressed.connect(_start_game)
	start_content.add_child(start_button)

	result_panel = PanelContainer.new()
	result_panel.position = Vector2(70, 390)
	result_panel.size = Vector2(580, 390)
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.12, 0.23, 0.97), 30))
	root.add_child(result_panel)
	var result_content := VBoxContainer.new()
	result_content.alignment = BoxContainer.ALIGNMENT_CENTER
	result_content.add_theme_constant_override("separation", 22)
	result_panel.add_child(result_content)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 29)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	result_content.add_child(result_label)
	restart_button = Button.new()
	restart_button.text = "PLAY AGAIN"
	restart_button.custom_minimum_size = Vector2(0, 82)
	restart_button.add_theme_font_size_override("font_size", 30)
	restart_button.add_theme_color_override("font_color", Color("#3d2940"))
	restart_button.add_theme_stylebox_override("normal", _panel_style(Color("#ffe078"), 22))
	restart_button.pressed.connect(_start_game)
	result_content.add_child(restart_button)
	result_panel.hide()
	_update_ui()

func _make_button(caption: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("#382a43"))
	button.add_theme_stylebox_override("normal", _panel_style(color, 25))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.14), 25))
	return button

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style

func _show_start() -> void:
	start_panel.show()
	result_panel.hide()
	left_button.disabled = true
	right_button.disabled = true

func _start_game() -> void:
	game_started = true
	game_over = false
	elapsed = 0.0
	spawn_clock = 0.0
	distance = 0.0
	lane = 1
	player_x = LANES[lane]
	body_value = 50.0
	burgers = 0
	salads = 0
	foods.clear()
	target_is_slim = rng.randf() < 0.5
	target_value = 28.0 if target_is_slim else 72.0
	start_panel.hide()
	result_panel.hide()
	left_button.disabled = false
	right_button.disabled = false
	feedback = "GO!"
	feedback_timer = 1.0
	_update_ui()
	queue_redraw()

func _change_lane(direction: int) -> void:
	if not game_started or game_over:
		return
	lane = clampi(lane + direction, 0, 2)

func _spawn_food() -> void:
	var food_lane := rng.randi_range(0, 2)
	var is_burger := rng.randf() < 0.5
	foods.append({
		"lane": food_lane,
		"y": -80.0,
		"type": "burger" if is_burger else "salad"
	})

func _collect_food(item: Dictionary) -> void:
	if item["type"] == "burger":
		burgers += 1
		body_value = clampf(body_value + 12.0, 0.0, 100.0)
		feedback = "+ SIZE  🍔"
	else:
		salads += 1
		body_value = clampf(body_value - 12.0, 0.0, 100.0)
		feedback = "SLIMMER  🥗"
	feedback_timer = 0.8
	_update_ui()

func _finish_level() -> void:
	game_over = true
	game_started = false
	left_button.disabled = true
	right_button.disabled = true
	var difference := absf(body_value - target_value)
	var won := difference <= 12.0
	var shape_text := "SLIM" if target_is_slim else "CURVY"
	if won:
		result_label.text = "🏆  YOU WIN!\n\nPerfect match!\nTarget: %s\nYour result: %d%%" % [shape_text, int(body_value)]
	else:
		result_label.text = "🙈  TRY AGAIN!\n\nTarget: %s (%d%%)\nYour result: %d%%\nYou were %d points away." % [shape_text, int(target_value), int(body_value), int(difference)]
	result_panel.show()
	_update_ui()

func _update_ui() -> void:
	if not is_instance_valid(hud_label):
		return
	hud_label.text = "🍔 %d     🥗 %d       BODY: %d%%" % [burgers, salads, int(body_value)]
	target_label.text = "FINISH GOAL:  %s  •  %d%%" % ["SLIM" if target_is_slim else "CURVY", int(target_value)]
	progress_bar.value = distance * 100.0
	feedback_label.text = feedback

func _input(event: InputEvent) -> void:
	if not game_started or game_over:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			last_touch_x = event.position.x
		elif last_touch_x >= 0.0:
			var dx := event.position.x - last_touch_x
			if absf(dx) > 45.0:
				_change_lane(1 if dx > 0.0 else -1)
			last_touch_x = -1.0
	elif event is InputEventMouseButton:
		if event.pressed:
			last_touch_x = event.position.x
		elif last_touch_x >= 0.0:
			var dx := event.position.x - last_touch_x
			if absf(dx) > 45.0:
				_change_lane(1 if dx > 0.0 else -1)
			last_touch_x = -1.0

func _draw() -> void:
	# Bright vertical runner world
	draw_rect(Rect2(0, 0, VIEW_W, VIEW_H), Color("#a6e8f2"))
	draw_circle(Vector2(610, 270), 92, Color("#fff1a8"))
	for i in range(6):
		var cloud_x := fposmod(float(i) * 151.0 + 40.0, VIEW_W)
		var cloud_y := 290.0 + float(i % 3) * 72.0
		draw_circle(Vector2(cloud_x, cloud_y), 30, Color(1, 1, 1, 0.55))
		draw_circle(Vector2(cloud_x + 30, cloud_y + 8), 25, Color(1, 1, 1, 0.55))
		draw_circle(Vector2(cloud_x - 25, cloud_y + 12), 22, Color(1, 1, 1, 0.55))
	# Side scenery
	draw_rect(Rect2(0, 390, 720, 890), Color("#8bd58d"))
	for y in range(430, 1250, 170):
		_draw_tree(28 + (y % 3) * 12, float(y))
		_draw_tree(690 - (y % 4) * 10, float(y + 55))
	# Three-lane running path
	var road := PackedVector2Array([
		Vector2(245, 255), Vector2(475, 255), Vector2(710, 1280), Vector2(10, 1280)
	])
	draw_colored_polygon(road, Color("#e8b5a1"))
	draw_polyline(PackedVector2Array([Vector2(245,255), Vector2(10,1280)]), Color("#fff0d5"), 8.0)
	draw_polyline(PackedVector2Array([Vector2(475,255), Vector2(710,1280)]), Color("#fff0d5"), 8.0)
	# Lane markings scroll down as the runner advances
	for k in range(2):
		var x_top := 245.0 + float(k + 1) * 76.7
		var x_bottom := 10.0 + float(k + 1) * 233.3
		for j in range(8):
			var y := fposmod(float(j) * 190.0 + elapsed * RUN_SPEED, 1120.0) + 260.0
			var t := (y - 255.0) / 1025.0
			var x := lerpf(x_top, x_bottom, t)
			var width := lerpf(3.0, 8.0, t)
			draw_line(Vector2(x, y), Vector2(x, y + lerpf(32.0, 90.0, t)), Color(1,1,1,0.55), width)
	# Food on the track
	for item in foods:
		var y := float(item["y"])
		var lane_index := int(item["lane"])
		var t := clampf((y - 255.0) / 1025.0, 0.0, 1.0)
		var x := lerpf(360.0 + (float(lane_index) - 1.0) * 76.7, LANES[lane_index], t)
		var scale := lerpf(0.48, 1.0, t)
		_draw_food(Vector2(x, y), str(item["type"]), scale)
	# Player shadow and runner
	if game_started or game_over:
		draw_ellipse(Vector2(player_x, PLAYER_Y + 62), Vector2(58, 17), Color(0,0,0,0.18))
		_draw_girl(Vector2(player_x, PLAYER_Y), body_value)
	else:
		_draw_girl(Vector2(360, PLAYER_Y), 50.0)
	# Finish line
	if game_started:
		var remaining := 1.0 - distance
		if remaining < 0.18:
			var alpha := (0.18 - remaining) / 0.18
			draw_rect(Rect2(20, 340, 680, 18), Color(1,1,1,0.85 * alpha))
			draw_rect(Rect2(20, 358, 680, 18), Color("#4c3d65"))
			draw_string(ThemeDB.fallback_font, Vector2(270, 330), "FINISH LINE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

func _draw_tree(x: float, y: float) -> void:
	draw_rect(Rect2(x - 7, y, 14, 48), Color("#986346"))
	draw_circle(Vector2(x, y - 8), 34, Color("#42a86e"))
	draw_circle(Vector2(x - 18, y + 4), 23, Color("#5cbd78"))
	draw_circle(Vector2(x + 20, y + 5), 24, Color("#35965f"))

func _draw_food(pos: Vector2, kind: String, scale: float) -> void:
	var s := scale
	draw_circle(pos + Vector2(0, 8*s), 39*s, Color(0,0,0,0.18))
	if kind == "burger":
		draw_rounded_rect(Rect2(pos.x - 34*s, pos.y - 7*s, 68*s, 20*s), 8*s, Color("#8b4b2d"))
		draw_rounded_rect(Rect2(pos.x - 36*s, pos.y - 19*s, 72*s, 19*s), 9*s, Color("#f5b94f"))
		draw_rounded_rect(Rect2(pos.x - 33*s, pos.y - 36*s, 66*s, 23*s), 18*s, Color("#e99a45"))
		for dot in [Vector2(-14,-27), Vector2(0,-30), Vector2(15,-25)]:
			draw_circle(pos + dot*s, 2.5*s, Color("#fff0bd"))
		draw_rect(Rect2(pos.x - 34*s, pos.y - 4*s, 68*s, 5*s), Color("#62a84f"))
	else:
		draw_circle(pos, 35*s, Color("#4a9b56"))
		draw_circle(pos + Vector2(-13,-7)*s, 19*s, Color("#a7df69"))
		draw_circle(pos + Vector2(13,-11)*s, 17*s, Color("#6ecb6b"))
		draw_circle(pos + Vector2(3,13)*s, 17*s, Color("#f1df87"))
		draw_line(pos + Vector2(-5,-22)*s, pos + Vector2(2,20)*s, Color("#fff7c4"), 4*s)

func _draw_girl(pos: Vector2, size_value: float) -> void:
	var fullness := lerpf(0.78, 1.34, size_value / 100.0)
	var bob := sin(elapsed * 11.0) * 5.0 if game_started else 0.0
	var p := pos + Vector2(0, bob)
	# legs
	draw_line(p + Vector2(-12*fullness, 35), p + Vector2(-23, 90), Color("#f3c19e"), 16)
	draw_line(p + Vector2(12*fullness, 35), p + Vector2(24, 90), Color("#f3c19e"), 16)
	draw_line(p + Vector2(-23, 90), p + Vector2(-35, 110), Color("#684c76"), 18)
	draw_line(p + Vector2(24, 90), p + Vector2(36, 110), Color("#684c76"), 18)
	# dress/body changes width with food
	draw_rounded_rect(Rect2(p.x - 28*fullness, p.y - 35, 56*fullness, 91), 23, Color("#f06f9a"))
	draw_rounded_rect(Rect2(p.x - 35*fullness, p.y + 20, 70*fullness, 16), 8, Color("#d95786"))
	# arms
	draw_line(p + Vector2(-25*fullness, -20), p + Vector2(-48*fullness, 17), Color("#f3c19e"), 13)
	draw_line(p + Vector2(25*fullness, -20), p + Vector2(48*fullness, 14), Color("#f3c19e"), 13)
	# neck and head
	draw_rect(Rect2(p.x - 9, p.y - 58, 18, 22), Color("#f3c19e"))
	draw_circle(p + Vector2(0, -88), 39, Color("#f3c19e"))
	# hair
	draw_circle(p + Vector2(-5, -111), 38, Color("#5a3549"))
	draw_circle(p + Vector2(0, -91), 34, Color("#f3c19e"))
	draw_arc(p + Vector2(0, -88), 38, PI, TAU, 24, Color("#5a3549"), 11)
	draw_circle(p + Vector2(-13, -91), 3.5, Color("#493341"))
	draw_circle(p + Vector2(13, -91), 3.5, Color("#493341"))
	draw_arc(p + Vector2(0, -77), 10, 0.2, PI - 0.2, 16, Color("#a64e68"), 3)
	draw_circle(p + Vector2(31, -110), 10, Color("#ffc7dc"))

func draw_rounded_rect(rect: Rect2, radius: float, color: Color) -> void:
	draw_rect(rect, color)
	draw_circle(rect.position + Vector2(radius, radius), radius, color)
	draw_circle(rect.position + Vector2(rect.size.x-radius, radius), radius, color)
	draw_circle(rect.position + Vector2(radius, rect.size.y-radius), radius, color)
	draw_circle(rect.position + rect.size - Vector2(radius, radius), radius, color)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle)*radius.x, sin(angle)*radius.y))
	draw_colored_polygon(points, color)
