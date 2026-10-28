# MacDPI — Kolay kurulum (v1.6.1)

**Sadece Mac içindir. Windows paketinden ayrıdır.**

## İlk kez kuruyorsan veya eski sürümü güncelliyorsan

1. [MacDPI-OneClick-v1.6.1.zip dosyasını indir](https://github.com/welosu06/MacDPI-OneClick/releases/download/v1.6.1/MacDPI-OneClick-v1.6.1.zip).
2. **İndirilenler** klasörünü aç. ZIP dosyasına **iki kez tıkla**. Bir klasör çıkacak.
3. Çıkan **MacDPI-OneClick-v1.6.1** klasörünü aç.
4. İçindeki **MacDPI.command** dosyasını aç. Terminal penceresinin açılması normaldir.
5. Menüde **1** yaz ve **Enter** tuşuna bas. Eski sürümün olsa da güncellemek için **1** seç.
6. Mac giriş şifren istenirse yaz ve **Enter** tuşuna bas. **Yazarken ekranda harf veya yıldız görünmez; bu normaldir.**
7. Kurulum bitene kadar pencereyi kapatma. İlk kurulum internet hızına göre birkaç dakika sürebilir.
8. Kurulum başarılı olduğunda Discord'u tamamen kapatıp yeniden aç.

**GitHub'da “Source code” dosyalarını değil, `MacDPI-OneClick-v1.6.1.zip` dosyasını indir.**

### Mac dosyayı açtırmazsa

Önce dosyaya sağ tıkla → **Aç** seç. Hâlâ izin vermiyorsa **Sistem Ayarları → Gizlilik ve Güvenlik** bölümündeki bu dosyaya ait **Yine de Aç** seçeneğini kullan. Bu adım yalnızca dosyanın geliştiricisinin doğrulanamadığı uyarısı içindir. “Kötü amaçlı yazılım” veya “bilgisayarınıza zarar verecek” uyarısı varsa dur; güvenlik korumasını kapatma.

### Sonraki kullanımlarda

Masaüstündeki **MacDPI** kısayolunu aç:

- **2 + Enter:** DPI'yi aç.
- **3 + Enter:** DPI'yi kapat.
- **4 + Enter:** Bağlantıyı kontrol et.
- **7 + Enter:** İnternet sorunu olursa ağ ayarlarını kurtar.

Kurulum servis olarak çalışır. Mac açıldığında Wi-Fi/IP hazır olana kadar bekler;
DPI bileşenlerinden biri kapanırsa kendini yeniden başlatır. Terminal menüsünü
kapatmak DPI'yi kapatmaz; kapatmak için **3** seç.

## Bu sürümde ne düzeldi?

Mac yeniden açıldıktan sonra internet için DPI'yi elle kapatıp açma sorunu için
başlangıçta ağ bekleme ve bileşen takibi eklendi. Önceki Discord güncelleme düzeltmeleri korundu.
Kullanıcı kendi Mac'inde düzeltmenin işe yaradığını bildirdi; tüm Mac modelleri/ağlar ve Discord sesli kanal bağlantıları test edilmiş değildir.

---

## Teknik ayrıntılar ve kurtarma

## Menü

| Seçenek | İşlem |
| --- | --- |
| 1 | Bu paketi kur / yükselt |
| 2 | DPI'yi aç |
| 3 | DPI'yi kapat, yedeklenen ağ ayarını geri yükle |
| 4 | Genel internet ve Discord güncelleme erişimini kontrol et |
| 5 | Kurulumu bu sürümün yamalarıyla onar |
| 6 | Kaldır |
| 7 | Ağı kurtar |
| 8 | Maskelenmiş tanılama raporu oluştur |
| 0 | Menüden çık |

Terminal'i kapatmak arka plan servisini durdurmaz; kapatmak için **3** kullan.

## Düzeltilen sorunlar

- **TUN uyumluluğu:** gVisor ağ yığını ve fiziksel arayüz bağlama birlikte kullanılır.
- **Proxy yönlendirmesi:** ciadpi'nin dış bağlantıları gerçek ağ arayüzüne bağlanır. Arayüz bulunamazsa işlem hata verir.
- **Discord'un TLS bağlantısı:** varsayılan yöntem `-I 0.0.0.0 --split 2` oldu. Sorunun yaşandığı Mac'te `split 1` sıradan curl testinde çalışsa da uygulamanın kullandığı macOS TLS altyapısında çalışmıyordu.
- **DNS:** aktifken ağ servisinin DNS'i `1.1.1.1` olur, eski DNS önbelleği temizlenir; TUN DNS sorgularını şifreli DNS'e yönlendirir. Önceki ağ/DNS ayarları yedeklenir.
- **IP:** varsayılan olarak `.240` statik IP'ye geçilmez; mevcut DHCP/manuel IP korunur.
- **Kurulum/Onar:** yamalar pakette ve kurulu başlatıcıda saklanır; yeniden derlemede kaybolmaz.
- **İşlem kilidi:** başarısız kurulum Enter beklemeden kendi kilidini bırakır; başka işlemin kilidini silemez.
- **Sağlık kontrolü:** genel internet ile Discord güncelleme erişimi ayrı gösterilir. Discord testi sertifika kontrolünü kapatmaz.

## Doğrulama kapsamı

Sorunun yeniden üretildiği Apple Silicon Mac'te genel HTTPS ve Discord'un yerel TLS testi başarılı oldu; Discord güncellemeleri tamamlayıp açıldı. Sesli kanal/UDP bağlantısı bu güncelleme testiyle doğrulanmış değildir. Her ağ ve ISS için başarı garantisi verilmez.

Paket testleri temiz kaynakta yama uygulama, tekrar onarım, yanlış sürümün reddi, yerel proxy derleme, loopback arayüz bağlama, geçersiz arayüzün reddi, yeni paketin eski kurulumdan önce seçilmesi, kilit sahipliği ve ZIP izinlerini kontrol eder. CI, gerçek ISS engellemesini veya sistem genelinde TUN bağlantısını taklit etmez.

Varsayılan bypass IPv4 soketleri kullanır. Yalnızca IPv6 olan ağlar, VPN üzerinden varsayılan rota, kurumsal ağlar ve captive portal ortamları ayrıca değerlendirilmelidir. Ağ arayüzü değiştiğinde DPI'yi kapatıp yeniden aç. Intel derleme hedefidir; burada belirtilen uçtan uca Discord doğrulaması Apple Silicon üzerinde yapıldı.

## Kaynak ve kurtarma

MacDPI `30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`, ByeDPI `ba532298de7b28cfe854aea83d061369d13ca290` ve sing-box `v1.13.14` kullanılır. İncelenebilir yamalar `patches/` klasöründedir. Pakete kullanıcı adı, özel ağ adresi veya kişisel log eklenmez.

Normal internet bozulursa **7 — Ağı Kurtar** seç. Yedekler `~/.macdpi-oneclick/network-backups/` içinde tutulur. Kullanılabilir yedek yoksa otomatik DNS/DHCP'ye dönüş kullanıcı onayıyla teklif edilir.

Proje Apple tarafından imzalanmış/notarize edilmiş değildir; uzak VPN sunucusu işletmez ve yönetici parolasını kaydetmez. Ayrıntılar: [SECURITY.md](SECURITY.md), [CHANGELOG.md](CHANGELOG.md).
