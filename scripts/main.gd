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
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}
var particles: Array[Dictionary] = []
var character_index := 0
var character_names := ["GIRL", "BOY", "BUNNY", "PANDA", "MONKEY", "FOX"]
var character_foods := [["burger","salad","apple","strawberry"],["burger","salad","apple","strawberry"],["carrot","lettuce","apple"],["bamboo","apple"],["banana","mango","strawberry"],["berry","apple","carrot"]]
var character_button: Button
var music_button: Button
var settings_button: Button
var settings_panel: PanelContainer
var music_slider: HSlider
var sfx_slider: HSlider
var music_enabled := true

func _ready() -> void:
	rng.randomize()
	_build_audio()
	_build_ui()
	_show_start()
	queue_redraw()

func _process(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle["life"] = float(particle["life"]) - delta
		var particle_pos: Vector2 = particle["pos"]
		var particle_velocity: Vector2 = particle["velocity"]
		particle["pos"] = particle_pos + particle_velocity * delta
		particle["velocity"] = particle_velocity + Vector2(0, 360.0 * delta)
		if float(particle["life"]) <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = particle
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
	title.text = "ASMR FOOD RUN"
	title.position = Vector2(24, 26)
	title.size = Vector2(500, 58)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#ffffff"))
	title.add_theme_color_override("font_shadow_color", Color("#643c57"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	root.add_child(title)
	music_button = _make_button("♫", Vector2(620, 24), Vector2(78, 58), Color("#ffe078"))
	music_button.pressed.connect(_toggle_music)
	root.add_child(music_button)
	settings_button = _make_button("⚙", Vector2(540, 24), Vector2(70, 58), Color("#c8b7f2"))
	settings_button.pressed.connect(_toggle_settings)
	root.add_child(settings_button)

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
	start_panel.position = Vector2(70, 340)
	start_panel.size = Vector2(580, 500)
	start_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.12, 0.23, 0.96), 30))
	root.add_child(start_panel)
	var start_content := VBoxContainer.new()
	start_content.alignment = BoxContainer.ALIGNMENT_CENTER
	start_content.add_theme_constant_override("separation", 20)
	start_panel.add_child(start_content)
	var intro := Label.new()
	intro.text = "CHOOSE YOUR CHARACTER!\nEach hero gets their own food."
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_font_size_override("font_size", 27)
	intro.add_theme_color_override("font_color", Color.WHITE)
	start_content.add_child(intro)
	character_button = Button.new()
	character_button.custom_minimum_size = Vector2(0, 70)
	character_button.text = "GIRL"
	character_button.add_theme_font_size_override("font_size", 25)
	character_button.pressed.connect(_next_character)
	start_content.add_child(character_button)
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

	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(80, 410)
	settings_panel.size = Vector2(560, 420)
	settings_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.15, 0.12, 0.23, 0.98), 26))
	root.add_child(settings_panel)
	var settings_box := VBoxContainer.new()
	settings_box.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_box.add_theme_constant_override("separation", 12)
	settings_panel.add_child(settings_box)
	var settings_title := Label.new()
	settings_title.text = "SOUND SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 27)
	settings_title.add_theme_color_override("font_color", Color.WHITE)
	settings_box.add_child(settings_title)
	var music_text := Label.new()
	music_text.text = "MUSIC VOLUME"
	music_text.add_theme_color_override("font_color", Color.WHITE)
	settings_box.add_child(music_text)
	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 100
	music_slider.value = 35
	music_slider.value_changed.connect(_set_music_volume)
	settings_box.add_child(music_slider)
	var sfx_text := Label.new()
	sfx_text.text = "FOOD / ACTION SOUNDS"
	sfx_text.add_theme_color_override("font_color", Color.WHITE)
	settings_box.add_child(sfx_text)
	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 100
	sfx_slider.value = 85
	sfx_slider.value_changed.connect(_set_sfx_volume)
	settings_box.add_child(sfx_slider)
	var close_settings := _make_button("CLOSE", Vector2.ZERO, Vector2(0, 62), Color("#ffe078"))
	close_settings.pressed.connect(_toggle_settings)
	settings_box.add_child(close_settings)
	settings_panel.hide()
	_update_ui()

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	_play_sfx("lane")

func _set_music_volume(value: float) -> void:
	music_player.volume_db = linear_to_db(maxf(value / 100.0, 0.001))

func _set_sfx_volume(value: float) -> void:
	sfx_player.volume_db = linear_to_db(maxf(value / 100.0, 0.001))

func _toggle_music() -> void:
	music_enabled = not music_enabled
	if music_enabled:
		music_player.play()
		music_button.text = "♫"
	else:
		music_player.stop()
		music_button.text = "♪"
	_play_sfx("lane")

func _next_character() -> void:
	character_index = (character_index + 1) % character_names.size()
	character_button.text = "◀  " + character_names[character_index] + "  ▶"
	_play_sfx("lane")
	queue_redraw()

func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "ArcadeMusic"
	music_player.volume_db = -19.0
	add_child(music_player)
	music_player.stream = _make_music_loop()
	music_player.play()

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SoundEffects"
	sfx_player.volume_db = -3.0
	add_child(sfx_player)
	sfx_streams["burger"] = _make_effect([220.0, 330.0, 440.0], 0.075, 0.42)
	sfx_streams["salad"] = _make_effect([587.33, 783.99, 1046.5], 0.065, 0.34)
	sfx_streams["lane"] = _make_effect([260.0, 210.0], 0.045, 0.13)
	sfx_streams["start"] = _make_effect([392.0, 523.25, 659.25], 0.10, 0.28)
	sfx_streams["win"] = _make_effect([523.25, 659.25, 783.99, 1046.5], 0.13, 0.34)
	sfx_streams["lose"] = _make_effect([392.0, 329.63, 261.63], 0.16, 0.25)

func _make_music_loop() -> AudioStreamWAV:
	const RATE := 22050
	const DURATION := 8.0
	var frames := int(RATE * DURATION)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var melody := [
		659.25, 783.99, 880.0, 783.99, 659.25, 523.25, 587.33, 659.25,
		783.99, 880.0, 987.77, 880.0, 783.99, 659.25, 587.33, 523.25,
		659.25, 783.99, 880.0, 1046.5, 987.77, 880.0, 783.99, 659.25,
		587.33, 659.25, 783.99, 880.0, 783.99, 659.25, 587.33, 523.25
	]
	var bass := [130.81, 164.81, 110.0, 146.83]
	for i in range(frames):
		var t := float(i) / float(RATE)
		var step := int(t / 0.25) % melody.size()
		var local_step := fposmod(t, 0.25)
		var lead_env := minf(1.0, local_step * 45.0) * pow(1.0 - local_step / 0.25, 0.65)
		var lead_phase := TAU * float(melody[step]) * t
		var lead := (sin(lead_phase) * 0.78 + sin(lead_phase * 2.0) * 0.22) * 0.105 * lead_env
		var bass_note := float(bass[int(t / 2.0) % bass.size()])
		var beat_phase := fposmod(t, 0.5)
		var bass_env := 0.35 + 0.65 * (1.0 - beat_phase / 0.5)
		var bass_tone := sin(TAU * bass_note * t) * 0.075 * bass_env
		var kick := 0.0
		if beat_phase < 0.12:
			var kick_env := 1.0 - beat_phase / 0.12
			var kick_frequency := 105.0 - 45.0 * (beat_phase / 0.12)
			kick = sin(TAU * kick_frequency * t) * 0.12 * kick_env
		var sample_value := clampf(lead + bass_tone + kick, -0.85, 0.85)
		data.encode_s16(i * 2, int(sample_value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream

func _make_effect(notes: Array, note_seconds: float, volume: float) -> AudioStreamWAV:
	const RATE := 22050
	var frames := int(float(RATE) * note_seconds * float(notes.size()))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(RATE)
		var note_index := mini(int(t / note_seconds), notes.size() - 1)
		var local_time := fposmod(t, note_seconds)
		var envelope := minf(1.0, local_time * 50.0) * (1.0 - local_time / note_seconds)
		var frequency := float(notes[note_index])
		var phase := TAU * frequency * t
		var tone := sin(phase) * 0.82 + sin(phase * 2.02) * 0.18
		data.encode_s16(i * 2, int(clampf(tone * envelope * volume, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream

func _play_sfx(effect_name: String) -> void:
	if not is_instance_valid(sfx_player) or not sfx_streams.has(effect_name):
		return
	sfx_player.stream = sfx_streams[effect_name]
	sfx_player.play()

func _spawn_particles(color: Color, amount: int) -> void:
	for i in range(amount):
		var angle := rng.randf_range(-PI, PI)
		var speed := rng.randf_range(100.0, 330.0)
		var life := rng.randf_range(0.32, 0.72)
		particles.append({
			"pos": Vector2(player_x, PLAYER_Y - 65.0),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"life": life,
			"max_life": life,
			"color": color,
			"size": rng.randf_range(4.0, 9.0)
		})

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
	settings_panel.hide()
	result_panel.hide()
	left_button.disabled = true
	right_button.disabled = true

func _start_game() -> void:
	_play_sfx("start")
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
	var next_lane := clampi(lane + direction, 0, 2)
	if next_lane != lane:
		lane = next_lane
		_play_sfx("lane")

func _spawn_food() -> void:
	var food_lane := rng.randi_range(0, 2)
	var choices: Array = character_foods[character_index]
	var food_type: String = str(choices[rng.randi_range(0, choices.size() - 1)])
	foods.append({"lane": food_lane, "y": -80.0, "type": food_type})

func _collect_food(item: Dictionary) -> void:
	var kind := str(item["type"])
	if kind in ["burger", "pizza"]:
		_play_sfx("burger")
		burgers += 1
		body_value = clampf(body_value + 8.0, 0.0, 100.0)
		feedback = "YUMMY!  " + _food_icon(kind)
	else:
		_play_sfx("salad")
		salads += 1
		feedback = "CRUNCH!  " + _food_icon(kind)
	_spawn_particles(Color("#ffbd55") if kind in ["burger", "pizza", "banana", "mango"] else Color("#8fe58b"), 18)
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
		_play_sfx("win")
		_spawn_particles(Color("#ffe078"), 48)
		result_label.text = "🏆  YOU WIN!\n\nPerfect match!\nTarget: %s\nYour result: %d%%" % [shape_text, int(body_value)]
	else:
		_play_sfx("lose")
		result_label.text = "🙈  TRY AGAIN!\n\nTarget: %s (%d%%)\nYour result: %d%%\nYou were %d points away." % [shape_text, int(target_value), int(body_value), int(difference)]
	result_panel.show()
	_update_ui()

func _food_icon(kind: String) -> String:
	var icons := {"burger":"🍔","salad":"🥗","apple":"🍎","strawberry":"🍓","pizza":"🍕","carrot":"🥕","lettuce":"🥬","bamboo":"🎋","banana":"🍌","mango":"🥭","berry":"🫐"}
	return str(icons.get(kind, "✨"))

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
			var dx: float = float(event.position.x) - last_touch_x
			if absf(dx) > 45.0:
				_change_lane(1 if dx > 0.0 else -1)
			last_touch_x = -1.0
	elif event is InputEventMouseButton:
		if event.pressed:
			last_touch_x = event.position.x
		elif last_touch_x >= 0.0:
			var dx: float = float(event.position.x) - last_touch_x
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
	# Collection sparkles
	for particle in particles:
		var particle_color: Color = particle["color"]
		var particle_pos: Vector2 = particle["pos"]
		particle_color.a *= clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		draw_circle(particle_pos, float(particle["size"]), particle_color)
	# Player shadow and runner
	if game_started or game_over:
		draw_ellipse(Vector2(player_x, PLAYER_Y + 62), Vector2(58, 17), Color(0,0,0,0.18))
		_draw_selected_character(Vector2(player_x, PLAYER_Y), body_value)
	else:
		_draw_selected_character(Vector2(360, PLAYER_Y), 50.0)
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
	elif kind in ["salad", "lettuce", "bamboo"]:
		draw_circle(pos, 35*s, Color("#4a9b56"))
		draw_circle(pos + Vector2(-13,-7)*s, 19*s, Color("#a7df69"))
		draw_circle(pos + Vector2(13,-11)*s, 17*s, Color("#6ecb6b"))
		draw_circle(pos + Vector2(3,13)*s, 17*s, Color("#f1df87"))
		if kind == "bamboo":
			draw_line(pos + Vector2(-12,24)*s, pos + Vector2(10,-28)*s, Color("#b5dc65"), 8*s)
	elif kind in ["carrot", "banana", "mango"]:
		var food_color := Color("#f28b35") if kind == "carrot" else (Color("#ffd84d") if kind == "banana" else Color("#f6a33b"))
		draw_circle(pos, 30*s, food_color)
		if kind == "carrot":
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-18,-20)*s, pos + Vector2(18,-20)*s, pos + Vector2(0,35)*s]), food_color)
	elif kind in ["apple", "strawberry", "berry"]:
		draw_circle(pos, 29*s, Color("#ed5263") if kind != "berry" else Color("#6652b8"))
		draw_line(pos + Vector2(0,-25)*s, pos + Vector2(8,-38)*s, Color("#5da85a"), 5*s)
	elif kind == "pizza":
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-34,-28)*s, pos + Vector2(36,-20)*s, pos + Vector2(0,38)*s]), Color("#f5c45e"))
		draw_circle(pos + Vector2(-10,-9)*s, 6*s, Color("#e65e48"))
		draw_circle(pos + Vector2(12,-4)*s, 6*s, Color("#e65e48"))

func _draw_selected_character(pos: Vector2, size_value: float) -> void:
	if character_index < 2:
		_draw_girl(pos, size_value)
		return
	var bob := sin(elapsed * 11.0) * 5.0 if game_started else 0.0
	var p := pos + Vector2(0, bob)
	var fur := Color("#f2e5ef")
	if character_index == 3:
		fur = Color("#eeeeee")
	elif character_index == 4:
		fur = Color("#b97845")
	elif character_index == 5:
		fur = Color("#ed8a3b")
	draw_line(p + Vector2(-15,30), p + Vector2(-24,86), fur, 16)
	draw_line(p + Vector2(15,30), p + Vector2(24,86), fur, 16)
	draw_circle(p + Vector2(0,-28), 48, fur)
	draw_circle(p + Vector2(-30,-68), 19, fur)
	draw_circle(p + Vector2(30,-68), 19, fur)
	if character_index == 3:
		draw_circle(p + Vector2(-17,-30), 13, Color("#25252b"))
		draw_circle(p + Vector2(17,-30), 13, Color("#25252b"))
	else:
		draw_circle(p + Vector2(-16,-30), 4, Color("#302b35"))
		draw_circle(p + Vector2(16,-30), 4, Color("#302b35"))
	draw_circle(p + Vector2(0,-14), 7, Color("#4b3540"))

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
