class_name FateCardDeckManager
extends RefCounted

var condition_manager := FateCardConditionManager.new()

func draw_cards(cards: Array[Dictionary], stats: Dictionary, amount := 3) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for card in cards:
		if bool(card.get("active", true)) and condition_manager.is_available(card, stats):
			pool.append(card)
	var chosen: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	while not pool.is_empty() and chosen.size() < amount:
		var total := 0.0
		for card in pool:
			total += maxf(0.01, float(card.get("weight", 1.0)))
		var roll := rng.randf_range(0.0, total)
		var selected_index := 0
		for index in pool.size():
			roll -= maxf(0.01, float(pool[index].get("weight", 1.0)))
			if roll <= 0.0:
				selected_index = index
				break
		chosen.append(pool[selected_index])
		pool.remove_at(selected_index)
	return chosen
