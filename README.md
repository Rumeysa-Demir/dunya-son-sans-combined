# Dünya: Son Şans — Fate Cards birleşik demo

Godot 4 ile hazırlanan oynanabilir City Grid / şehir kurma demosu. Şehir inşası, enerji dengesi, kirlilik ve halk desteği canlı bir simülasyon akışında çalışır. Kritik koşullar oluştuğunda kader kartları merkezde, referans görseldeki gibi tam ekran olay katmanı içinde gösterilir.

## Çalıştırma

1. Godot 4.3 veya üzeriyle `project.godot` dosyasını açın.
2. **Run Project** seçin.
3. Haritadaki boş hücrelere santral yerleştirin.
4. Şehri normal şekilde kurmaya devam edin. Her üç yeni santral kurulduğunda iki kartlık karar zinciri anında açılır.
5. Kartı sola sürükleyerek EVET, sağa sürükleyerek HAYIR seçin. Butonlar, A/D ve sol/sağ ok tuşları aynı karar yolunu kullanır.
6. Karar tamamlanınca kart kapanır ve canlı şehir simülasyonu otomatik olarak devam eder.
7. Kurulu bir santrali kapattığınızda, o santral için gerçekten ödenen kurulum ücretinin %50'si bütçeye iade edilir.

## Görsel akış

- Üst HUD: bütçe, enerji arzı, kirlilik ve halk desteği.
- Ana ekran: 4×4 şehir planlama ağı ve santral seçimi.
- Ağın genişletme alanı: kıyı bölgesi, zehirli orman, çorak arazi ve su havzası için dört görsel arazi hücresi.
- Kader aşaması: oyun alanını karartan, ortada portreli ve neon çerçeveli kart; iki yanda sabit yükseklikte karar bölgeleri ve arkada deste görünümü.
- Kart görsel dili: paslı metal kabuk, amber/teal durum ışıkları, hazard şeritleri, ağır gölgeler ve çevre aktivisti portreleriyle distopik sci-fi/fantasy-punk sunum.
- Karar kartları referans kompozisyonuna göre üç parçalıdır: ortada olay görseli, solda yeşil EVET/ONAYLA ve sağda kırmızı HAYIR/REDDET paneli; neon amblem ve parıltı katmanları karar yönünü belirginleştirir.
- Karar panelleri ve merkez olay alanı ayrı raster görseller kullanır; kart metinleri referans görünümüne yakın yüksek kontrastlı display font ile çizilir ve merkez portre yerine olay illüstrasyonu gösterilir.
- Merkez olay görselleri yalnızca kullanıcı tarafından sağlanan dokuz görselden seçilir: `card_reference.jpeg`, `card_public.jpeg`, `card_recycling.jpeg`, `card_education.jpeg`, `card_conscious_consumption.jpeg`, `card_filters.jpeg`, `card_green_space.jpeg`, `card_solar_panels.jpeg` ve `card_cooling.jpeg`. Filtre, yeşil alan, panel bakımı ve soğutma kartları ilgili görselleri kullanır; üretilen tema görselleri olay kartlarında kullanılmaz.
- Kart tipografisi `assets/Fonts/FateCardTypography.tres` üzerinden merkezileştirilmiştir: Oxanium başlık/karar yazılarında, Rajdhani kategori ve teknik etiketlerde, Exo 2 açıklama ve etkilerde kullanılır. Font dosyaları `assets/Fonts/` altında tutulur ve Türkçe karakter fallback'iyle yüklenir.
- Metin alanları artık görselden ayrılmış koyu kart yüzeyinde gösterilir; kamu/halk/sanayi/gıda/toplum temalı kartlar `assets/card_public.jpeg` içindeki sağlanan görseli kullanır.
- Kaydırma sırasında kart doğrudan pointer/touch konumunu izler; kart açısı, konumu ve karar bölgelerinin parlaklığı değişir. Eşik altı hareket kartı yerine akıcı şekilde geri döner, eşik aşılınca ekran dışına animasyonla çıkar.
- Kart yüksekliği viewport'a göre hesaplanır; alt içerik ekrandan taşmaz. EVET/HAYIR metinleri karar panellerinde ve kart altındaki kısa özette ayrı tutulur.
- Her olay zinciri iki kart içerir. Başlangıçta verilen iki santral kilometre taşına dahil değildir; oyuncunun kurduğu her üç yeni santralden sonra kartlar anında açılır.

## Dosya yapısı

- `Main.gd`: birleşik oynanabilir oyun, canlı simülasyon akışı ve kader kartı sunumu. Başlangıç bütçesi ve canlı gelir dengesi uzun oyun oturumları için ayarlanmıştır.
- `Data.gd`: santraller, kartlar ve denge değerleri. Kartlar bütçe, enerji, kirlilik, halk desteği ve talebi birlikte etkileyebilir.
- `assets/`: oyun ikonları, portreler, santral ve arazi görselleri.
- `fate-card-system/`: önceki bağımsız, JSON tabanlı Fate Cards modülleri, yönetim paneli ve entegrasyon örnekleri.

Kart etkileri ana oyunun kaynaklarına doğrudan uygulanır; harita ve bina sistemleri kart arayüzünden ayrıdır. Bu sayede `Data.gd` içindeki olay metinleri/etkileri değiştirilebilir.
