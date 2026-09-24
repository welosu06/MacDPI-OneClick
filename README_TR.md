# MacDPI OneClick

macOS için sistem-geneli MacDPI kurulum ve kontrol paketi.

## Hiç Bilmeyen Biri İçin Kurulum / Beginner Setup

1. GitHub'da **Releases** bölümünü aç / Open **Releases** on GitHub.
2. **MacDPI-OneClick-v1.3.0.zip** dosyasını indir / Download **MacDPI-OneClick-v1.3.0.zip**.
3. ZIP dosyasını aç / Extract the ZIP.
4. **MacDPI.command** dosyasına çift tıkla / Double-click **MacDPI.command**.
5. Mac uyarı verirse dosyaya sağ tık → **Aç / Open** → **Aç / Open**.
6. İlk kez kullanıyorsan terminalde **1** yazıp Enter'a bas / First time: type **1** and press Enter.
7. Kurulum tamamlanınca Masaüstünde **MacDPI OneClick.command** oluşur.
8. Bundan sonra sadece Masaüstündeki bu kısayolu açman yeterli.

Terminali kapatman DPI servisini kapatmaz. DPI'yi kapatmak ve normal ağ ayarlarına dönmek için Masaüstündeki kısayolu açıp **3** seç.

## Menü / Menu

- **1) MacDPI'yi Kur / Install MacDPI**
- **2) DPI Bypass'ı Aç / Enable DPI Bypass**
- **3) DPI Bypass'ı Kapat / Disable DPI Bypass**
- **4) Bağlantı Durumunu Kontrol Et / Check Connection Status**
- **5) Kurulumu Güncelle veya Onar / Update or Repair Installation**
- **6) MacDPI'yi Tamamen Kaldır / Uninstall MacDPI Completely**
- **0) Çıkış / Exit**

## Ağ Güvenliği / Network Safety

MacDPI ağ ayarlarına dokunmadan önce mevcut ayarlar otomatik olarak yedeklenir:

`~/.macdpi-oneclick/network-backup`

Yedekte DHCP veya manuel ağ yapılandırması, IP adresi, subnet mask, router ve DNS bilgileri tutulur.

Ek güvenlik önlemleri:

- Global mod açılmadan önce `.240` IP çakışması kontrol edilir.
- MacDPI, değişebilen `main` dalı yerine kontrol edilmiş `30556c5dd90d23819e32b4c2bfb8b8b670cde8a4` commit'ine sabitlenmiştir.
- Üçüncü taraf hazır binary dağıtılmaz; bileşenler Mac üzerinde kaynak koddan derlenir.
- Kurulumdan ve DPI'yi açtıktan sonra internet bağlantısı otomatik test edilir.
- Bağlantı testi başarısız olursa servis kapatılır ve yedeklenen ağ ayarları otomatik geri yüklenir.
- **3 - DPI'yi Kapat** seçeneği orijinal ağ ayarlarını geri yükler.
- **6 - Tamamen Kaldır** seçeneği de kaldırmadan önce orijinal ağ ayarlarını geri yükler.

Bu önlemler riski azaltır; ancak her modem, VPN, kurumsal ağ, captive portal ve ISS yapılandırmasında sıfır sorun garantisi verilemez.

## Mac'te Neleri Değiştirir?

DPI aktifken upstream MacDPI geçici olarak ağ yapılandırmasını değiştirebilir, `.240` ile biten bir LAN adresi kullanabilir, DNS'i değiştirebilir, QUIC/UDP 443'ü engelleyebilir ve `com.macdpi` isimli launchd servisini çalıştırabilir.

Servis Mac açıldığında otomatik başlayabilir. Terminal penceresini kapatmak servisi durdurmaz.

## Gizlilik / Privacy

Wrapper scriptlerinde bilerek eklenmiş telemetry veya kullanıcı verisi toplama mekanizması yoktur. Proje kendi uzak VPN sunucusunu işletmez.

Yönetici yetkisi ağ ayarları ve sistem servisi için gereklidir.

## Sorun Olursa / If Something Goes Wrong

Önce Masaüstündeki **MacDPI OneClick.command** dosyasını açıp **3** seç. Bu servis kapatma ve kayıtlı ağ ayarlarını geri yükleme işlemini çalıştırır.

Tamamen kaldırmak için **6** seç.

Daha fazla güvenlik bilgisi için [SECURITY.md](SECURITY.md).

## Destek / Support

Apple Silicon M1–M5 ve Intel Mac'ler.

## Lisans / License

Wrapper scriptleri ve dokümantasyon MIT lisanslıdır. Üçüncü taraf projeler kendi lisanslarına tabidir.
