# City Grid entegrasyon notları

Bu proje ana oyunun haritasına, binalarına veya kaynak sınıflarına bağımlı değildir.

```gdscript
var repository := FateCardRepository.new()
var deck := FateCardDeckManager.new()
var effects := FateCardEffectManager.new()
var cards := repository.load_cards()
var phase_cards := deck.draw_cards(cards, city_stats, 3)

for card in phase_cards:
    # UI kararı geldiğinde:
    var changed := effects.apply_decision(card, "yes", city_stats)
    effects.clamp_stats(city_stats)
    city_event_bus.emit_signal("fate_card_decided", card["id"], changed)

city_event_bus.emit_signal("fate_phase_completed", city_stats)
```

`city_stats` yalnızca sayısal bir sözlük olmalıdır. Ana oyun, bu sözlükteki değişimleri kendi kaynak/harita sistemine uygulayabilir. Böylece kart başlığı, illüstrasyonu veya metni değiştiğinde etki kodu değişmez.
