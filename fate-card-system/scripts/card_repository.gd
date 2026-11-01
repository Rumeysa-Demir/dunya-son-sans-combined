class_name FateCardRepository
extends RefCounted

const CARDS_PATH := "res://data/fate_cards.json"

func load_cards() -> Array[Dictionary]:
	var file := FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file == null:
		push_error("Kart verisi açılamadı: %s" % CARDS_PATH)
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Kart verisi dizi formatında değil.")
		return []
	var result: Array[Dictionary] = []
	for item in parsed:
		if item is Dictionary:
			result.append(FateCardModels.from_dict(item))
	return result

func save_cards(cards: Array[Dictionary]) -> bool:
	var file := FileAccess.open(CARDS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Kart verisi yazılamadı: %s" % CARDS_PATH)
		return false
	file.store_string(JSON.stringify(cards, "\t"))
	return true

func upsert_card(card: Dictionary) -> bool:
	var cards := load_cards()
	for index in cards.size():
		if str(cards[index].get("id")) == str(card.get("id")):
			cards[index] = FateCardModels.from_dict(card)
			return save_cards(cards)
	cards.append(FateCardModels.from_dict(card))
	return save_cards(cards)

func delete_card(card_id: String) -> bool:
	var cards := load_cards()
	for index in range(cards.size() - 1, -1, -1):
		if str(cards[index].get("id")) == card_id:
			cards.remove_at(index)
	return save_cards(cards)
