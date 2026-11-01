class_name FateCardAdminPanel
extends PanelContainer

signal cards_changed

var repository := FateCardRepository.new()
var cards: Array[Dictionary] = []
var list: ItemList
var editor: VBoxContainer
var selected_index := -1
var fields: Dictionary = {}

func open() -> void:
	cards = repository.load_cards()
	_build()
	visible = true

func _build() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0d172b")
	style.border_color = Color("#29436a")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var heading := HBoxContainer.new()
	root.add_child(heading)
	var label := Label.new()
	label.text = "KART YÖNETİM PANELİ"
	label.add_theme_font_size_override("font_size", 24)
	heading.add_child(label)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(gap)
	var close := Button.new()
	close.text = "Kapat"
	close.pressed.connect(func(): visible = false)
	heading.add_child(close)
	var new_card := Button.new()
	new_card.text = "Yeni kart"
	new_card.pressed.connect(_new_card)
	heading.add_child(new_card)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	root.add_child(body)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(300, 0)
	list.item_selected.connect(_select_card)
	body.add_child(list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	editor = right
	_refresh_list()
	if not cards.is_empty():
		list.select(0)
		_select_card(0)

func _refresh_list() -> void:
	list.clear()
	for card in cards:
		var state := "AKTİF" if bool(card.get("active", true)) else "PASİF"
		list.add_item("%s  [%s]" % [str(card.get("title", "")), state])

func _select_card(index: int) -> void:
	selected_index = index
	for child in editor.get_children():
		child.queue_free()
	var card := cards[index]
	_add_field("Başlık", "title", str(card.get("title", "")))
	_add_field("Açıklama", "description", str(card.get("description", "")))
	_add_field("Kaynak", "source", str(card.get("source", "")))
	_add_field("Kategori", "category", str(card.get("category", "economy")))
	_add_field("İkon", "icon", str(card.get("icon", "✦")))
	_add_field("Ağırlık", "weight", str(card.get("weight", 1.0)))
	_add_multiline_field("EVET etkileri (JSON)", "yes_effects", JSON.stringify(card.get("yes_effects", {})))
	_add_multiline_field("HAYIR etkileri (JSON)", "no_effects", JSON.stringify(card.get("no_effects", {})))
	var active := CheckButton.new()
	active.text = "Kart aktif"
	active.button_pressed = bool(card.get("active", true))
	fields["active"] = active
	editor.add_child(active)
	var save := Button.new()
	save.text = "Değişiklikleri kaydet"
	save.pressed.connect(_save_selected)
	editor.add_child(save)
	var delete := Button.new()
	delete.text = "Kartı sil"
	delete.pressed.connect(_delete_selected)
	editor.add_child(delete)

func _add_field(caption: String, key: String, value: String) -> void:
	var label := Label.new()
	label.text = caption
	editor.add_child(label)
	var field := LineEdit.new()
	field.text = value
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields[key] = field
	editor.add_child(field)

func _add_multiline_field(caption: String, key: String, value: String) -> void:
	var label := Label.new()
	label.text = caption
	editor.add_child(label)
	var field := TextEdit.new()
	field.text = value
	field.custom_minimum_size = Vector2(0, 62)
	fields[key] = field
	editor.add_child(field)

func _save_selected() -> void:
	if selected_index < 0:
		return
	var card := cards[selected_index]
	for key in ["title", "description", "source", "category", "icon"]:
		card[key] = (fields[key] as LineEdit).text
	card["weight"] = maxf(0.01, float((fields["weight"] as LineEdit).text))
	card["active"] = (fields["active"] as CheckButton).button_pressed
	var yes_effects = JSON.parse_string((fields["yes_effects"] as TextEdit).text)
	var no_effects = JSON.parse_string((fields["no_effects"] as TextEdit).text)
	if yes_effects is Dictionary:
		card["yes_effects"] = yes_effects
	if no_effects is Dictionary:
		card["no_effects"] = no_effects
	if repository.upsert_card(card):
		cards = repository.load_cards()
		_refresh_list()
		cards_changed.emit()
		list.select(selected_index)
		_select_card(selected_index)

func _delete_selected() -> void:
	if selected_index < 0:
		return
	repository.delete_card(str(cards[selected_index].get("id", "")))
	cards = repository.load_cards()
	_refresh_list()
	cards_changed.emit()
	if cards.is_empty():
		selected_index = -1
	else:
		list.select(0)
		_select_card(0)

func _new_card() -> void:
	var id := "custom-card-%d" % Time.get_ticks_msec()
	var card := FateCardModels.from_dict({
		"id": id,
		"active": true,
		"category": "economy",
		"icon": "✦",
		"title": "Yeni kader kartı",
		"source": "Şehir konseyi",
		"description": "Yeni kararın şehir üzerindeki etkisini tanımlayın.",
		"weight": 1.0,
		"conditions": [],
		"yes_effects": {"budget": -1},
		"no_effects": {"happiness": -1}
	})
	if repository.upsert_card(card):
		cards = repository.load_cards()
		_refresh_list()
		list.select(cards.size() - 1)
		_select_card(cards.size() - 1)
		cards_changed.emit()
