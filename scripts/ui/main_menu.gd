extends Control
## Dünya: Son Şans — Ana Menü
## Tüm arayüz kodla kurulur (Main.gd ile aynı yaklaşım); sahne sadece bu betiği taşır.
## Sıra: Oyuna Başla → Ayarlar → COP31 Hakkında Bilgi Al → Çıkış

const GAME_SCENE := "res://Main.tscn"
const COP31_URL := "https://cop31.tr/tr"
const VIDEO_PATH := "res://assets/menu-arkaplan.ogv"
const SETTINGS_PATH := "user://settings.cfg"

# Oyunun mevcut renk paleti (Main.gd ile uyumlu)
const COL_BTN := Color("173b48")
const COL_BTN_HOVER := Color("246071")
const COL_PRIMARY := Color("28765c")
const COL_PRIMARY_HOVER := Color("34966f")
const COL_PANEL := Color("153b45")
const COL_ACCENT := Color("5ee0a0")
const COL_DANGER := Color("a8453b")
const COL_TEXT := Color("e8f4f0")
const COL_TEXT_SOFT := Color("a9c6c0")

var _video: VideoStreamPlayer
var _fade: ColorRect
var _menu_buttons: Array[Button] = []
var _start_btn: Button
var _settings_btn: Button
var _settings_overlay: Control
var _volume_slider: HSlider
var _volume_label: Label
var _fullscreen_check: CheckButton
var _busy := false

var _volume := 80.0
var _fullscreen := false


func _ready() -> void:
	_load_settings()
	_apply_volume(_volume)
	_apply_fullscreen(_fullscreen)
	_build_background()
	_build_menu()
	_build_settings_overlay()
	_build_fade()
	_play_intro()


# ---------------------------------------------------------------- Arka plan

func _build_background() -> void:
	var base := ColorRect.new()
	base.color = Color(0.025, 0.06, 0.1, 1)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)

	if ResourceLoader.exists(VIDEO_PATH):
		# 16:9 video, pencere oranı farklı olsa bile bozulmadan ekranı kaplasın
		var cover := AspectRatioContainer.new()
		cover.ratio = 16.0 / 9.0
		cover.stretch_mode = AspectRatioContainer.STRETCH_COVER
		cover.clip_contents = true
		cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cover)

		_video = VideoStreamPlayer.new()
		_video.stream = load(VIDEO_PATH)
		_video.expand = true
		_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_video.finished.connect(_video.play) # sonsuz döngü
		cover.add_child(_video)
		_video.play()

	# Soldan sağa koyulaşan perde: menü yazıları videonun üstünde okunaklı kalsın
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.85])
	grad.colors = PackedColorArray([
		Color(0.02, 0.05, 0.08, 0.94),
		Color(0.02, 0.05, 0.08, 0.62),
		Color(0.02, 0.05, 0.08, 0.0)
	])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0, 0)
	grad_tex.fill_to = Vector2(1, 0)
	grad_tex.width = 256
	grad_tex.height = 8
	var scrim := TextureRect.new()
	scrim.texture = grad_tex
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)


# ---------------------------------------------------------------- Ana menü

func _build_menu() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 460
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	# Başlık bloğu
	var badge := _label("GRUP 23", 16, COL_ACCENT)
	column.add_child(badge)
	var title_top := _label("DÜNYA:", 34, COL_TEXT)
	column.add_child(title_top)
	var title_main := _label("SON ŞANS", 78, Color.WHITE)
	title_main.add_theme_constant_override("line_spacing", -8)
	title_main.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	title_main.add_theme_constant_override("shadow_offset_x", 3)
	title_main.add_theme_constant_override("shadow_offset_y", 4)
	column.add_child(title_main)
	var tagline := _label("Şehrin enerjisini yönet, iklimi kaybetme.", 19, COL_TEXT_SOFT)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(tagline)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 30
	column.add_child(spacer)

	# Butonlar — istenen sıra
	_start_btn = _make_button("Oyuna Başla", true)
	_start_btn.pressed.connect(_on_start_pressed)
	column.add_child(_start_btn)

	_settings_btn = _make_button("Ayarlar")
	_settings_btn.pressed.connect(_open_settings)
	column.add_child(_settings_btn)

	var cop_btn := _make_button("COP31 Hakkında Bilgi Al")
	cop_btn.tooltip_text = "Tarayıcıda %s adresini açar" % COP31_URL
	cop_btn.pressed.connect(_on_cop31_pressed)
	column.add_child(cop_btn)

	var exit_btn := _make_button("Çıkış", false, true)
	exit_btn.pressed.connect(_on_exit_pressed)
	column.add_child(exit_btn)

	_menu_buttons = [_start_btn, _settings_btn, cop_btn, exit_btn]

	# Klavye / gamepad ile döngüsel gezinme (en alttan en üste)
	_start_btn.focus_neighbor_top = _start_btn.get_path_to(exit_btn)
	exit_btn.focus_neighbor_bottom = exit_btn.get_path_to(_start_btn)

	# Sol alt köşe: proje bilgisi
	var footer := _label("Dünya: Son Şans — Grup 23", 14, Color(1, 1, 1, 0.45))
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = 80
	footer.offset_top = -40
	footer.offset_right = 600
	footer.offset_bottom = -14
	add_child(footer)


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _box(color: Color, accent_left := 0, accent_color := COL_ACCENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(10)
	s.content_margin_left = 24
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	s.border_width_left = accent_left
	s.border_color = accent_color
	return s


func _make_button(text: String, primary := false, danger := false) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 60)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 21)

	var normal_col := COL_PRIMARY if primary else Color(COL_BTN, 0.88)
	var hover_col := COL_PRIMARY_HOVER if primary else (COL_DANGER if danger else COL_BTN_HOVER)
	var accent := Color.WHITE if danger else COL_ACCENT

	b.add_theme_stylebox_override("normal", _box(normal_col))
	b.add_theme_stylebox_override("hover", _box(hover_col, 5, accent))
	b.add_theme_stylebox_override("focus", _box(hover_col, 5, accent))
	b.add_theme_stylebox_override("pressed", _box(hover_col.darkened(0.2), 5, accent))
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)

	# Fare üstüne gelince odak da oraya geçsin: tek tip vurgu (fare + klavye)
	b.mouse_entered.connect(func() -> void:
		if b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
	)
	return b


# ---------------------------------------------------------------- Ayarlar paneli

func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP # arkadaki butonları engelle
	_settings_overlay.visible = false
	add_child(_settings_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 560
	var style := StyleBoxFlat.new()
	style.bg_color = COL_PANEL
	style.set_corner_radius_all(16)
	style.set_border_width_all(2)
	style.border_color = COL_PRIMARY
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	box.add_child(_label("AYARLAR", 32, Color.WHITE))

	# Ses
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 14)
	box.add_child(volume_row)
	var vol_title := _label("Ses", 20, COL_TEXT)
	vol_title.custom_minimum_size.x = 90
	volume_row.add_child(vol_title)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0
	_volume_slider.max_value = 100
	_volume_slider.step = 1
	_volume_slider.value = _volume
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.custom_minimum_size.y = 28
	_volume_slider.value_changed.connect(_on_volume_changed)
	volume_row.add_child(_volume_slider)
	_volume_label = _label("%d%%" % int(_volume), 20, COL_ACCENT)
	_volume_label.custom_minimum_size.x = 60
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(_volume_label)

	# Tam ekran
	_fullscreen_check = CheckButton.new()
	_fullscreen_check.text = "Tam ekran"
	_fullscreen_check.button_pressed = _fullscreen
	_fullscreen_check.add_theme_font_size_override("font_size", 20)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	box.add_child(_fullscreen_check)

	var close_btn := _make_button("Geri", true)
	close_btn.custom_minimum_size.y = 54
	close_btn.pressed.connect(_close_settings)
	box.add_child(close_btn)

	box.add_child(_label("Esc ile de kapatabilirsin", 14, COL_TEXT_SOFT))


func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


# ---------------------------------------------------------------- Animasyon

func _play_intro() -> void:
	create_tween().tween_property(_fade, "color:a", 0.0, 0.7)
	for i in range(_menu_buttons.size()):
		var b := _menu_buttons[i]
		b.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(b, "modulate:a", 1.0, 0.45).set_delay(0.35 + 0.1 * i)
	_start_btn.grab_focus.call_deferred()


# ---------------------------------------------------------------- Buton işlevleri

func _on_start_pressed() -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.45)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))


func _open_settings() -> void:
	_set_menu_focus(false)
	_settings_overlay.modulate.a = 0.0
	_settings_overlay.show()
	create_tween().tween_property(_settings_overlay, "modulate:a", 1.0, 0.18)
	_volume_slider.grab_focus()


func _close_settings() -> void:
	_settings_overlay.hide()
	_set_menu_focus(true)
	_settings_btn.grab_focus()


func _set_menu_focus(enabled: bool) -> void:
	for b in _menu_buttons:
		b.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _on_cop31_pressed() -> void:
	OS.shell_open(COP31_URL)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if _settings_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_settings()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- Ayarlar

func _on_volume_changed(value: float) -> void:
	_volume = value
	_volume_label.text = "%d%%" % int(value)
	_apply_volume(value)
	_save_settings()


func _on_fullscreen_toggled(pressed: bool) -> void:
	_fullscreen = pressed
	_apply_fullscreen(pressed)
	_save_settings()


func _apply_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, value <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.1) / 100.0))


func _apply_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_volume = float(cfg.get_value("audio", "volume", 80.0))
		_fullscreen = bool(cfg.get_value("display", "fullscreen", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", _volume)
	cfg.set_value("display", "fullscreen", _fullscreen)
	cfg.save(SETTINGS_PATH)
