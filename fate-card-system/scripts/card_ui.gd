class_name FateCardView
extends PanelContainer

signal decision_requested(decision: String)

var card: Dictionary
var swipe := FateCardSwipeController.new()
var drag_origin := Vector2.ZERO
var base_position := Vector2.ZERO
var dragging := false
var title_label: Label
var source_label: Label
var category_label: Label
var body_label: Label
var yes_label: Label
var no_label: Label

const COLORS := {
	"economy": Color("#ffc857"),
	"ecology": Color("#35e0a1"),
	"energy": Color("#43d9ff"),
	"society": Color("#c58cff")
}

func setup(data: Dictionary) -> void:
	card = data
	custom_minimum_size = Vector2(560, 650)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_style()
	_build_content()

func _build_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101b32")
	style.border_color = COLORS.get(str(card.get("category", "economy")), Color("#35e0a1"))
	style.set_border_width_all(2)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 24
	add_theme_stylebox_override("panel", style)

func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	category_label = Label.new()
	category_label.text = str(card.get("category", "economy")).to_upper()
	category_label.modulate = COLORS.get(str(card.get("category", "economy")), Color.WHITE)
	category_label.add_theme_font_size_override("font_size", 14)
	header.add_child(category_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var weight_label := Label.new()
	weight_label.text = "FATE // %s" % str(card.get("id", "")).to_upper()
	weight_label.modulate = Color("#7890b5")
	header.add_child(weight_label)
	source_label = Label.new()
	source_label.text = str(card.get("source", "Şehir konseyi"))
	source_label.modulate = Color("#8fa5c9")
	source_label.add_theme_font_size_override("font_size", 16)
	column.add_child(source_label)
	title_label = Label.new()
	title_label.text = str(card.get("title", "İsimsiz kart"))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 30)
	column.add_child(title_label)
	var art := ColorRect.new()
	art.custom_minimum_size = Vector2(0, 180)
	art.color = Color("#17294a")
	column.add_child(art)
	var art_text := Label.new()
	art_text.text = str(card.get("icon", "✦"))
	art_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	art_text.add_theme_font_size_override("font_size", 76)
	art_text.modulate = COLORS.get(str(card.get("category", "economy")), Color("#35e0a1"))
	art.add_child(art_text)
	body_label = Label.new()
	body_label.text = str(card.get("description", ""))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.modulate = Color("#d4def0")
	body_label.add_theme_font_size_override("font_size", 17)
	column.add_child(body_label)
	var divider := HSeparator.new()
	column.add_child(divider)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	column.add_child(choices)
	yes_label = _choice_label("←  EVET / ONAYLA", Color("#35e0a1"))
	no_label = _choice_label("HAYIR / REDDET  →", Color("#ff6685"))
	choices.add_child(yes_label)
	var choice_spacer := Control.new()
	choice_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_child(choice_spacer)
	choices.add_child(no_label)

func _choice_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 16)
	return label

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_origin = event.position
			base_position = position
			accept_event()
		else:
			if dragging:
				dragging = false
				var offset := position.x - base_position.x
				var decision := swipe.decision_for_offset(offset)
				if decision.is_empty():
					var tween := create_tween()
					tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property(self, "position", base_position, swipe.animation_duration)
					tween.parallel().tween_property(self, "rotation", 0.0, swipe.animation_duration)
				else:
					decision_requested.emit(decision)
				accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			drag_origin = event.position
			base_position = position
		elif dragging:
			dragging = false
			var touch_offset := position.x - base_position.x
			var touch_decision := swipe.decision_for_offset(touch_offset)
			if touch_decision.is_empty():
				var touch_tween := create_tween()
				touch_tween.tween_property(self, "position", base_position, swipe.animation_duration)
				touch_tween.parallel().tween_property(self, "rotation", 0.0, swipe.animation_duration)
			else:
				decision_requested.emit(touch_decision)
	elif event is InputEventMouseMotion and dragging:
		var offset_x: float = event.position.x - drag_origin.x
		position = base_position + Vector2(offset_x, absf(offset_x) * 0.04)
		rotation = deg_to_rad(clampf(offset_x / 20.0, -swipe.max_rotation_degrees, swipe.max_rotation_degrees))
		_update_feedback(offset_x)
		accept_event()

func _update_feedback(offset: float) -> void:
	var strength := clampf(absf(offset) / swipe.threshold, 0.0, 1.0)
	yes_label.modulate.a = 0.45 + (strength if offset < 0 else 0.0)
	no_label.modulate.a = 0.45 + (strength if offset > 0 else 0.0)
