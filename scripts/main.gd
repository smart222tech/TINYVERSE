extends Node2D

const SAVE_PATH := "user://tinyverse_progress.cfg"
const LANGUAGES := ["EN", "DE", "RU"]

var language := "EN"
var stars := 12
var creatures := 0
var eggs := 1
var creature_level := 1
var creature_name := "Mimo"
var mood_time := 0.0
var message := ""
var message_timer := 0.0

var ui: CanvasLayer
var title_label: Label
var stats_label: Label
var message_label: Label
var hatch_button: Button
var language_button: OptionButton

var words := {
	"EN": {"subtitle":"YOUR LITTLE WORLD OF WONDERS", "stars":"STARS", "creatures":"CREATURES", "eggs":"MAGIC EGGS", "hatch":"HATCH AN EGG", "care":"GIVE A STAR", "reset":"RESET", "welcome":"A tiny world, full of magic!", "hatched":"A new friend appeared!", "no_eggs":"No eggs yet — explore your island!", "star":"A little love for your friend!", "level":"LEVEL"},
	"DE": {"subtitle":"DEINE KLEINE WELT VOLLER WUNDER", "stars":"STERNE", "creatures":"WESEN", "eggs":"ZAUBEREIER", "hatch":"EI AUSBRÜTEN", "care":"STERN SCHENKEN", "reset":"NEUSTART", "welcome":"Eine kleine Welt voller Magie!", "hatched":"Ein neuer Freund ist da!", "no_eggs":"Noch keine Eier — erkunde deine Insel!", "star":"Ein bisschen Liebe für deinen Freund!", "level":"LEVEL"},
	"RU": {"subtitle":"ТВОЙ МАЛЕНЬКИЙ МИР ЧУДЕС", "stars":"ЗВЁЗДЫ", "creatures":"СУЩЕСТВА", "eggs":"ВОЛШЕБНЫЕ ЯЙЦА", "hatch":"ВЫЛУПИТЬ ЯЙЦО", "care":"ПОДАРИТЬ ЗВЕЗДУ", "reset":"СБРОС", "welcome":"Маленький мир, полный волшебства!", "hatched":"Появился новый друг!", "no_eggs":"Яиц пока нет — исследуй остров!", "star":"Немного любви для твоего друга!", "level":"УРОВЕНЬ"}
}

func _ready() -> void:
	load_progress()
	build_ui()
	message = tr_word("welcome")
	queue_redraw()

func _process(delta: float) -> void:
	mood_time += delta
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message = ""
			update_ui()
	queue_redraw()

func build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var header := PanelContainer.new()
	header.position = Vector2(28, 22)
	header.size = Vector2(1224, 104)
	header.add_theme_stylebox_override("panel", make_panel(Color(0.10, 0.19, 0.34, 0.88), 26))
	root.add_child(header)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 22)
	header.add_child(header_row)

	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(brand)
	title_label = Label.new()
	title_label.text = "TINYVERSE"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color("#fff4c9"))
	brand.add_child(title_label)
	var subtitle := Label.new()
	subtitle.text = tr_word("subtitle")
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#b9d9ff"))
	brand.add_child(subtitle)

	stats_label = Label.new()
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 17)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	header_row.add_child(stats_label)

	language_button = OptionButton.new()
	language_button.add_item("English")
	language_button.add_item("Deutsch")
	language_button.add_item("Русский")
	language_button.selected = LANGUAGES.find(language)
	language_button.item_selected.connect(_on_language_selected)
	header_row.add_child(language_button)

	var bottom := HBoxContainer.new()
	bottom.position = Vector2(28, 610)
	bottom.size = Vector2(1224, 78)
	bottom.add_theme_constant_override("separation", 18)
	root.add_child(bottom)

	hatch_button = make_button(tr_word("hatch"), Color("#ffbf69"))
	hatch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hatch_button.pressed.connect(_on_hatch_pressed)
	bottom.add_child(hatch_button)

	var care_button := make_button(tr_word("care"), Color("#9b8cff"))
	care_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	care_button.pressed.connect(_on_care_pressed)
	bottom.add_child(care_button)

	var reset_button := make_button(tr_word("reset"), Color("#6e8aa8"))
	reset_button.custom_minimum_size.x = 150
	reset_button.pressed.connect(_on_reset_pressed)
	bottom.add_child(reset_button)

	message_label = Label.new()
	message_label.position = Vector2(250, 535)
	message_label.size = Vector2(780, 48)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 25)
	message_label.add_theme_color_override("font_color", Color("#fff7d6"))
	message_label.add_theme_color_override("font_shadow_color", Color("#18324b"))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 3)
	root.add_child(message_label)
	update_ui()

func make_button(caption: String, color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(220, 66)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("#25314a"))
	button.add_theme_stylebox_override("normal", make_panel(color, 20))
	button.add_theme_stylebox_override("hover", make_panel(color.lightened(0.12), 20))
	button.add_theme_stylebox_override("pressed", make_panel(color.darkened(0.12), 20))
	return button

func make_panel(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func tr_word(key: String) -> String:
	return words.get(language, words["EN"]).get(key, key)

func update_ui() -> void:
	if not is_instance_valid(stats_label):
		return
	stats_label.text = "★ %d %s     ✦ %d %s     ◇ %d %s" % [stars, tr_word("stars"), creatures, tr_word("creatures"), eggs, tr_word("eggs")]
	hatch_button.text = tr_word("hatch")
	message_label.text = message
	if is_instance_valid(language_button):
		language_button.select(LANGUAGES.find(language))

func _on_language_selected(index: int) -> void:
	language = LANGUAGES[clampi(index, 0, 2)]
	update_ui()
	save_progress()

func _on_hatch_pressed() -> void:
	if eggs <= 0:
		show_message(tr_word("no_eggs"))
		return
	eggs -= 1
	creatures += 1
	creature_level = 1
	stars += 3
	show_message(tr_word("hatched"))
	save_progress()

func _on_care_pressed() -> void:
	if creatures <= 0:
		show_message(tr_word("welcome"))
		return
	if stars <= 0:
		show_message("★")
		return
	stars -= 1
	creature_level += 1
	show_message(tr_word("star"))
	save_progress()

func _on_reset_pressed() -> void:
	stars = 12
	creatures = 0
	eggs = 1
	creature_level = 1
	show_message(tr_word("welcome"))
	save_progress()

func show_message(value: String) -> void:
	message = value
	message_timer = 3.0
	update_ui()

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "language", language)
	cfg.set_value("game", "stars", stars)
	cfg.set_value("game", "creatures", creatures)
	cfg.set_value("game", "eggs", eggs)
	cfg.set_value("game", "creature_level", creature_level)
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		language = str(cfg.get_value("game", "language", "EN"))
		stars = int(cfg.get_value("game", "stars", 12))
		creatures = int(cfg.get_value("game", "creatures", 0))
		eggs = int(cfg.get_value("game", "eggs", 1))
		creature_level = int(cfg.get_value("game", "creature_level", 1))

func _draw() -> void:
	var sky := Color("#91d8ff")
	draw_rect(Rect2(0, 0, 1280, 720), sky)
	draw_circle(Vector2(1080, 185), 64, Color("#fff1a8"))
	draw_circle(Vector2(1080, 185), 78, Color(1.0, 0.92, 0.65, 0.18))
	# Puffy clouds
	for cloud in [Vector2(190, 205), Vector2(760, 170), Vector2(450, 285)]:
		draw_circle(cloud, 28, Color("#ffffff"))
		draw_circle(cloud + Vector2(27, 7), 35, Color("#ffffff"))
		draw_circle(cloud + Vector2(60, 2), 25, Color("#ffffff"))
	# Distant magical hills
	draw_colored_polygon(PackedVector2Array([Vector2(0,430),Vector2(0,340),Vector2(170,280),Vector2(340,355),Vector2(520,285),Vector2(720,370),Vector2(930,290),Vector2(1280,370),Vector2(1280,520)]), Color("#83cda8"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,470),Vector2(180,385),Vector2(360,430),Vector2(540,350),Vector2(760,430),Vector2(1010,350),Vector2(1280,430),Vector2(1280,560)]), Color("#63b98f"))
	# Water and island
	draw_rect(Rect2(0, 470, 1280, 250), Color("#48b9d0"))
	for i in range(12):
		var x := float(i) * 125.0 + fposmod(mood_time * 18.0, 125.0)
		draw_arc(Vector2(x, 555 + sin(float(i)) * 42.0), 20, 0.2, 2.7, 20, Color(0.8, 0.98, 1.0, 0.45), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(110,510),Vector2(230,430),Vector2(430,390),Vector2(690,405),Vector2(930,445),Vector2(1110,520),Vector2(1030,650),Vector2(260,650)]), Color("#e7c987"))
	draw_colored_polygon(PackedVector2Array([Vector2(180,500),Vector2(270,445),Vector2(450,420),Vector2(690,430),Vector2(920,465),Vector2(1060,525),Vector2(1000,620),Vector2(280,620)]), Color("#83d77d"))
	# Little cottage
	draw_rect(Rect2(475, 355, 190, 145), Color("#fff0d1"))
	draw_colored_polygon(PackedVector2Array([Vector2(450,365),Vector2(570,270),Vector2(690,365)]), Color("#ee8a79"))
	draw_rect(Rect2(550, 415, 48, 85), Color("#8b685a"))
	draw_circle(Vector2(585, 460), 4, Color("#ffdf75"))
	draw_rect(Rect2(495, 390, 42, 42), Color("#91d8ff"))
	draw_line(Vector2(516,390), Vector2(516,432), Color("#fff9e9"), 4)
	draw_line(Vector2(495,411), Vector2(537,411), Color("#fff9e9"), 4)
	# Trees
	for tree in [Vector2(350,440), Vector2(790,430), Vector2(930,480), Vector2(285,495)]:
		draw_rect(Rect2(tree.x - 7, tree.y, 14, 55), Color("#9b704d"))
		draw_circle(tree + Vector2(0,-17), 31, Color("#3d9c72"))
		draw_circle(tree + Vector2(-18,-3), 21, Color("#58b77a"))
		draw_circle(tree + Vector2(18,-3), 21, Color("#58b77a"))
	# Flowers
	for flower in [Vector2(420,500),Vector2(720,510),Vector2(850,535),Vector2(390,555),Vector2(965,560)]:
		draw_line(flower, flower + Vector2(0,14), Color("#438b5d"), 3)
		draw_circle(flower, 6, Color("#ffcf70"))
		for a in range(5):
			var angle := TAU * float(a) / 5.0
			draw_circle(flower + Vector2(cos(angle), sin(angle)) * 9.0, 5, Color("#fff2f7"))
	# Egg or friendly creature
	if creatures == 0:
		draw_egg(Vector2(700, 475))
	else:
		draw_creature(Vector2(700, 455))
	# Decorative stars
	for i in range(9):
		var p := Vector2(90 + i * 135, 300 + sin(mood_time * 1.4 + i) * 15)
		draw_star(p, 9, Color("#fff3a6"))

func draw_egg(center: Vector2) -> void:
	draw_ellipse(center + Vector2(0, 24), Vector2(34, 9), Color(0.12,0.35,0.38,0.2))
	draw_circle(center + Vector2(0, 0), 31, Color("#fff4cf"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-42),center+Vector2(24,-12),center+Vector2(28,18),center+Vector2(0,36),center+Vector2(-28,18),center+Vector2(-24,-12)]), Color("#fff2cf"))
	draw_circle(center + Vector2(-9,-2), 5, Color("#f4a6cf"))
	draw_circle(center + Vector2(10,9), 5, Color("#9b8cff"))
	draw_star(center + Vector2(0,-12), 7, Color("#ffcb65"))

func draw_creature(center: Vector2) -> void:
	var bob := sin(mood_time * 3.0) * 5.0
	var c := center + Vector2(0,bob)
	draw_ellipse(c + Vector2(0,50), Vector2(52,13), Color(0.12,0.35,0.38,0.2))
	# ears and body
	draw_colored_polygon(PackedVector2Array([c+Vector2(-34,-35),c+Vector2(-48,-78),c+Vector2(-8,-56)]), Color("#aa8cff"))
	draw_colored_polygon(PackedVector2Array([c+Vector2(34,-35),c+Vector2(48,-78),c+Vector2(8,-56)]), Color("#aa8cff"))
	draw_circle(c, 47, Color("#aa8cff"))
	draw_circle(c + Vector2(-12,-12), 18, Color("#c9b7ff"))
	draw_circle(c + Vector2(12,-12), 18, Color("#c9b7ff"))
	draw_circle(c + Vector2(-16,3), 5, Color("#293653"))
	draw_circle(c + Vector2(16,3), 5, Color("#293653"))
	draw_arc(c + Vector2(0,12), 10, 0.2, PI-0.2, 16, Color("#573d78"), 3)
	draw_circle(c + Vector2(-29,15), 8, Color("#ff9fc0"))
	draw_circle(c + Vector2(29,15), 8, Color("#ff9fc0"))
	draw_star(c + Vector2(0,-32), 10, Color("#ffe28b"))
	draw_label_center("Lv. %d" % creature_level, c + Vector2(0,75), 17, Color("#ffffff"))

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(a)*radius.x, sin(a)*radius.y))
	draw_colored_polygon(points, color)

func draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var a := -PI/2.0 + float(i) * PI/5.0
		var r := radius if i % 2 == 0 else radius * 0.43
		points.append(center + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, color)

func draw_label_center(value: String, center: Vector2, size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center - Vector2(width/2.0, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
