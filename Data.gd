extends RefCounted
## Denge ve kart içeriği burada değiştirilir. Pozitif pollution = daha çok kirlilik.
const TURNS = 6
const START_MONEY = 100
const INCOME = 22
const PLANTS = [
	{"name": "Kömür", "cost": 20, "energy": 6, "pollution": 5},
	{"name": "Doğalgaz", "cost": 35, "energy": 7, "pollution": 3},
	{"name": "Güneş", "cost": 25, "energy": 3, "pollution": 0},
	{"name": "Rüzgâr", "cost": 40, "energy": 5, "pollution": 0}
]
## effects: money, pollution, support kalıcı anlık değişim;
## demand, energy ve discount sadece bu tur; saving kalıcı talep azaltımı.
## required: -1 = her zaman; 0..3 = o tür santral varsa.
const EVENTS = [
	{"title":"Halkın sabrı taşıyor","body":"Konut, fatura ve yaşam maliyeti baskısı mahallelerde protestolara dönüştü. Şimdi atacağın adım halk desteğini ve bütçeyi birlikte etkileyecek.","required":-1,"condition":{"stat":"support","operator":"<=","value":45},
	"left":{"text":"Acil sosyal paket","effects":{"money":-14,"support":18,"demand":2}},
	"right":{"text":"Güvenliği artır","effects":{"money":8,"support":-12,"pollution":3}}},
	{"title":"Hava alarmı","body":"Kirlilik kritik seviyeye yaklaşıyor. Şehir çevre birimleri acil önlem istiyor.","required":-1,"condition":{"stat":"pollution","operator":">=","value":55},
	"left":{"text":"Temiz hava seferberliği","effects":{"money":-12,"pollution":-18,"support":8,"energy":-2}},
	"right":{"text":"Üretimi sürdür","effects":{"money":18,"pollution":12,"support":-9}}},
	{"title":"Kömür santrali baskısı","body":"Sanayi lobisi, enerji açığını kapatmak için yeni bir kömür santrali kurulmasını istiyor. Kısa vadeli kazanç ile uzun vadeli bedel arasında seçim yapmalısın.","required":0,
	"left":{"text":"Santrali kur","effects":{"money":22,"energy":8,"pollution":15,"support":-6}},
	"right":{"text":"Temiz enerjiye yönel","effects":{"money":-8,"energy":2,"pollution":-4,"support":5,"saving":1}}},
	{"title":"Sanayi talebi","body":"Fabrikalar bu tur daha fazla elektrik istiyor.","required":-1,
	"left":{"text":"Sözleşmeyi kabul et","effects":{"money":18,"demand":4,"pollution":7,"support":-4}},
	"right":{"text":"Kapasiteyi koru","effects":{"support":-3,"money":-4,"pollution":-2}}},
	{"title":"Güneş teşviki","body":"Bu turluk indirim için belediye tanıtım bütçesini kullanabiliriz.","required":-1,
	"left":{"text":"Teşviği al","effects":{"discount":10,"support":-3}},
	"right":{"text":"Tanıtım bütçesini koru","effects":{"support":2}}},
	{"title":"Çevre denetimi","body":"Yeni filtreler mevcut kirliliği azaltabilir.","required":0,
	"left":{"text":"Filtre yatırımı yap","effects":{"money":-12,"pollution":-10,"support":6,"energy":-1}},
	"right":{"text":"Cezayı öde","effects":{"money":-6,"support":-3,"pollution":4}}},
	{"title":"Bakım zamanı","body":"Bakım ertelenirse bu tur toplam üretim 3 azalır.","required":-1,
	"left":{"text":"Bakım yaptır","effects":{"money":-8}},
	"right":{"text":"Üretim kaybını kabul et","effects":{"energy":-3}}},
	{"title":"Bilinçli tüketim","body":"Eğitim kampanyası enerji ihtiyacını kalıcı olarak 1 azaltır.","required":-1,
	"left":{"text":"Kampanya başlat","effects":{"money":-10,"saving":1,"support":2}},
	"right":{"text":"Ertele","effects":{"support":-2}}},
	{"title":"Eğitim seferberliği","body":"Şehir genelinde enerji ve çevre bilincini artıracak bir eğitim kampanyası başlatılabilir.","required":-1,
	"left":{"text":"Programı başlat","effects":{"money":-12,"support":8,"saving":1}},
	"right":{"text":"Bütçeyi koru","effects":{"money":6,"support":-5}}},
	{"title":"Gıda güvenliği","body":"Çiftçiler sulama için bu tur ek enerji istiyor.","required":-1,
	"left":{"text":"Sulamaya destek ver","effects":{"demand":2,"support":7}},
	"right":{"text":"Desteği reddet","effects":{"support":-5}}},
	{"title":"Denizleri koru","body":"Kıyıdaki atık suyu temizlemek için kaynak gerekiyor.","required":-1,
	"left":{"text":"Arıtmayı destekle","effects":{"money":-10,"pollution":-8,"support":3}},
	"right":{"text":"Ertele","effects":{"pollution":4,"support":-3}}},
	{"title":"Sıfır atık","body":"Geri dönüşüm merkezi kurmak ister misin?","required":-1,
	"left":{"text":"Merkezi destekle","effects":{"money":-8,"pollution":-6}},
	"right":{"text":"Bütçeyi koru","effects":{"pollution":2}}},
	{"title":"Sıcak hava","body":"Soğutma talebi arttı. Geçici tasarruf çağrısı yapabiliriz.","required":-1,
	"left":{"text":"Tasarruf çağrısı","effects":{"support":-4,"demand":-2}},
	"right":{"text":"Tüketimi serbest bırak","effects":{"demand":3,"support":2}}},
	{"title":"Rüzgârlı günler","body":"Türbinleri yoğun çalıştırmak için bakım ekibi gerekiyor.","required":3,
	"left":{"text":"Ekibi görevlendir","effects":{"money":-5,"energy":4}},
	"right":{"text":"Normal üretime devam","effects":{}}},
	{"title":"İklim dirençli şehir","body":"Yeşil alanlar kirliliği azaltır ve halkı memnun eder.","required":-1,
	"left":{"text":"Yeşil alan aç","effects":{"money":-12,"pollution":-5,"support":6}},
	"right":{"text":"Yeni vergi koy","effects":{"money":12,"support":-6}}},
	{"title":"Güneş paneli temizliği","body":"Panelleri temizleyerek bu tur üretimi artırabiliriz.","required":2,
	"left":{"text":"Temizlik yaptır","effects":{"money":-4,"energy":3}},
	"right":{"text":"Normal üretime devam","effects":{}}}
]
