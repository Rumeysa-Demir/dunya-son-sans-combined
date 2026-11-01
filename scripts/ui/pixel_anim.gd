extends TextureRect
## Yatay sprite sheet'ten kare kare animasyon oynatır (pixel art için NEAREST filtre).

const PixelData = preload("res://scripts/ui/pixel_data.gd")

var _atlas := AtlasTexture.new()
var _frames := 1
var _fw := 1
var _fh := 1
var _fps := 8.0
var _time := 0.0
var _frame := -1
var _sheet_name := ""


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture = _atlas


## native_size = true: düğüm sprite'ın gerçek piksel boyutuna ayarlanır (tahtadaki santraller).
func play_sheet(sheet_name: String, native_size: bool = false) -> void:
	if sheet_name == _sheet_name:
		return
	var info: Dictionary = PixelData.SHEETS[sheet_name]
	_sheet_name = sheet_name
	_atlas.atlas = load("res://assets/pixel/%s_sheet.png" % sheet_name)
	_frames = int(info.frames)
	_fw = int(info.w)
	_fh = int(info.h)
	_fps = float(info.fps)
	_time = randf() * float(_frames) / _fps # birden çok sprite aynı anda senkron oynamasın
	if native_size:
		custom_minimum_size = Vector2(_fw, _fh)
		size = Vector2(_fw, _fh)
	_set_frame(0)


func _process(delta: float) -> void:
	if _frames <= 1 or not is_visible_in_tree():
		return
	_time += delta
	var f := int(_time * _fps) % _frames
	if f != _frame:
		_set_frame(f)


func _set_frame(f: int) -> void:
	_frame = f
	_atlas.region = Rect2(f * _fw, 0, _fw, _fh)
