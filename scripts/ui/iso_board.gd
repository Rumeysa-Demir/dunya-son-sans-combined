extends Control
## 4×4 izometrik (2.5D) pixel-art arazi. Tıklama / hover hesabı izometrik ters dönüşümle yapılır.
## Hücre indeksi: satır * 4 + sütun  (Main.gd'deki board dizisiyle aynı).

signal cell_pressed(index: int)
signal cell_hovered(index: int) # imleç tahtadan çıkınca -1
signal plant_pressed(index: int)

const PixelAnim = preload("res://scripts/ui/pixel_anim.gd")

const SCALE := 2.3                    # arazi panelini daha dolu göstermek için ölçek
const OX := 132                       # 0,0 karesinin üst köşesi (tuval pikseli)
const OY := 80
const CANVAS := Vector2(264, 240)
const PLANT_SHEETS := ["plant_coal", "plant_gas", "plant_solar", "plant_wind"]

var pointer_cell := -1                # imlecin altındaki hücre

var _canvas: Control
const LIFT_HEIGHT := 5.0              # hover'da karenin yükselme miktarı (piksel)

var _shadow: TextureRect
var _lift: TextureRect
var _lift_ok: Texture2D = load("res://assets/pixel/tile_lift.png")
var _lift_bad: Texture2D = load("res://assets/pixel/tile_lift_bad.png")
var _lift_tween: Tween
var _plant_lift_tween: Tween
var _shown_index := -1
var _shown_usable := true
var _plants: Array = []
var _kinds: Array = []
var _plants_lifted := false
var _selected_plant := -1


func _ready() -> void:
	custom_minimum_size = CANVAS * SCALE
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_canvas = Control.new()
	_canvas.size = CANVAS
	_canvas.scale = Vector2(SCALE, SCALE)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)

	var base := PixelAnim.new()
	_canvas.add_child(base)
	base.play_sheet("board_base", true)

	_shadow = _make_tile_rect(load("res://assets/pixel/tile_shadow.png"), Vector2(64, 32))
	_lift = _make_tile_rect(_lift_ok, Vector2(64, 38))

	# Arkadan öne doğru ekle: öndeki santral arkadakini doğru şekilde kapatsın
	var order: Array = range(16)
	order.sort_custom(func(a: int, b: int) -> bool: return _depth_key(a) < _depth_key(b))
	_plants.resize(16)
	_kinds.resize(16)
	_kinds.fill(-1)
	for i in order:
		var p := PixelAnim.new()
		p.visible = false
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(p)
		_plants[i] = p


func _make_tile_rect(tex: Texture2D, tile_size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size = tile_size
	t.visible = false
	_canvas.add_child(t)
	return t


func _depth_key(i: int) -> int:
	var row := i >> 2
	var col := i & 3
	return (row + col) * 10 + col


func _tile_top(i: int) -> Vector2:
	var row := i >> 2
	var col := i & 3
	return Vector2(OX + (col - row) * 32, OY + (col + row) * 16)


## board: Main.gd'deki dizi (-1 = boş, 0..3 = santral türü).
func set_board(board: Array, _interactive: bool = true) -> void:
	for i in range(16):
		var kind: int = board[i]
		if kind == _kinds[i]:
			continue
		_kinds[i] = kind
		var p = _plants[i]
		if kind < 0:
			p.visible = false
			continue
		p.play_sheet(PLANT_SHEETS[kind], true)
		var top := _tile_top(i)
		p.position = Vector2(round(top.x - p.size.x / 2.0), top.y + 34.0 - p.size.y)
		p.visible = true
		_apply_plant_tint(i)
		_pop(p)

func set_plant_selection(index: int) -> void:
	_selected_plant = index
	for i in range(_plants.size()):
		if _kinds[i] >= 0:
			_apply_plant_tint(i)
	if index >= 0 and index < _plants.size() and _kinds[index] >= 0:
		_lift_selected_plant(index)

func _apply_plant_tint(index: int) -> void:
	if index < 0 or index >= _plants.size() or _kinds[index] < 0:
		return
	var plant: Control = _plants[index]
	if _selected_plant >= 0:
		plant.modulate = Color("#f4fff8") if index == _selected_plant else Color("#526875")
	else:
		plant.modulate = Color.WHITE

func _lift_selected_plant(index: int) -> void:
	var plant: Control = _plants[index]
	var top := _tile_top(index)
	var base_y := top.y + 34.0 - plant.size.y
	if _plant_lift_tween:
		_plant_lift_tween.kill()
	_plant_lift_tween = create_tween()
	_plant_lift_tween.tween_property(plant, "position:y", base_y - 24.0, 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_plants_lifted(lifted: bool) -> void:
	if lifted == _plants_lifted:
		return
	_plants_lifted = lifted
	var tween := create_tween().set_parallel(true)
	for i in range(_plants.size()):
		if _kinds[i] < 0:
			continue
		var plant: Control = _plants[i]
		var top := _tile_top(i)
		var base_y := top.y + 34.0 - plant.size.y
		tween.tween_property(plant, "position:y", base_y - (14.0 if lifted else 0.0), 0.16) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pop(p: Control) -> void:
	var end_y := p.position.y
	p.position.y = end_y - 18.0
	p.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(p, "position:y", end_y, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(p, "modulate:a", 1.0, 0.12)


## index < 0: gizle. Aksi halde o kare gölgesiyle birlikte hafifçe havaya kalkar.
## usable: kurulabilir mi (açık çerçeve) / değil mi (kırmızı çerçeve).
func show_hover(index: int, usable: bool) -> void:
	if index == _shown_index and (index < 0 or usable == _shown_usable):
		return # aynı durum: animasyonu baştan başlatma
	if not _plants_lifted and _shown_index >= 0 and _shown_index < _plants.size() and _kinds[_shown_index] >= 0:
		_reset_plant_lift(_shown_index)
	_shown_index = index
	_shown_usable = usable
	if _lift_tween:
		_lift_tween.kill()
	if index < 0:
		_lift.visible = false
		_shadow.visible = false
		return
	# Not: _tile_top karenin ÜST KÖŞESİ; 64 px'lik sprite'ın sol kenarı 32 px solda.
	var origin := _tile_top(index) - Vector2(32, 0)
	_shadow.position = origin
	_shadow.visible = true
	_lift.texture = _lift_ok if usable else _lift_bad
	_lift.position = origin
	_lift.visible = true
	_lift_tween = create_tween()
	_lift_tween.tween_property(_lift, "position:y", origin.y - LIFT_HEIGHT, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _kinds[index] >= 0:
		var plant: Control = _plants[index]
		var top := _tile_top(index)
		var base_y := top.y + 34.0 - plant.size.y
		if _plant_lift_tween:
			_plant_lift_tween.kill()
		_plant_lift_tween = create_tween()
		_plant_lift_tween.tween_property(plant, "position:y", base_y - 14.0, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _reset_plant_lift(index: int) -> void:
	if index < 0 or index >= _plants.size() or _kinds[index] < 0:
		return
	var plant: Control = _plants[index]
	var top := _tile_top(index)
	var base_y := top.y + 34.0 - plant.size.y
	if _plant_lift_tween:
		_plant_lift_tween.kill()
	_plant_lift_tween = create_tween()
	_plant_lift_tween.tween_property(plant, "position:y", base_y, 0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _pick(pos: Vector2) -> int:
	var p := pos / float(SCALE) - Vector2(OX, OY)
	var c := (p.x / 32.0 + p.y / 16.0) / 2.0
	var r := (p.y / 16.0 - p.x / 32.0) / 2.0
	if c < 0.0 or r < 0.0 or c >= 4.0 or r >= 4.0:
		return -1
	return int(r) * 4 + int(c)

func _plant_at(pos: Vector2) -> int:
	var local_pos := pos / float(SCALE)
	var order: Array = range(16)
	order.sort_custom(func(a: int, b: int) -> bool: return _depth_key(a) > _depth_key(b))
	for i in order:
		if _kinds[i] < 0 or not _plants[i].visible:
			continue
		if Rect2(_plants[i].position, _plants[i].size).has_point(local_pos):
			return i
	return -1


func _set_pointer(i: int) -> void:
	if i == pointer_cell:
		return
	pointer_cell = i
	cell_hovered.emit(i)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_pointer(_pick(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var plant_index := _plant_at(event.position)
		if plant_index >= 0:
			plant_pressed.emit(plant_index)
			return
		var i := _pick(event.position)
		if i >= 0:
			if _kinds[i] >= 0:
				plant_pressed.emit(i)
			else:
				cell_pressed.emit(i)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_pointer(-1)
