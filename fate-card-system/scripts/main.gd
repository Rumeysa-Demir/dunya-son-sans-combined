extends Control

var repository := FateCardRepository.new()
var deck_manager := FateCardDeckManager.new()
var effect_manager := FateCardEffectManager.new()
var cards: Array[Dictionary] = []
var round_cards: Array[Dictionary] = []
var current_index := 0
var stats := {
	"budget": 72, "population": 48, "energy": 54, "energy_consumption": 42,
	"ecology": 51, "pollution": 32, "happiness": 63, "employment": 58,
	"health": 70, "fossil_dependency": 44
}
var card_host: Control
var status_label: Label
var progress_label: Label
var stats_grid: GridContainer
var start_button: Button
var yes_button: Button
var no_button: Button
var admin: FateCardAdminPanel

const BG := Color("#07101f")
const TEXT_MUTED := Color("#8296b8")

func _ready() -> void:
	cards = repository.load_cards()
	effect_manager.effects_applied.connect(_on_effects_applied)
	_build_shell()
	_render_stats()

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var glow := ColorRect.new()
	glow.color = Color("#0b2031")
	glow.position = Vector2(0, 0)
	glow.size = Vector2(420, 900)
	add_child(glow)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var brand := Label.new()
	brand.text = "CITY GRID  /  FATE PROTOCOL"
	brand.add_theme_font_size_override("font_size", 21)
	brand.modulate = Color("#43d9ff")
	top.add_child(brand)
	var top_gap := Control.new()
	top_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(top_gap)
	var admin_button := Button.new()
	admin_button.text = "Kart Yönetimi"
	admin_button.pressed.connect(_open_admin)
	top.add_child(admin_button)
	var main_content := HBoxContainer.new()
	main_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_content.add_theme_constant_override("separation", 30)
	root.add_child(main_content)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	main_content.add_child(left)
	var phase := Label.new()
	phase.text = "KADER AŞAMASI"
	phase.modulate = Color("#35e0a1")
	phase.add_theme_font_size_override("font_size", 14)
	left.add_child(phase)
	var title := Label.new()
	title.text = "Şehrin geleceği\nsenin kararın."
	title.add_theme_font_size_override("font_size", 34)
	left.add_child(title)
	status_label = Label.new()
	status_label.text = "Üç kart arasından kararlarını ver."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = TEXT_MUTED
	status_label.add_theme_font_size_override("font_size", 16)
	left.add_child(status_label)
	progress_label = Label.new()
	progress_label.text = "Hazır"
	progress_label.modulate = Color("#ffc857")
	progress_label.add_theme_font_size_override("font_size", 20)
	left.add_child(progress_label)
	var stats_title := Label.new()
	stats_title.text = "ŞEHİR GÖSTERGELERİ"
	stats_title.modulate = Color("#7890b5")
	left.add_child(stats_title)
	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 12)
	stats_grid.add_theme_constant_override("v_separation", 7)
	left.add_child(stats_grid)
	var left_gap := Control.new()
	left_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(left_gap)
	start_button = Button.new()
	start_button.text = "Yeni kader aşaması başlat"
	start_button.custom_minimum_size = Vector2(0, 52)
	start_button.pressed.connect(_start_round)
	left.add_child(start_button)
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_content.add_child(center)
	card_host = Control.new()
	card_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(card_host)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 18)
	center.add_child(controls)
	yes_button = Button.new()
	yes_button.text = "←  EVET / ONAYLA"
	yes_button.custom_minimum_size = Vector2(220, 48)
	yes_button.modulate = Color("#35e0a1")
	yes_button.pressed.connect(func(): _decide("yes"))
	controls.add_child(yes_button)
	no_button = Button.new()
	no_button.text = "HAYIR / REDDET  →"
	no_button.custom_minimum_size = Vector2(220, 48)
	no_button.modulate = Color("#ff6685")
	no_button.pressed.connect(func(): _decide("no"))
	controls.add_child(no_button)
	var hint := Label.new()
	hint.text = "Kartı tutup sürükle  •  A / ← = EVET  •  D / → = HAYIR"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color("#52698e")
	center.add_child(hint)

func _render_stats() -> void:
	if stats_grid == null:
		return
	for child in stats_grid.get_children():
		child.queue_free()
	for key in ["budget", "population", "energy", "ecology", "pollution", "happiness", "health", "fossil_dependency"]:
		var name := Label.new()
		name.text = FateCardModels.STAT_NAMES[key]
		name.modulate = TEXT_MUTED
		stats_grid.add_child(name)
		var value := Label.new()
		value.text = str(int(stats[key]))
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.modulate = _stat_color(key, float(stats[key]))
		stats_grid.add_child(value)

func _stat_color(key: String, value: float) -> Color:
	if key in ["pollution", "fossil_dependency"]:
		return Color("#ff6685") if value > 60 else Color("#ffc857")
	return Color("#35e0a1") if value >= 50 else Color("#ffc857")

func _start_round() -> void:
	round_cards = deck_manager.draw_cards(cards, stats, 3)
	current_index = 0
	start_button.disabled = true
	yes_button.disabled = false
	no_button.disabled = false
	status_label.text = "Kartı incele ve şehrin için bir yön seç."
	_show_current_card()

func _show_current_card() -> void:
	for child in card_host.get_children():
		child.queue_free()
	if current_index >= round_cards.size():
		_finish_round()
		return
	progress_label.text = "KART  %d / %d" % [current_index + 1, round_cards.size()]
	var card_view := FateCardView.new()
	card_view.setup(round_cards[current_index])
	card_view.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card_view.position -= card_view.custom_minimum_size / 2.0
	card_view.decision_requested.connect(_decide)
	card_host.add_child(card_view)

func _decide(decision: String) -> void:
	if current_index >= round_cards.size():
		return
	var card := round_cards[current_index]
	var effects := effect_manager.apply_decision(card, decision, stats)
	effect_manager.clamp_stats(stats)
	_render_stats()
	status_label.text = "%s seçildi: %s" % ["EVET" if decision == "yes" else "HAYIR", ", ".join(FateCardModels.format_effects(effects))]
	current_index += 1
	await get_tree().create_timer(0.22).timeout
	_show_current_card()

func _on_effects_applied(_decision: String, _effects: Dictionary, _card_id: String) -> void:
	pass

func _finish_round() -> void:
	progress_label.text = "AŞAMA TAMAMLANDI"
	start_button.disabled = false
	yes_button.disabled = true
	no_button.disabled = true
	status_label.text = "Üç karar işlendi. Sonuçlar ana oyuna aktarılmaya hazır."

func _open_admin() -> void:
	if admin == null:
		admin = FateCardAdminPanel.new()
		admin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		admin.position = Vector2(120, 80)
		admin.size = Vector2(1200, 730)
		admin.cards_changed.connect(func(): cards = repository.load_cards())
		add_child(admin)
	admin.open()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_A, KEY_LEFT]:
		_decide("yes")
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_D, KEY_RIGHT]:
		_decide("no")
