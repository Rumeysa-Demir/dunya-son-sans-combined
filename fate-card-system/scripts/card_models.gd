class_name FateCardModels
extends RefCounted

const STAT_NAMES := {
	"budget": "Bütçe",
	"population": "Nüfus",
	"energy": "Enerji",
	"energy_consumption": "Enerji tüketimi",
	"ecology": "Ekoloji",
	"pollution": "Kirlilik",
	"happiness": "Mutluluk",
	"employment": "İstihdam",
	"fossil_dependency": "Fosil bağımlılığı"
}

static func from_dict(raw: Dictionary) -> Dictionary:
	var card := raw.duplicate(true)
	card["id"] = str(card.get("id", "unnamed"))
	card["active"] = bool(card.get("active", true))
	card["weight"] = float(card.get("weight", 1.0))
	card["category"] = str(card.get("category", "economy"))
	card["conditions"] = card.get("conditions", [])
	card["yes_effects"] = card.get("yes_effects", {})
	card["no_effects"] = card.get("no_effects", {})
	return card

static func format_effects(effects: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in effects:
		var amount := float(effects[key])
		var sign := "+" if amount >= 0 else ""
		result.append("%s %s%s" % [STAT_NAMES.get(key, key), sign, _number(amount)])
	return result

static func _number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(value))
	return "%.1f" % value
