class_name FateCardEffectManager
extends RefCounted

signal effects_applied(decision: String, effects: Dictionary, card_id: String)

func apply_decision(card: Dictionary, decision: String, stats: Dictionary) -> Dictionary:
	var effects: Dictionary = card.get("yes_effects", {}) if decision == "yes" else card.get("no_effects", {})
	for key in effects:
		stats[key] = float(stats.get(key, 0)) + float(effects[key])
	effects_applied.emit(decision, effects, str(card.get("id", "")))
	return effects.duplicate()

func clamp_stats(stats: Dictionary) -> void:
	for key in ["budget", "population", "energy", "energy_consumption", "ecology", "pollution", "happiness", "employment", "health", "fossil_dependency"]:
		stats[key] = clampi(int(stats.get(key, 0)), 0, 100)
