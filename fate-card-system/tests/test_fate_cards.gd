extends SceneTree

func _init() -> void:
	var repository := FateCardRepository.new()
	var cards := repository.load_cards()
	assert(cards.size() >= 10)
	var deck := FateCardDeckManager.new()
	var stats := {"budget": 72, "population": 48, "energy": 54, "energy_consumption": 42, "ecology": 51, "pollution": 32, "happiness": 63, "employment": 58, "health": 70, "fossil_dependency": 44}
	var drawn := deck.draw_cards(cards, stats, 3)
	assert(drawn.size() == 3)
	var ids := {}
	for card in drawn:
		assert(not ids.has(card["id"]))
		ids[card["id"]] = true
	var effects := FateCardEffectManager.new()
	var before: float = float(stats["budget"])
	effects.apply_decision(drawn[0], "yes", stats)
	assert(stats["budget"] != before or drawn[0]["yes_effects"].is_empty())
	print("Fate Cards tests passed: %d cards loaded, %d unique drawn." % [cards.size(), drawn.size()])
	quit()
