# MacDPI OneClick v1.6.0

macOS için Türkçe/İngilizce kurulum, açma-kapatma ve ağ kurtarma menüsü.

**v1.6.0, Discord uygulamasında görülen “Update Failed / Retrying” sorunu için doğrulanan düzeltmeleri içerir.** gVisor TUN, fiziksel ağ arayüzüne bağlanan yerel ByeDPI derlemesi ve `--split 2` birlikte kullanılır. Kurulum ve Onar seçenekleri bu düzeltmeleri yeniden uygular.

## Kurulum ve yükseltme

1. [Son sürümü aç](https://github.com/welosu06/MacDPI-OneClick/releases/latest).
2. **Assets** bölümünden **MacDPI-OneClick-v1.6.0.zip** indir ve ZIP'i aç.
3. Yeni klasördeki **MacDPI.command** dosyasını aç; **1 — Güvenli Kurulum** seç.
4. macOS engellerse **sağ tık → Aç** yolunu dene. Gerekirse **Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç** seçeneğini kullan.
5. Yönetici parolanı yalnızca normal macOS/sudo istemine gir. Yerel derleme birkaç dakika sürebilir.
6. Sonraki kullanımlarda Masaüstündeki **MacDPI OneClick.command** kısayolunu aç.

**v1.5.0 kuruluysa:** yükseltmeyi Masaüstündeki eski kısayoldan değil, yeni çıkardığın **v1.6.0 klasöründen** başlatıp bir kez **1** seç. Yeni paket kendi kurucusunu kullanır. Yükseltmeden sonra **5 — Onar** da yeni düzeltmeleri korur.

Paket hazır üçüncü taraf binary içermez; kaynak kod yerel olarak derlenir. ZIP'in yanındaki `.sha256` dosyası indirme bütünlüğünü kontrol etmek içindir.

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
