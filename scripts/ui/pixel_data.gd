extends RefCounted
## Otomatik üretildi: assets/pixel altındaki yatay sprite sheet'lerin kare sayısı, boyutu ve hızı.

const SHEETS := {
	"icon_money": {"frames": 8, "w": 48, "h": 48, "fps": 10},
	"icon_energy": {"frames": 8, "w": 48, "h": 48, "fps": 10},
	"icon_environment": {"frames": 8, "w": 48, "h": 48, "fps": 8},
	"icon_people": {"frames": 8, "w": 48, "h": 48, "fps": 6},
	"icon_pollution": {"frames": 8, "w": 48, "h": 48, "fps": 8},
	"plant_coal": {"frames": 12, "w": 66, "h": 96, "fps": 10},
	"plant_gas": {"frames": 12, "w": 66, "h": 90, "fps": 10},
	"plant_solar": {"frames": 12, "w": 66, "h": 55, "fps": 12},
	"plant_wind": {"frames": 12, "w": 66, "h": 82, "fps": 12},
	"portrait_engineer": {"frames": 8, "w": 80, "h": 104, "fps": 5},
	"portrait_environmentalist": {"frames": 8, "w": 80, "h": 104, "fps": 5},
	"portrait_farmer": {"frames": 8, "w": 80, "h": 104, "fps": 5},
	"portrait_industrialist": {"frames": 8, "w": 80, "h": 104, "fps": 5},
	"portrait_mayor": {"frames": 8, "w": 80, "h": 104, "fps": 5},
	"portrait_scientist": {"frames": 8, "w": 80, "h": 104, "fps": 5},
	"board_base": {"frames": 8, "w": 264, "h": 240, "fps": 6}
}


## Sheet'in tek bir karesini (varsayılan 0) statik doku olarak verir (buton ikonları için).
static func frame_texture(sheet_name: String, frame: int = 0) -> AtlasTexture:
	var info: Dictionary = SHEETS[sheet_name]
	var t := AtlasTexture.new()
	t.atlas = load("res://assets/pixel/%s_sheet.png" % sheet_name)
	t.region = Rect2(frame * int(info.w), 0, int(info.w), int(info.h))
	return t
