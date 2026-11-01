extends Control

const D = preload("res://Data.gd")
const CARD_TYPOGRAPHY = preload("res://assets/Fonts/FateCardTypography.tres")
const IsoBoard = preload("res://scripts/ui/iso_board.gd")
const ASSET_FILES = [
	"icon_energy.png", "icon_environment.png", "icon_money.png", "icon_people.png", "icon_pollution.png",
	"plant_coal.png", "plant_gas.png", "plant_solar.png", "plant_wind.png",
	"portrait_engineer.png", "portrait_environmentalist.png", "portrait_farmer.png",
	"portrait_industrialist.png", "portrait_mayor.png", "portrait_scientist.png",
	"tile_blocked.png", "tile_empty.png", "tile_selected.png",
	"choice_yes_backdrop.png", "choice_no_backdrop.png",
	"card_reference.jpeg", "card_public.jpeg", "card_recycling.jpeg",
	"card_education.jpeg", "card_conscious_consumption.jpeg",
	"card_filters.jpeg", "card_green_space.jpeg", "card_solar_panels.jpeg", "card_cooling.jpeg"
]
const PORTRAITS = {
	"Sanayi talebi":"industrialist", "Güneş teşviki":"mayor", "Çevre denetimi":"scientist",
	"Bakım zamanı":"engineer", "Bilinçli tüketim":"environmentalist", "Gıda güvenliği":"farmer",
	"Denizleri koru":"scientist", "Sıfır atık":"environmentalist", "Sıcak hava":"scientist",
	"Rüzgârlı günler":"engineer", "İklim dirençli şehir":"environmentalist", "Güneş paneli temizliği":"engineer"
}

var money: int
var pollution: int
var support: int
var health: int
var turn: int
var saving: int
var bonus_energy: int
var bonus_demand: int
var discount: int
var selected: int = 0
var board: Array = []
var deck: Array = []
var resolved: int = 0
var phase: String = "build"
var current: Dictionary = {}
var rng := RandomNumberGenerator.new()
var textures: Dictionary = {}
var card_font: Font
var card_theme: Theme
var exo_font: Font
var plant_images: Array = []
var tiles: Array[Button] = []
var shops: Array[Button] = []
var tile_pictures: Array[TextureRect] = []
var tile_frames: Array[TextureRect] = []
var terrain_tiles: Array[Button] = []

var metrics: Array[Label] = []
var turn_label: Label
var info: Label
var build_title: Label
var selected_hint: Label
var next: Button
var reset_button: Button
var map_panel: PanelContainer
var planning_panel: PanelContainer
var board_view: IsoBoard

var card_overlay: Control
var card_panel: Panel
var card_title: Label
var card_source: Label
var card_body: Label
var card_effects: Label
var card_portrait: TextureRect
var card_art: PanelContainer
var card_art_backdrop: TextureRect
var card_glow: Panel
var card_counter: Label
var card_yes: Button
var card_no: Button
var yes_zone: Panel
var no_zone: Panel
var yes_backdrop: TextureRect
var no_backdrop: TextureRect
var yes_hint: Label
var no_hint: Label
var card_stage: Control
var card_margin: MarginContainer
var cards_to_resolve: int = 0
var card_home_position := Vector2.ZERO
var simulation_timer: Timer
var next_plant_event_count := 5
var drag_origin := Vector2.ZERO
var card_origin := Vector2.ZERO
var dragging := false
var decision_locked := false
var swipe_threshold := 170.0
var swipe_exit_distance := 1100.0

func _ready() -> void:
	for file in ASSET_FILES:
		textures[file.get_basename()] = load("res://assets/" + file)
	card_theme = CARD_TYPOGRAPHY
	exo_font = card_theme.get_font("font", "FateCardBody")
	card_font = card_theme.get_font("font", "FateCardTitle")
	plant_images = [textures["plant_coal"], textures["plant_gas"], textures["plant_solar"], textures["plant_wind"]]
	rng.randomize()
	build_ui()
	restart()

func label_at(parent: Node, size: int, color := Color.WHITE) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.modulate = color
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func typeface(control: Control, font: Font, size: int) -> void:
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)

func card_typeface(control: Control, variation: String) -> void:
	control.theme = card_theme
	control.theme_type_variation = variation
	control.remove_theme_font_override("font")
	control.remove_theme_font_size_override("font_size")

func panel_style(color: Color, border := Color.TRANSPARENT, width := 0, radius := 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func hazard_strip(parent: Node, height := 8.0) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.custom_minimum_size.y = height
	strip.add_theme_constant_override("separation", 0)
	parent.add_child(strip)
	for i in range(12):
		var segment := ColorRect.new()
		segment.custom_minimum_size.x = 18
		segment.color = Color("#d28a32") if i % 2 == 0 else Color("#1a2228")
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(segment)
	return strip

func button_at(parent: Node, text: String, action: Callable, color := Color("#163747")) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	typeface(button, exo_font, 15)
	button.add_theme_stylebox_override("normal", panel_style(color, Color("#2a6470"), 1, 10))
	button.add_theme_stylebox_override("hover", panel_style(Color("#20596a"), Color("#43d9ff"), 1, 10))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#28765c"), Color("#35e0a1"), 1, 10))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#101e2b"), Color("#203442"), 1, 10))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func picture(parent: Node, texture: Texture2D, dimensions: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = dimensions
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect

func build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#06111c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var glow := ColorRect.new()
	glow.color = Color("#0a2330")
	glow.position = Vector2(0, 0)
	glow.size = Vector2(430, 1000)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	build_header(root)
	build_metrics(root)
	build_body(root)
	build_footer(root)
	build_card_overlay()
	card_overlay.theme = card_theme
	simulation_timer = Timer.new()
	simulation_timer.wait_time = 9.0
	simulation_timer.one_shot = false
	simulation_timer.timeout.connect(simulation_pulse)
	add_child(simulation_timer)
	simulation_timer.start()

func build_header(root: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 54
	root.add_child(header)
	var brand := label_at(header, 19, Color("#43d9ff"))
	brand.text = "◈  DÜNYA: SON ŞANS"
	brand.custom_minimum_size.x = 280
	var center := label_at(header, 24, Color("#e9f4ff"))
	center.text = "GEZEGENSEL YÖNETİM KONSOLU"
	center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_label = label_at(header, 16, Color("#ffc857"))
	turn_label.text = "CANLI SİMÜLASYON  •  2026"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	turn_label.custom_minimum_size.x = 260

func build_metrics(root: VBoxContainer) -> void:
	var metrics_row := HBoxContainer.new()
	metrics_row.add_theme_constant_override("separation", 12)
	root.add_child(metrics_row)
	var keys := ["money", "energy", "pollution", "people", "health"]
	var names := ["BÜTÇE", "ENERJİ ARZI", "KİRLİLİK", "HALK DESTEĞİ", "SAĞLIK"]
	var icons := ["icon_money", "icon_energy", "icon_pollution", "icon_people", "icon_environment"]
	for i in keys.size():
		var metric_panel := PanelContainer.new()
		metric_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metric_panel.add_theme_stylebox_override("panel", panel_style(Color("#0c2230"), Color("#1c5360"), 1, 12))
		metrics_row.add_child(metric_panel)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		metric_panel.add_child(line)
		picture(line, textures[icons[i]], Vector2(42, 42))
		var text := label_at(line, 15, Color("#8ba9bd"))
		text.text = names[i] + "\n—"
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metrics.append(text)

func build_body(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	map_panel = PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 1.65
	map_panel.add_theme_stylebox_override("panel", panel_style(Color("#0a1c2a"), Color("#1c5965"), 1, 16))
	row.add_child(map_panel)
	build_map(map_panel)
	planning_panel = PanelContainer.new()
	planning_panel.custom_minimum_size.x = 380
	planning_panel.add_theme_stylebox_override("panel", panel_style(Color("#0b1c2c"), Color("#204b60"), 1, 16))
	row.add_child(planning_panel)
	build_planning(planning_panel)

func build_map(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	parent.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := label_at(box, 18, Color("#9fc7d6"))
	title.text = "ŞEHİR PLANLAMA AĞI  /  İZOMETRİK ARAZİ"
	var sub := label_at(box, 13, Color("#527b89"))
	sub.text = "Boş bir arazi seç, enerji santralini yerleştir ve kapasiteyi yönet."
	var grid_panel := PanelContainer.new()
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.add_theme_stylebox_override("panel", panel_style(Color("#071824"), Color("#214e5c"), 1, 12))
	box.add_child(grid_panel)
	var grid_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		grid_margin.add_theme_constant_override("margin_" + side, 18)
	grid_panel.add_child(grid_margin)
	board_view = IsoBoard.new()
	board_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.cell_pressed.connect(place)
	board_view.cell_hovered.connect(hover_cell)
	grid_margin.add_child(board_view)
	var hint := label_at(box, 13, Color("#5b8493"))
	hint.text = "Her santral bir arazi karesi kaplar. Hover sırasında arazi ve santral bilgisi gösterilir."

func build_planning(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	parent.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var kicker := label_at(box, 13, Color("#35e0a1"))
	kicker.text = "İNŞA AŞAMASI"
	build_title = label_at(box, 27, Color("#eff8ff"))
	build_title.text = "ŞEHRİ HAZIRLA"
	var copy := label_at(box, 15, Color("#7d9baa"))
	copy.text = "Bir santral seç. Haritadaki boş bir hücreye tıklayarak şehrin enerji dengesini kur."
	var separator := HSeparator.new()
	box.add_child(separator)
	selected_hint = label_at(box, 16, Color("#ffc857"))
	selected_hint.text = "Seçili: Kömür"
	var plant_list := VBoxContainer.new()
	plant_list.add_theme_constant_override("separation", 8)
	box.add_child(plant_list)
	for i in range(D.PLANTS.size()):
		var shop := button_at(plant_list, "", select_plant.bind(i))
		shop.custom_minimum_size.y = 64
		shops.append(shop)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	next = Button.new()
	next.visible = false
	var guide := label_at(box, 13, Color("#5c8090"))
	guide.text = "Şehir kendi akışıyla çalışır. Kritik koşullar oluştuğunda karar kartı kendiliğinden açılır."

func build_footer(root: VBoxContainer) -> void:
	var footer := PanelContainer.new()
	footer.custom_minimum_size.y = 74
	footer.add_theme_stylebox_override("panel", panel_style(Color("#081925"), Color("#1d4d5b"), 1, 12))
	root.add_child(footer)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	footer.add_child(box)
	info = label_at(box, 14, Color("#8da8b5"))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reset_button = button_at(box, "YENİ OYUN", restart, Color("#172a39"))
	reset_button.custom_minimum_size = Vector2(130, 42)

func build_card_overlay() -> void:
	card_overlay = Control.new()
	card_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_overlay.z_index = 20
	card_overlay.visible = false
	add_child(card_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.04, 0.07, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_overlay.add_child(dim)
	var header := label_at(card_overlay, 14, Color("#35e0a1"))
	header.text = "◈  KADER KARTI AŞAMASI  /  ŞEHRİN GELECEĞİ SENİN KARARIN"
	header.set_anchors_preset(Control.PRESET_CENTER_TOP)
	header.position = Vector2(-330, 26)
	header.size = Vector2(660, 30)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_stage = Control.new()
	card_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_overlay.add_child(card_stage)
	yes_zone = decision_zone(card_stage, true)
	var center := Control.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_stage.add_child(center)
	no_zone = decision_zone(card_stage, false)
	build_card(center)
	card_overlay.resized.connect(layout_card_overlay)
	call_deferred("layout_card_overlay")
	var hint := label_at(card_overlay, 13, Color("#567d8e"))
	hint.text = "KARTI TUTUP SÜRÜKLE  •  SOLA KAYDIR = EVET  •  SAĞA KAYDIR = HAYIR  •  ESC = BEKLE"
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-360, -34)
	hint.size = Vector2(720, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func decision_zone(stage: Control, is_yes: bool) -> Panel:
	var zone := Panel.new()
	var color := Color("#102b2a") if is_yes else Color("#302127")
	var border := Color("#41d9ad") if is_yes else Color("#d86b69")
	var zone_style := panel_style(color, border, 2, 20)
	zone_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	zone_style.shadow_size = 12
	zone.add_theme_stylebox_override("panel", zone_style)
	stage.add_child(zone)
	zone.clip_contents = true
	var backdrop := TextureRect.new()
	backdrop.texture = textures["choice_yes_backdrop" if is_yes else "choice_no_backdrop"]
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.modulate = Color(1.0, 1.0, 1.0, 0.9)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(backdrop)
	var emblem := TextureRect.new()
	emblem.texture = textures["icon_environment" if is_yes else "icon_pollution"]
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.set_anchors_preset(Control.PRESET_CENTER)
	emblem.position = Vector2(-66, -132)
	emblem.size = Vector2(132, 132)
	emblem.modulate = Color(0.42, 1.0, 0.78, 0.88) if is_yes else Color(1.0, 0.42, 0.42, 0.88)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.add_child(emblem)
	if is_yes:
		yes_backdrop = backdrop
	else:
		no_backdrop = backdrop
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	zone.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var icon := label_at(box, 58, border)
	card_typeface(icon, "FateCardChoice")
	icon.add_theme_font_size_override("font_size", 58)
	icon.text = "✦" if is_yes else "⊘"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title := label_at(box, 32, border)
	card_typeface(title, "FateCardChoice")
	title.add_theme_font_size_override("font_size", 32)
	title.text = "EVET" if is_yes else "HAYIR"
	title.add_theme_color_override("font_shadow_color", border)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var action := label_at(box, 18, Color("#f0eee3"))
	card_typeface(action, "FateCardBody")
	action.add_theme_font_size_override("font_size", 18)
	action.text = "ONAYLA" if is_yes else "REDDET"
	action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var line := HSeparator.new()
	box.add_child(line)
	hazard_strip(box, 6.0)
	var hint := label_at(box, 15, Color("#d6e5df"))
	card_typeface(hint, "FateCardBody")
	hint.add_theme_font_size_override("font_size", 15)
	hint.text = "ŞEHRİN YÖNÜNÜ DEĞİŞTİR" if is_yes else "MEVCUT DÜZENİ KORU"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_yes:
		yes_hint = hint
	else:
		no_hint = hint
	var button := button_at(box, "EVET / ONAYLA" if is_yes else "HAYIR / REDDET", choose.bind("left" if is_yes else "right"), color)
	button.custom_minimum_size.y = 52
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_yes:
		card_yes = button
	else:
		card_no = button
	return zone

func build_card(center: Control) -> void:
	var stack_back := PanelContainer.new()
	stack_back.position = Vector2(48, 28)
	stack_back.size = Vector2(520, 610)
	stack_back.rotation = deg_to_rad(-4)
	stack_back.add_theme_stylebox_override("panel", panel_style(Color("#122b43"), Color("#1d7180"), 1, 24))
	center.add_child(stack_back)
	var stack_back2 := PanelContainer.new()
	stack_back2.position = Vector2(34, 18)
	stack_back2.size = Vector2(520, 610)
	stack_back2.rotation = deg_to_rad(3)
	stack_back2.add_theme_stylebox_override("panel", panel_style(Color("#10243a"), Color("#21546d"), 1, 24))
	center.add_child(stack_back2)
	card_panel = Panel.new()
	card_panel.position = Vector2(28, 8)
	card_panel.size = Vector2(520, 610)
	card_panel.custom_minimum_size = Vector2.ZERO
	card_panel.pivot_offset = Vector2(260, 305)
	card_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	card_panel.clip_contents = true
	var shell := panel_style(Color("#11161b"), Color("#4b806f"), 3, 24)
	shell.shadow_color = Color(0.0, 0.0, 0.0, 0.75)
	shell.shadow_size = 18
	card_panel.add_theme_stylebox_override("panel", shell)
	center.add_child(card_panel)
	var center_backdrop := TextureRect.new()
	center_backdrop.texture = textures["card_reference"]
	center_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	center_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	center_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.0)
	center_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_panel.add_child(center_backdrop)
	var glow := Panel.new()
	card_glow = glow
	glow.position = Vector2(28, 8)
	glow.size = Vector2(520, 610)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style := panel_style(Color(0.0, 0.0, 0.0, 0.0), Color("#27e6d2"), 2, 24)
	glow_style.shadow_color = Color(0.05, 0.95, 0.85, 0.9)
	glow_style.shadow_size = 14
	glow.add_theme_stylebox_override("panel", glow_style)
	center.add_child(glow)
	center.move_child(glow, 2)
	var margin := MarginContainer.new()
	card_margin = margin
	margin.custom_minimum_size = Vector2.ZERO
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	card_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_vertical = Control.SIZE_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)
	var status := HBoxContainer.new()
	status.custom_minimum_size.y = 12
	status.add_theme_constant_override("separation", 7)
	box.add_child(status)
	for i in range(4):
		var light := ColorRect.new()
		light.custom_minimum_size = Vector2(18, 5)
		light.color = Color("#f0ad4e") if i == 0 else Color("#2bc8a7") if i == 1 else Color("#34434a")
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status.add_child(light)
	var status_label := label_at(status, 10, Color("#71918b"))
	card_typeface(status_label, "FateCardTechnical")
	status_label.text = "SYS // KADER KARTI"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var top := HBoxContainer.new()
	box.add_child(top)
	card_source = label_at(top, 15, Color("#39dcca"))
	card_typeface(card_source, "FateCardCategory")
	card_source.add_theme_color_override("font_shadow_color", Color("#35e0a1"))
	card_source.add_theme_constant_override("shadow_offset_x", 1)
	card_source.add_theme_constant_override("shadow_offset_y", 1)
	card_source.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_source.clip_text = true
	card_source.autowrap_mode = TextServer.AUTOWRAP_OFF
	card_source.custom_minimum_size.x = 0
	card_counter = label_at(top, 14, Color("#ffc857"))
	card_typeface(card_counter, "FateCardTechnical")
	card_counter.custom_minimum_size.x = 72
	card_counter.size_flags_horizontal = Control.SIZE_SHRINK_END
	card_counter.clip_text = true
	card_counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	card_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	card_title = label_at(box, 34, Color("#f4f1e8"))
	card_typeface(card_title, "FateCardTitle")
	card_title.add_theme_color_override("font_color", Color("#f4f1e8"))
	card_title.add_theme_color_override("font_outline_color", Color("#07131d"))
	card_title.add_theme_constant_override("outline_size", 4)
	card_title.add_theme_color_override("font_shadow_color", Color("#39dcca"))
	card_title.add_theme_constant_override("shadow_offset_x", 2)
	card_title.add_theme_constant_override("shadow_offset_y", 2)
	card_title.custom_minimum_size.y = 48
	card_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var art := PanelContainer.new()
	card_art = art
	art.custom_minimum_size.y = 238
	var portrait_style := panel_style(Color("#172228"), Color("#b17b42"), 2, 12)
	portrait_style.shadow_color = Color("#0b0d0e")
	portrait_style.shadow_size = 8
	art.add_theme_stylebox_override("panel", portrait_style)
	box.add_child(art)
	card_portrait = picture(art, textures["portrait_mayor"], Vector2.ZERO)
	card_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_portrait.modulate = Color("#d6e0d1")
	card_portrait.visible = false
	var art_backdrop := TextureRect.new()
	card_art_backdrop = art_backdrop
	art_backdrop.texture = textures["card_reference"]
	art_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.92)
	art_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(art_backdrop)
	card_body = label_at(box, 17, Color("#d5e1e5"))
	card_typeface(card_body, "FateCardBody")
	card_body.custom_minimum_size.y = 0
	card_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_effects = label_at(box, 14, Color("#8fc6c9"))
	card_typeface(card_effects, "FateCardEffects")
	card_effects.custom_minimum_size.y = 0
	var divider := HSeparator.new()
	box.add_child(divider)
	hazard_strip(box, 7.0)
	var choices := HBoxContainer.new()
	choices.custom_minimum_size.y = 42
	choices.add_theme_constant_override("separation", 14)
	box.add_child(choices)
	var yes_label := label_at(choices, 14, Color("#35e0a1"))
	card_typeface(yes_label, "FateCardChoice")
	yes_label.text = "← EVET / ONAYLA"
	yes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var no_label := label_at(choices, 14, Color("#ff6685"))
	card_typeface(no_label, "FateCardChoice")
	no_label.custom_minimum_size.x = 150
	no_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no_label.text = "HAYIR / REDDET →"
	no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func layout_card_overlay() -> void:
	if card_stage == null or card_panel == null:
		return
	var viewport := get_viewport_rect().size
	var margin_x := clampf(viewport.x * 0.035, 18.0, 48.0)
	var top := 72.0
	var bottom := 48.0
	var available_h := maxf(420.0, viewport.y - top - bottom)
	var card_w := clampf(viewport.x * 0.34, 400.0, 500.0)
	var card_h := clampf(available_h * 0.72, 480.0, 560.0)
	var zone_w := clampf(viewport.x * 0.22, 240.0, 330.0)
	var center_x := viewport.x * 0.5
	var card_left := center_x - card_w * 0.5
	var card_top := top + maxf(0.0, (available_h - card_h) * 0.5)
	var zone_top := card_top
	var zone_h := card_h
	yes_zone.position = Vector2(margin_x, zone_top)
	yes_zone.size = Vector2(zone_w, zone_h)
	yes_zone.custom_minimum_size = Vector2(zone_w, zone_h)
	no_zone.position = Vector2(viewport.x - margin_x - zone_w, zone_top)
	no_zone.size = Vector2(zone_w, zone_h)
	no_zone.custom_minimum_size = Vector2(zone_w, zone_h)
	var center: Control = card_panel.get_parent()
	center.position = Vector2(card_left - 28.0, card_top - 8.0)
	center.size = Vector2(card_w + 56.0, card_h + 16.0)
	card_panel.size = Vector2(card_w, card_h)
	card_panel.custom_minimum_size = Vector2(card_w, card_h)
	card_panel.pivot_offset = Vector2(card_w * 0.5, card_h * 0.5)
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_home_position = Vector2(28.0, 8.0)
	card_panel.position = card_home_position
	if card_glow != null:
		card_glow.position = card_home_position
		card_glow.size = Vector2(card_w, card_h)
	var stack_back: Control = center.get_child(0)
	var stack_back2: Control = center.get_child(1)
	stack_back.size = Vector2(card_w, card_h)
	stack_back.position = Vector2(48.0, 28.0)
	stack_back2.size = Vector2(card_w, card_h)
	stack_back2.position = Vector2(34.0, 18.0)
	card_yes.custom_minimum_size.x = zone_w - 36.0
	card_no.custom_minimum_size.x = zone_w - 36.0
	if card_art != null:
		card_art.custom_minimum_size.y = clampf(card_h * 0.38, 205.0, 250.0)
	yes_zone.queue_redraw()
	no_zone.queue_redraw()

func restart() -> void:
	money = D.START_MONEY
	pollution = 0
	support = 70
	health = 76
	turn = 1
	saving = 0
	selected = 0
	board = []
	board.resize(16)
	board.fill(-1)
	board[0] = 0
	board[1] = 2
	deck.clear()
	next_plant_event_count = 5
	card_overlay.visible = false
	dragging = false
	decision_locked = false
	start_turn()
	info.text = "Başlangıç hediyesi: 1 kömür + 1 güneş. Şehrini kur; kritik koşullar oluştuğunda kader kartları kendiliğinden açılır."

func start_turn() -> void:
	bonus_energy = 0
	bonus_demand = 0
	discount = 0
	resolved = 0
	phase = "build"
	current = {}
	refresh()

func simulation_pulse() -> void:
	if phase != "build":
		return
	var gap: int = maxi(0, demand() - energy())
	var sale: int = mini(6, maxi(0, energy() - demand()))
	var income: int = D.INCOME + plant_income() + sale - gap * 3
	money += income
	pollution = clampi(pollution + emissions(), 0, 100)
	support = clampi(support - gap * 4 + (2 if gap == 0 else 0), 0, 100)
	info.text = "Canlı şehir akışı: gelir %+d  •  santral geliri %d  •  enerji açığı %d" % [income, plant_income(), gap]
	if check_loss():
		return
	turn += 1
	bonus_energy = 0
	bonus_demand = 0
	discount = 0
	refresh()

func energy() -> int:
	var total: int = bonus_energy
	for kind in board:
		if kind >= 0:
			total += int(D.PLANTS[kind].energy)
	return maxi(0, total)

func emissions() -> int:
	var total: int = 0
	for kind in board:
		if kind >= 0:
			total += int(D.PLANTS[kind].pollution)
	return total

func installed_plant_count() -> int:
	var count := 0
	for kind in board:
		if kind >= 0:
			count += 1
	return count

func plant_income() -> int:
	return 0

func demand() -> int:
	return maxi(1, 8 + (turn - 1) * 3 - saving + bonus_demand)

func price(kind: int) -> int:
	return maxi(0, int(D.PLANTS[kind].cost) - (discount if kind == 2 else 0))

func select_plant(kind: int) -> void:
	selected = kind
	refresh()

func hover_cell(index: int) -> void:
	if board_view == null:
		return
	if index < 0:
		board_view.show_hover(-1, false)
		board_view.tooltip_text = ""
		return
	if board[index] >= 0:
		var plant: Dictionary = D.PLANTS[board[index]]
		board_view.show_hover(-1, false)
		board_view.tooltip_text = "%s: %d enerji / %d kirlilik" % [plant.name, plant.energy, plant.pollution]
		return
	board_view.tooltip_text = "Boş arazi: seçili santrali kur"
	board_view.show_hover(index if phase in ["build", "review"] else -1, money >= price(selected))

func place(index: int) -> void:
	if phase not in ["build", "review"] or board[index] != -1:
		return
	if money < price(selected):
		info.text = "Bu santral için bütçen yetmiyor."
		return
	money -= price(selected)
	board[index] = selected
	info.text = "%s kuruldu. Enerji arzı ve kirlilik göstergeleri güncellendi." % D.PLANTS[selected].name
	refresh()
	if phase == "build" and installed_plant_count() >= next_plant_event_count:
		begin_card_phase()

func begin_card_phase() -> void:
	phase = "cards"
	resolved = 0
	cards_to_resolve = 2
	next_plant_event_count += 3
	draw_card()

func draw_card() -> void:
	if deck.is_empty():
		for i in range(D.EVENTS.size()):
			deck.append(i)
		for i in range(deck.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var temp = deck[i]
			deck[i] = deck[j]
			deck[j] = temp
	var picked: int = -1
	var conditional_picked: int = -1
	for i in range(deck.size()):
		var event: Dictionary = D.EVENTS[deck[i]]
		var required: int = event.required
		if required == -1 or board.has(required):
			if not event.has("condition") or event_condition_met(event):
				conditional_picked = i
				break
			if picked == -1 and not event.has("condition"):
				picked = i
	if conditional_picked >= 0:
		picked = conditional_picked
	if picked == -1:
		deck.clear()
		draw_card()
		return
	current = D.EVENTS[deck[picked]]
	deck.remove_at(picked)
	show_card()

func event_condition_met(event: Dictionary) -> bool:
	if not event.has("condition"):
		return true
	var condition: Dictionary = event.condition
	var value: float = float(support if condition.stat == "support" else pollution if condition.stat == "pollution" else money)
	var target: float = float(condition.value)
	match str(condition.operator):
		"<=": return value <= target
		">=": return value >= target
		"<": return value < target
		">": return value > target
		"==": return is_equal_approx(value, target)
	return false

func show_card() -> void:
	decision_locked = false
	var portrait_name: String = str(PORTRAITS.get(current.get("title", ""), "mayor"))
	card_portrait.texture = textures["portrait_" + portrait_name]
	card_portrait.visible = false
	card_art_backdrop.texture = textures[card_art_key(str(current.get("title", "")), str(current.get("body", "")))]
	card_source.text = card_category(str(current.get("title", ""))) + "  //  KAMU GÜNDEMİ"
	card_counter.text = "%02d  •  %02d" % [resolved + 1, cards_to_resolve]
	card_title.text = current.title.to_upper()
	card_body.text = current.body
	card_effects.text = "OLASI ETKİLER\nEVET: %s\nHAYIR: %s" % [effects_text(current.left.effects), effects_text(current.right.effects)]
	card_yes.text = "←  " + current.left.text
	card_no.text = current.right.text + "  →"
	card_yes.disabled = money + int(current.left.effects.get("money", 0)) < 0
	card_no.disabled = money + int(current.right.effects.get("money", 0)) < 0
	yes_hint.text = current.left.text
	no_hint.text = current.right.text
	card_overlay.visible = true
	layout_card_overlay()
	card_panel.position = card_home_position
	card_panel.rotation = 0.0
	card_panel.modulate = Color.WHITE
	yes_zone.modulate = Color.WHITE
	no_zone.modulate = Color.WHITE
	var tween := create_tween()
	card_panel.position = card_home_position + Vector2(-28, 18)
	card_panel.modulate.a = 0.0
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "position", card_home_position, 0.38)
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.28)
	call_deferred("_refresh_card_layout_after_frame")

func _refresh_card_layout_after_frame() -> void:
	if card_overlay.visible and card_panel != null:
		layout_card_overlay()

func effects_text(effects: Dictionary) -> String:
	var names := {"money":"Bütçe", "pollution":"Kirlilik", "support":"Halk", "health":"Sağlık", "demand":"Geçici ihtiyaç", "energy":"Geçici enerji", "discount":"Güneş indirimi", "saving":"Kalıcı tasarruf"}
	var parts := PackedStringArray()
	for key in effects:
		parts.append("%s %+d" % [names[key], effects[key]])
	return "Etki yok" if parts.is_empty() else " • ".join(parts)

func card_category(title: String) -> String:
	var lower := title.to_lower()
	if lower.contains("çevre") or lower.contains("hava") or lower.contains("deniz") or lower.contains("atık") or lower.contains("iklim"):
		return "ÇEVRE"
	if lower.contains("güneş") or lower.contains("rüzg") or lower.contains("enerji") or lower.contains("kömür") or lower.contains("panel"):
		return "ENERJİ"
	if lower.contains("halk") or lower.contains("gıda") or lower.contains("eğitim") or lower.contains("tüketim"):
		return "TOPLUM"
	return "KAMU"

func card_art_key(title: String, body := "") -> String:
	var lower := title.to_lower()
	var body_lower := body.to_lower()
	if lower.contains("çevre denetimi") or lower.contains("filtre"):
		return "card_filters"
	if lower.contains("iklim dirençli") or lower.contains("yeşil alan"):
		return "card_green_space"
	if lower.contains("panel temizliği") or lower.contains("güneş paneli") or lower.contains("güneş teşviki"):
		return "card_solar_panels"
	if lower.contains("sıcak hava") or lower.contains("soğutma") or lower.contains("hava alarmı"):
		return "card_cooling"
	if lower.contains("eğitim") or body_lower.contains("eğitim kampanyası"):
		return "card_education"
	if lower.contains("bilinçli tüketim"):
		return "card_conscious_consumption"
	if lower.contains("sıfır atık") or lower.contains("geri dönüşüm"):
		return "card_recycling"
	if lower.contains("halk") or lower.contains("gıda") or lower.contains("deniz"):
		return "card_public"
	return "card_reference"

func choose(side: String) -> void:
	if phase != "cards" or decision_locked:
		return
	var effects: Dictionary = current.left.effects if side == "left" else current.right.effects
	if money + int(effects.get("money", 0)) < 0:
		info.text = "Bu seçeneğe bütçe yetmiyor; diğer seçeneği kullan."
		return
	decision_locked = true
	card_yes.disabled = true
	card_no.disabled = true
	var direction := -1.0 if side == "left" else 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(card_panel, "position", card_home_position + Vector2(direction * swipe_exit_distance, 0), 0.34)
	tween.tween_property(card_panel, "rotation", direction * 0.32, 0.34)
	tween.tween_property(card_panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	apply_effects(effects)
	resolved += 1
	if check_loss():
		return
	if resolved >= cards_to_resolve:
		phase = "build"
		card_overlay.visible = false
		bonus_energy = 0
		bonus_demand = 0
		discount = 0
		turn += 1
		info.text = "Karar uygulandı. Şehir akışı devam ediyor; yeni olaylar koşullar oluştuğunda açılacak."
		refresh()
	else:
		draw_card()

func apply_effects(effects: Dictionary) -> void:
	money += int(effects.get("money", 0))
	pollution = clampi(pollution + int(effects.get("pollution", 0)), 0, 100)
	support = clampi(support + int(effects.get("support", 0)), 0, 100)
	health = clampi(health + int(effects.get("health", 0)), 0, 100)
	bonus_energy += int(effects.get("energy", 0))
	bonus_demand += int(effects.get("demand", 0))
	discount += int(effects.get("discount", 0))
	saving += int(effects.get("saving", 0))
	info.text = "Karar uygulandı: " + effects_text(effects)

func check_loss() -> bool:
	if money < 0 or pollution >= 100 or support <= 0 or health <= 0:
		finish("OYUN BİTTİ", "Bütçe, gezegen, sağlık veya halk desteği kritik eşiği geçti.")
		return true
	return false

func finish(title: String, message: String) -> void:
	phase = "ended"
	card_overlay.visible = false
	refresh()
	build_title.text = title
	info.text = message
func should_trigger_cards() -> bool:
	return installed_plant_count() >= next_plant_event_count

func refresh() -> void:
	turn_label.text = "CANLI SİMÜLASYON  •  %d YILI" % (2025 + turn)
	metrics[0].text = "BÜTÇE\n%d" % money
	metrics[1].text = "ENERJİ ARZI\n%d / %d" % [energy(), demand()]
	metrics[2].text = "KİRLİLİK\n%d / 100" % pollution
	metrics[3].text = "HALK DESTEĞİ\n%d / 100" % support
	metrics[4].text = "SAĞLIK\n%d / 100" % health
	selected_hint.text = "SEÇİLİ SANTRAL  •  %s  •  %d BÜTÇE" % [D.PLANTS[selected].name.to_upper(), price(selected)]
	if board_view != null:
		board_view.set_board(board, phase in ["build", "review"])
		hover_cell(board_view.pointer_cell)
	for i in range(shops.size()):
		var plant: Dictionary = D.PLANTS[i]
		shops[i].text = ("%s  " % ("◆" if selected == i else "○")) + "%s\n◉ %d bütçe   ⚡ %d enerji   ☣ %d kirlilik" % [plant.name, price(i), plant.energy, plant.pollution]
		shops[i].tooltip_text = "%s\n◉ Maliyet: %d bütçe\n⚡ Enerji: +%d\n☣ Kirlilik: +%d" % [plant.name, price(i), plant.energy, plant.pollution]
		shops[i].disabled = phase not in ["build", "review"]
	planning_panel.visible = phase != "cards"
	map_panel.modulate = Color(0.55, 0.7, 0.76, 1.0) if phase == "cards" else Color.WHITE
	if phase == "build":
		build_title.text = "ŞEHRİ HAZIRLA"
	elif phase == "ended":
		build_title.text = "OYUN SONU"

func card_input(event: InputEvent) -> void:
	pass

func update_zones(offset: float) -> void:
	var strength := clampf(absf(offset) / 220.0, 0.0, 1.0)
	yes_zone.modulate = Color(1.0, 1.0, 1.0, 0.72 + (0.28 * strength if offset < 0 else 0.0))
	no_zone.modulate = Color(1.0, 1.0, 1.0, 0.72 + (0.28 * strength if offset > 0 else 0.0))

func snap_card() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_panel, "position", card_home_position, 0.26)
	tween.parallel().tween_property(card_panel, "rotation", 0.0, 0.26)
	update_zones(0.0)

func _input(event: InputEvent) -> void:
	if phase == "cards" and not decision_locked:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and card_panel.get_global_rect().has_point(event.position):
				dragging = true
				drag_origin = event.position
				card_origin = card_panel.position
				get_viewport().set_input_as_handled()
			elif not event.pressed and dragging:
				dragging = false
				var release_offset: float = card_panel.position.x - card_origin.x
				if absf(release_offset) >= swipe_threshold:
					choose("left" if release_offset < 0.0 else "right")
				else:
					snap_card()
				get_viewport().set_input_as_handled()
		elif event is InputEventMouseMotion and dragging:
			var offset_x: float = event.position.x - drag_origin.x
			var clamped_offset: float = clampf(offset_x, -get_viewport_rect().size.x * 0.9, get_viewport_rect().size.x * 0.9)
			card_panel.position = card_origin + Vector2(clamped_offset, absf(clamped_offset) * 0.025)
			card_panel.rotation = clampf(clamped_offset / 650.0, -0.28, 0.28)
			update_zones(clamped_offset)
			get_viewport().set_input_as_handled()
		elif event is InputEventScreenTouch:
			if event.pressed and card_panel.get_global_rect().has_point(event.position):
				dragging = true
				drag_origin = event.position
				card_origin = card_panel.position
			elif not event.pressed and dragging:
				dragging = false
				var touch_offset: float = card_panel.position.x - card_origin.x
				if absf(touch_offset) >= swipe_threshold:
					choose("left" if touch_offset < 0.0 else "right")
				else:
					snap_card()
		elif event is InputEventScreenDrag and dragging:
			var touch_x: float = event.position.x - drag_origin.x
			card_panel.position = card_origin + Vector2(touch_x, absf(touch_x) * 0.025)
			card_panel.rotation = clampf(touch_x / 650.0, -0.28, 0.28)
			update_zones(touch_x)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			choose("left")
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			choose("right")
		elif event.keycode == KEY_ESCAPE and phase == "cards":
			snap_card()
