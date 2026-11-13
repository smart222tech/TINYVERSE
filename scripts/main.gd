extends Node2D

const SAVE_PATH := "user://tinyverse_progress.cfg"
const LANGUAGES := ["EN", "DE", "RU"]
const WORLD_SIZE := Vector2(1280, 720)
const PLAYER_SPEED := 245.0
const RESOURCE_RESPAWN := 18.0

var language := "RU"
var stars := 12
var eggs := 1
var creature_level := 1
var has_pet := false
var pet_hunger := 0
var player_pos := Vector2(625, 505)
var move_vector := Vector2.ZERO
var mood_time := 0.0
var message := ""
var message_timer := 0.0
var flowers_collected := 0
var crystals_collected := 0
var quest_index := 0
var quest_progress := 0
var mini_game_active := false
var mini_game_time := 0.0
var mini_game_score := 0
var mini_target := Vector2(900, 340)
var resource_nodes: Array[Dictionary] = []
var ui: CanvasLayer
var stats_label: Label
var quest_label: Label
var message_label: Label
var action_label: Label
var language_button: OptionButton
var move_buttons: Dictionary = {}
var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

var words := {
	"EN": {
		"subtitle":"CREATE • EXPLORE • GROW", "stars":"Stars", "eggs":"Eggs", "level":"Lv.",
		"quest":"TODAY'S QUEST", "move":"MOVE", "collect":"COLLECT", "care":"CARE", "hatch":"HATCH", "game":"STAR CATCH",
		"welcome":"Welcome home! Explore your island and find something magical.",
		"flower":"Lovely! You found a magic flower.", "crystal":"A sparkling crystal! Great find.",
		"nothing":"Nothing nearby. Walk closer to a flower or crystal.",
		"quest_done":"Quest complete! You earned 5 stars and an egg!",
		"quest_flowers":"Collect 5 flowers", "quest_crystals":"Find 3 crystals", "quest_care":"Give your friend 3 treats",
		"need_pet":"Hatch an egg first to meet your new friend!", "fed":"Mimo is happy! Your friend gained experience.",
		"no_stars":"You need a star for a treat. Complete a quest!",
		"hatched":"Pop! Meet Mimo, your new magical friend!",
		"no_eggs":"No eggs yet. Finish a quest to earn one.",
		"mini_start":"Catch as many stars as you can in 12 seconds! Tap the glowing star!",
		"mini_win":"Amazing! You caught enough stars. +8 stars!",
		"mini_end":"Time is up! Try again and beat your score.",
		"reset":"Progress reset.", "pet":"MIMO", "hunger":"Treats given"
	},
	"DE": {
		"subtitle":"ERSCHAFFEN • ENTDECKEN • WACHSEN", "stars":"Sterne", "eggs":"Eier", "level":"St.",
		"quest":"TAGESAUFGABE", "move":"BEWEGEN", "collect":"SAMMELN", "care":"PFLEGEN", "hatch":"AUSBRÜTEN", "game":"STERNE FANGEN",
		"welcome":"Willkommen zu Hause! Erkunde deine Insel und entdecke Magie.",
		"flower":"Wunderbar! Du hast eine Zauberblume gefunden.", "crystal":"Ein funkelnder Kristall! Gut gemacht.",
		"nothing":"Hier ist nichts. Geh näher an eine Blume oder einen Kristall.",
		"quest_done":"Aufgabe geschafft! Du bekommst 5 Sterne und ein Ei!",
		"quest_flowers":"Sammle 5 Blumen", "quest_crystals":"Finde 3 Kristalle", "quest_care":"Gib deinem Freund 3 Leckerli",
		"need_pet":"Brüte zuerst ein Ei aus und lerne deinen Freund kennen!", "fed":"Mimo freut sich! Dein Freund hat Erfahrung gesammelt.",
		"no_stars":"Du brauchst einen Stern für ein Leckerli. Erledige eine Aufgabe!",
		"hatched":"Plopp! Das ist Mimo, dein neuer Zauberfreund!",
		"no_eggs":"Keine Eier mehr. Erledige eine Aufgabe, um eins zu verdienen.",
		"mini_start":"Fange in 12 Sekunden so viele Sterne wie möglich! Tippe auf den leuchtenden Stern!",
		"mini_win":"Fantastisch! Du bekommst 8 Sterne!", "mini_end":"Die Zeit ist um! Versuch es noch einmal.",
		"reset":"Fortschritt zurückgesetzt.", "pet":"MIMO", "hunger":"Gefütterte Leckerli"
	},
	"RU": {
		"subtitle":"СОЗДАВАЙ • ИССЛЕДУЙ • РАСТИ", "stars":"Звёзды", "eggs":"Яйца", "level":"Ур.",
		"quest":"ЗАДАНИЕ ДНЯ", "move":"ДВИЖЕНИЕ", "collect":"СОБРАТЬ", "care":"УХОД", "hatch":"ВЫЛУПИТЬ", "game":"ЛОВИ ЗВЁЗДЫ",
		"welcome":"Добро пожаловать домой! Исследуй остров и найди волшебство.",
		"flower":"Здорово! Ты нашёл волшебный цветок.", "crystal":"Сверкающий кристалл! Отличная находка.",
		"nothing":"Рядом ничего нет. Подойди ближе к цветку или кристаллу.",
		"quest_done":"Задание выполнено! Ты получил 5 звёзд и яйцо!",
		"quest_flowers":"Собери 5 цветов", "quest_crystals":"Найди 3 кристалла", "quest_care":"Угости друга 3 раза",
		"need_pet":"Сначала вылупи яйцо и познакомься с питомцем!", "fed":"Мимо счастлив! Твой друг стал опытнее.",
		"no_stars":"Нужна звезда для угощения. Выполни задание!",
		"hatched":"Пуф! Знакомься — это Мимо, твой волшебный друг!",
		"no_eggs":"Яиц пока нет. Выполни задание, чтобы получить яйцо.",
		"mini_start":"За 12 секунд поймай как можно больше звёзд! Нажимай на сияющую звезду!",
		"mini_win":"Потрясающе! Ты получил 8 звёзд!", "mini_end":"Время вышло! Попробуй ещё раз.",
		"reset":"Прогресс сброшен.", "pet":"МИМО", "hunger":"Угощений дано"
	}
}

func _ready() -> void:
	_init_resources()
	load_progress()
	_build_audio()
	build_ui()
	show_message(tr_word("welcome"), 5.0)
	queue_redraw()

func _process(delta: float) -> void:
	mood_time += delta
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message = ""
			update_ui()
	if mini_game_active:
		mini_game_time -= delta
		if mini_game_time <= 0.0:
			_finish_mini_game()
	for node in resource_nodes:
		if not node["active"]:
			node["timer"] = maxf(0.0, float(node["timer"]) - delta)
			if node["timer"] <= 0.0:
				node["active"] = true
	var direction := move_vector
	if direction.length() > 1.0:
		direction = direction.normalized()
	if not mini_game_active:
		player_pos += direction * PLAYER_SPEED * delta
		player_pos.x = clampf(player_pos.x, 115.0, 1165.0)
		player_pos.y = clampf(player_pos.y, 355.0, 610.0)
	queue_redraw()

func _init_resources() -> void:
	resource_nodes = [
		{"kind":"flower","pos":Vector2(300,490),"active":true,"timer":0.0},
		{"kind":"flower","pos":Vector2(410,555),"active":true,"timer":0.0},
		{"kind":"flower","pos":Vector2(825,520),"active":true,"timer":0.0},
		{"kind":"flower","pos":Vector2(1010,560),"active":true,"timer":0.0},
		{"kind":"flower","pos":Vector2(690,590),"active":true,"timer":0.0},
		{"kind":"flower","pos":Vector2(205,555),"active":true,"timer":0.0},
		{"kind":"crystal","pos":Vector2(180,445),"active":true,"timer":0.0},
		{"kind":"crystal","pos":Vector2(1080,475),"active":true,"timer":0.0},
		{"kind":"crystal","pos":Vector2(900,600),"active":true,"timer":0.0},
		{"kind":"crystal","pos":Vector2(520,585),"active":true,"timer":0.0}
	]

func tr_word(key: String) -> String:
	return str(words.get(language, words["EN"]).get(key, key))

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var header := PanelContainer.new()
	header.position = Vector2(22, 16)
	header.size = Vector2(1236, 88)
	header.add_theme_stylebox_override("panel", _panel(Color(0.08,0.16,0.29,0.91), 22))
	root.add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	header.add_child(row)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(brand)
	var title := Label.new()
	title.text = "TINYVERSE"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#fff1bd"))
	brand.add_child(title)
	var subtitle := Label.new()
	subtitle.text = tr_word("subtitle")
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#b9d9ff"))
	brand.add_child(subtitle)
	stats_label = Label.new()
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(stats_label)
	language_button = OptionButton.new()
	language_button.add_item("English")
	language_button.add_item("Deutsch")
	language_button.add_item("Русский")
	language_button.item_selected.connect(_on_language_selected)
	row.add_child(language_button)

	var quest_panel := PanelContainer.new()
	quest_panel.position = Vector2(28, 120)
	quest_panel.size = Vector2(340, 72)
	quest_panel.add_theme_stylebox_override("panel", _panel(Color(0.12,0.24,0.35,0.88), 18))
	root.add_child(quest_panel)
	quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 17)
	quest_label.add_theme_color_override("font_color", Color("#fff4cb"))
	quest_panel.add_child(quest_label)

	message_label = Label.new()
	message_label.position = Vector2(330, 185)
	message_label.size = Vector2(620, 58)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_label.add_theme_color_override("font_color", Color("#fff7d6"))
	message_label.add_theme_color_override("font_shadow_color", Color("#18324b"))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(message_label)

	_add_direction_button(root, "up", Vector2(78, 548), "▲", Vector2(64,54))
	_add_direction_button(root, "left", Vector2(12, 605), "◀", Vector2(64,54))
	_add_direction_button(root, "down", Vector2(78, 605), "▼", Vector2(64,54))
	_add_direction_button(root, "right", Vector2(144, 605), "▶", Vector2(64,54))

	var collect_btn := _make_button(tr_word("collect"), Color("#ffc66d"), Vector2(190,58))
	collect_btn.position = Vector2(900, 635)
	collect_btn.pressed.connect(_on_collect)
	root.add_child(collect_btn)
	var care_btn := _make_button(tr_word("care"), Color("#b7a1ff"), Vector2(150,58))
	care_btn.position = Vector2(1098, 635)
	care_btn.pressed.connect(_on_care)
	root.add_child(care_btn)
	var hatch_btn := _make_button(tr_word("hatch"), Color("#ff9fbd"), Vector2(150,58))
	hatch_btn.position = Vector2(1098, 565)
	hatch_btn.pressed.connect(_on_hatch)
	root.add_child(hatch_btn)
	var game_btn := _make_button(tr_word("game"), Color("#85d9ce"), Vector2(190,58))
	game_btn.position = Vector2(900, 565)
	game_btn.pressed.connect(_start_mini_game)
	root.add_child(game_btn)
	update_ui()

func _add_direction_button(root: Control, direction: String, pos: Vector2, caption: String, size: Vector2) -> void:
	var button := _make_button(caption, Color("#e7f2ff"), size)
	button.position = pos
	button.button_down.connect(func(): _set_direction(direction, true))
	button.button_up.connect(func(): _set_direction(direction, false))
	root.add_child(button)
	move_buttons[direction] = button

func _set_direction(direction: String, pressed: bool) -> void:
	match direction:
		"up": move_vector.y = -1.0 if pressed else 0.0
		"down": move_vector.y = 1.0 if pressed else 0.0
		"left": move_vector.x = -1.0 if pressed else 0.0
		"right": move_vector.x = 1.0 if pressed else 0.0

func _make_button(caption: String, color: Color, size: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = size
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#25314a"))
	button.add_theme_stylebox_override("normal", _panel(color, 17))
	button.add_theme_stylebox_override("hover", _panel(color.lightened(0.1), 17))
	button.add_theme_stylebox_override("pressed", _panel(color.darkened(0.12), 17))
	return button

func _panel(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func update_ui() -> void:
	if not is_instance_valid(stats_label):
		return
	stats_label.text = "★ %d %s    ◇ %d %s    %s %d" % [stars, tr_word("stars"), eggs, tr_word("eggs"), tr_word("level"), creature_level]
	quest_label.text = "%s\n%s  %d/%d" % [tr_word("quest"), _quest_text(), quest_progress, _quest_goal()]
	message_label.text = message
	language_button.select(LANGUAGES.find(language))
	for child in ui.get_children():
		pass

func _quest_text() -> String:
	match quest_index:
		0: return tr_word("quest_flowers")
		1: return tr_word("quest_crystals")
		_: return tr_word("quest_care")

func _quest_goal() -> int:
	return 5 if quest_index == 0 else (3 if quest_index == 1 else 3)

func _on_language_selected(index: int) -> void:
	language = LANGUAGES[clampi(index, 0, 2)]
	update_ui()
	save_progress()

func _on_collect() -> void:
	if mini_game_active:
		return
	var nearest_index := -1
	var nearest_distance := 100000.0
	for i in range(resource_nodes.size()):
		var node: Dictionary = resource_nodes[i]
		if not node["active"]:
			continue
		var distance: float = player_pos.distance_to(node["pos"])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i
	if nearest_index == -1 or nearest_distance > 105.0:
		show_message(tr_word("nothing"))
		_play_sfx(190.0, 0.10)
		return
	var picked: Dictionary = resource_nodes[nearest_index]
	picked["active"] = false
	picked["timer"] = RESOURCE_RESPAWN
	resource_nodes[nearest_index] = picked
	if picked["kind"] == "flower":
		flowers_collected += 1
		stars += 1
		show_message(tr_word("flower"))
		_play_sfx(660.0, 0.14)
		if quest_index == 0:
			_add_quest_progress()
	else:
		crystals_collected += 1
		stars += 2
		show_message(tr_word("crystal"))
		_play_sfx(880.0, 0.18)
		if quest_index == 1:
			_add_quest_progress()
	save_progress()
	update_ui()

func _add_quest_progress() -> void:
	quest_progress += 1
	if quest_progress >= _quest_goal():
		quest_index = (quest_index + 1) % 3
		quest_progress = 0
		stars += 5
		eggs += 1
		show_message(tr_word("quest_done"), 4.0)
		_play_sfx(990.0, 0.28)
	update_ui()

func _on_care() -> void:
	if not has_pet:
		show_message(tr_word("need_pet"))
		return
	if stars < 1:
		show_message(tr_word("no_stars"))
		return
	stars -= 1
	pet_hunger += 1
	creature_level += 1
	show_message(tr_word("fed"))
	_play_sfx(740.0, 0.2)
	if quest_index == 2:
		_add_quest_progress()
	save_progress()
	update_ui()

func _on_hatch() -> void:
	if has_pet:
		show_message(tr_word("hatched"))
		return
	if eggs <= 0:
		show_message(tr_word("no_eggs"))
		return
	eggs -= 1
	has_pet = true
	creature_level = 1
	show_message(tr_word("hatched"), 4.0)
	_play_sfx(520.0, 0.12)
	save_progress()
	update_ui()

func _start_mini_game() -> void:
	if mini_game_active:
		return
	mini_game_active = true
	mini_game_time = 12.0
	mini_game_score = 0
	_move_mini_target()
	show_message(tr_word("mini_start"), 4.0)
	_play_sfx(520.0, 0.12)

func _move_mini_target() -> void:
	mini_target = Vector2(randf_range(240.0, 1080.0), randf_range(280.0, 550.0))

func _finish_mini_game() -> void:
	mini_game_active = false
	if mini_game_score >= 5:
		stars += 8
		show_message(tr_word("mini_win"), 4.0)
		_play_sfx(1040.0, 0.3)
	else:
		show_message(tr_word("mini_end"), 4.0)
		_play_sfx(260.0, 0.18)
	save_progress()
	update_ui()

func _input(event: InputEvent) -> void:
	if not mini_game_active:
		return
	var point := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		point = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		point = event.position
		pressed = event.pressed
	if pressed and point.distance_to(mini_target) < 90.0:
		mini_game_score += 1
		_play_sfx(820.0 + mini_game_score * 25.0, 0.08)
		_move_mini_target()
		show_message("%d / 5" % mini_game_score, 0.8)

func show_message(value: String, duration: float = 2.8) -> void:
	message = value
	message_timer = duration
	update_ui()

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "stars", stars)
	cfg.set_value("game", "eggs", eggs)
	cfg.set_value("game", "creature_level", creature_level)
	cfg.set_value("game", "has_pet", has_pet)
	cfg.set_value("game", "pet_hunger", pet_hunger)
	cfg.set_value("game", "flowers_collected", flowers_collected)
	cfg.set_value("game", "crystals_collected", crystals_collected)
	cfg.set_value("game", "quest_index", quest_index)
	cfg.set_value("game", "quest_progress", quest_progress)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		language = str(cfg.get_value("game", "language", "RU"))
		stars = int(cfg.get_value("game", "stars", 12))
		eggs = int(cfg.get_value("game", "eggs", 1))
		creature_level = int(cfg.get_value("game", "creature_level", 1))
		has_pet = bool(cfg.get_value("game", "has_pet", false))
		pet_hunger = int(cfg.get_value("game", "pet_hunger", 0))
		flowers_collected = int(cfg.get_value("game", "flowers_collected", 0))
		crystals_collected = int(cfg.get_value("game", "crystals_collected", 0))
		quest_index = int(cfg.get_value("game", "quest_index", 0))
		quest_progress = int(cfg.get_value("game", "quest_progress", 0))
	language = language if LANGUAGES.has(language) else "EN"
	quest_index = clampi(quest_index, 0, 2)

func _build_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -5.0
	add_child(sfx_player)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -24.0
	add_child(music_player)
	var music := AudioStreamWAV.new()
	music.mix_rate = 22050
	music.format = AudioStreamWAV.FORMAT_16_BITS
	music.stereo = false
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	var samples := PackedByteArray()
	var melody := [261.63,329.63,392.0,329.63,293.66,349.23,440.0,349.23]
	var sample_count := 22050 * 8
	samples.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / 22050.0
		var note := melody[int(t) % melody.size()]
		var envelope := 0.5 + 0.5 * sin(PI * fposmod(t, 1.0))
		var value := sin(TAU * note * t) * 0.11 * envelope + sin(TAU * note * 0.5 * t) * 0.035
		samples.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	music.data = samples
	music_player.stream = music
	music_player.play()

func _play_sfx(frequency: float, duration: float) -> void:
	if not is_instance_valid(sfx_player):
		return
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 22050
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	var count := int(22050.0 * duration)
	var samples := PackedByteArray()
	samples.resize(count * 2)
	for i in range(count):
		var t := float(i) / 22050.0
		var envelope := 1.0 - float(i) / maxf(1.0, float(count))
		var value := sin(TAU * frequency * t) * 0.28 * envelope
		samples.encode_s16(i * 2, int(value * 32767.0))
	stream.data = samples
	sfx_player.stream = stream
	sfx_player.play()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#8fd8ff"))
	draw_circle(Vector2(1080,165), 58, Color("#fff1a8"))
	for cloud in [Vector2(185,190),Vector2(760,170),Vector2(440,275)]:
		draw_circle(cloud,27,Color.WHITE)
		draw_circle(cloud+Vector2(28,5),34,Color.WHITE)
		draw_circle(cloud+Vector2(60,0),24,Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(0,420),Vector2(0,340),Vector2(170,280),Vector2(340,355),Vector2(520,285),Vector2(720,370),Vector2(930,290),Vector2(1280,370),Vector2(1280,520)]),Color("#83cda8"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,470),Vector2(180,385),Vector2(360,430),Vector2(540,350),Vector2(760,430),Vector2(1010,350),Vector2(1280,430),Vector2(1280,560)]),Color("#63b98f"))
	draw_rect(Rect2(0,470,1280,250),Color("#48b9d0"))
	for i in range(12):
		var x := float(i)*125.0+fposmod(mood_time*18.0,125.0)
		draw_arc(Vector2(x,555+sin(float(i))*42.0),20,0.2,2.7,20,Color(0.8,0.98,1.0,0.45),3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(110,510),Vector2(230,430),Vector2(430,390),Vector2(690,405),Vector2(930,445),Vector2(1110,520),Vector2(1030,650),Vector2(260,650)]),Color("#e7c987"))
	draw_colored_polygon(PackedVector2Array([Vector2(180,500),Vector2(270,445),Vector2(450,420),Vector2(690,430),Vector2(920,465),Vector2(1060,525),Vector2(1000,620),Vector2(280,620)]),Color("#83d77d"))
	_draw_house()
	_draw_trees()
	for node in resource_nodes:
		if node["active"]:
			if node["kind"] == "flower":
				_draw_flower(node["pos"])
			else:
				_draw_crystal(node["pos"])
	if has_pet:
		_draw_creature(Vector2(705,465))
	else:
		_draw_egg(Vector2(705,475))
	_draw_player(player_pos)
	if mini_game_active:
		draw_circle(mini_target,43,Color(1.0,0.92,0.35,0.22))
		_draw_star(mini_target,30,Color("#fff3a6"))
		_draw_text_center("★ %d     %.1f s" % [mini_game_score,mini_game_time],Vector2(640,270),24,Color.WHITE)

func _draw_house() -> void:
	draw_rect(Rect2(475,355,190,145),Color("#fff0d1"))
	draw_colored_polygon(PackedVector2Array([Vector2(450,365),Vector2(570,270),Vector2(690,365)]),Color("#ee8a79"))
	draw_rect(Rect2(550,415,48,85),Color("#8b685a"))
	draw_circle(Vector2(585,460),4,Color("#ffdf75"))
	draw_rect(Rect2(495,390,42,42),Color("#91d8ff"))
	draw_line(Vector2(516,390),Vector2(516,432),Color("#fff9e9"),4)
	draw_line(Vector2(495,411),Vector2(537,411),Color("#fff9e9"),4)

func _draw_trees() -> void:
	for tree in [Vector2(350,440),Vector2(790,430),Vector2(930,480),Vector2(285,495)]:
		draw_rect(Rect2(tree.x-7,tree.y,14,55),Color("#9b704d"))
		draw_circle(tree+Vector2(0,-17),31,Color("#3d9c72"))
		draw_circle(tree+Vector2(-18,-3),21,Color("#58b77a"))
		draw_circle(tree+Vector2(18,-3),21,Color("#58b77a"))

func _draw_flower(p: Vector2) -> void:
	draw_line(p,p+Vector2(0,15),Color("#438b5d"),3)
	for i in range(5):
		var a := TAU*float(i)/5.0
		draw_circle(p+Vector2(cos(a),sin(a))*9.0,6,Color("#fff2f7"))
	draw_circle(p,5,Color("#ffcf70"))
	_draw_star(p+Vector2(0,-22),5,Color("#fff4a5"))

func _draw_crystal(p: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([p+Vector2(0,-22),p+Vector2(17,-5),p+Vector2(10,19),p+Vector2(-10,19),p+Vector2(-17,-5)]),Color("#73e6ef"))
	draw_line(p+Vector2(0,-18),p+Vector2(-5,10),Color("#e4ffff"),3)
	draw_circle(p+Vector2(0,25),14,Color(0.1,0.3,0.4,0.12))

func _draw_egg(center: Vector2) -> void:
	draw_ellipse(center+Vector2(0,24),Vector2(34,9),Color(0.12,0.35,0.38,0.2))
	draw_circle(center,31,Color("#fff4cf"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-42),center+Vector2(24,-12),center+Vector2(28,18),center+Vector2(0,36),center+Vector2(-28,18),center+Vector2(-24,-12)]),Color("#fff2cf"))
	draw_circle(center+Vector2(-9,-2),5,Color("#f4a6cf"))
	draw_circle(center+Vector2(10,9),5,Color("#9b8cff"))
	_draw_star(center+Vector2(0,-12),7,Color("#ffcb65"))

func _draw_creature(center: Vector2) -> void:
	var c := center+Vector2(0,sin(mood_time*3.0)*6.0)
	draw_ellipse(c+Vector2(0,50),Vector2(52,13),Color(0.12,0.35,0.38,0.2))
	draw_colored_polygon(PackedVector2Array([c+Vector2(-34,-35),c+Vector2(-48,-78),c+Vector2(-8,-56)]),Color("#aa8cff"))
	draw_colored_polygon(PackedVector2Array([c+Vector2(34,-35),c+Vector2(48,-78),c+Vector2(8,-56)]),Color("#aa8cff"))
	draw_circle(c,47,Color("#aa8cff"))
	draw_circle(c+Vector2(-12,-12),18,Color("#c9b7ff"))
	draw_circle(c+Vector2(12,-12),18,Color("#c9b7ff"))
	draw_circle(c+Vector2(-16,3),5,Color("#293653"))
	draw_circle(c+Vector2(16,3),5,Color("#293653"))
	draw_arc(c+Vector2(0,12),10,0.2,PI-0.2,16,Color("#573d78"),3)
	draw_circle(c+Vector2(-29,15),8,Color("#ff9fc0"))
	draw_circle(c+Vector2(29,15),8,Color("#ff9fc0"))
	_draw_star(c+Vector2(0,-32),10,Color("#ffe28b"))
	_draw_text_center("%s %d" % [tr_word("level"),creature_level],c+Vector2(0,78),16,Color.WHITE)

func _draw_player(p: Vector2) -> void:
	var bob := sin(mood_time*8.0)*2.5 if move_vector.length() > 0.0 else 0.0
	var c := p+Vector2(0,bob)
	draw_ellipse(c+Vector2(0,25),Vector2(20,7),Color(0.12,0.35,0.38,0.2))
	draw_circle(c+Vector2(0,-7),17,Color("#ffd2a6"))
	draw_colored_polygon(PackedVector2Array([c+Vector2(-16,-12),c+Vector2(-12,-29),c+Vector2(10,-29),c+Vector2(17,-11)]),Color("#4b5f9e"))
	draw_rect(Rect2(c+Vector2(-14,8),Vector2(28,28)),Color("#ffb45e"))
	draw_circle(c+Vector2(-6,-8),2.5,Color("#293653"))
	draw_circle(c+Vector2(6,-8),2.5,Color("#293653"))
	draw_arc(c+Vector2(0,-2),5,0.2,PI-0.2,10,Color("#a65c57"),2)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var a := TAU*float(i)/32.0
		points.append(center+Vector2(cos(a)*radius.x,sin(a)*radius.y))
	draw_colored_polygon(points,color)

func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var a := -PI/2.0+float(i)*PI/5.0
		var r := radius if i%2==0 else radius*0.43
		points.append(center+Vector2(cos(a),sin(a))*r)
	draw_colored_polygon(points,color)

func _draw_text_center(value: String, center: Vector2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(font,center-Vector2(width/2.0,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
