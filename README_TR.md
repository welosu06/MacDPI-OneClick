# MacDPI OneClick v1.5.0

macOS için sistem genelinde çalışan MacDPI kurulum ve kontrol paketi. v1.5.0'ın ana amacı yalnızca kurulumu kolaylaştırmak değil, **ağ ayarlarına müdahale eden bir işlem başarısız olduğunda Mac'i mümkün olduğunca temiz ağ durumuna geri döndürebilmektir.**

> Ağ yazılımlarında her modem, VPN, şirket ağı, captive portal, ISS ve macOS sürümü için sıfır sorun garantisi verilemez. Bu sürüm güvenlik kontrolü, yedek, sağlık testi ve kurtarma katmanlarıyla riski azaltmak için tasarlanmıştır.

## Hızlı Başlangıç / Quick Start

1. GitHub'da **Releases** bölümünü aç.
2. **MacDPI-OneClick-v1.5.0.zip** dosyasını **Assets** bölümünden indir.
3. ZIP dosyasını aç.
4. **MacDPI.command** dosyasına çift tıkla.
5. macOS dosyayı engellerse önce **MacDPI.command → sağ tık → Aç / Open → Aç / Open** yolunu dene.
6. Hâlâ engelleniyorsa **Sistem Ayarları / System Settings → Gizlilik ve Güvenlik / Privacy & Security** bölümüne gir, aşağıdaki engellenen uygulama uyarısını bul, **Yine de Aç / Open Anyway** seçeneğine bas ve ardından **Aç / Open** ile onayla.
7. Terminal kontrol merkezi açıldığında ilk kurulum için **1** yaz ve Enter'a bas.
8. macOS yönetici parolanı isterse gir. **Wrapper scriptleri parolanı okumaz, kaydetmez veya loglamaz.**
9. Kurulum tamamlandığında Masaüstünde **MacDPI OneClick.command** oluşur. Bundan sonra kontrol için bu tek kısayolu kullan.

> **Code → Download ZIP** yerine **Releases / Assets** içindeki ZIP'i kullan. Release paketi macOS GitHub Actions üzerinde hazırlanır ve `.command` dosyalarının çalıştırılabilir izinleri kontrol edilir.

## Kontrol Merkezi

- **1 — Güvenli Kurulum / Safe Install**
- **2 — DPI'yi Aç / Enable DPI**
- **3 — DPI'yi Kapat / Disable DPI**
- **4 — Sağlık Kontrolü / Health Check**
- **5 — Kurulumu Onar / Repair Installation**
- **6 — Tamamen Kaldır / Uninstall Completely**
- **7 — Ağı Kurtar / Emergency Restore Network**
- **8 — Güvenli Tanılama Raporu / Redacted Diagnostics**
- **0 — Çıkış / Exit**

Terminal penceresini kapatmak, kurulu `launchd` servisini kapatmaz. DPI'yi bilerek durdurmak ve kayıtlı temiz ağ ayarına dönmek için **3** kullan.

## v1.5.0 Güvenlik Sistemi

### Her açılış öncesi güncel temiz ağ yedeği

DPI etkinleştirilmeden önce **o anda kullanılan ağın** yapılandırması kaydedilir. Yedekte şu bilgiler bulunur:

- aktif macOS ağ servisi;
- DHCP veya manuel IP modu;
- IP adresi;
- subnet mask;
- router/gateway;
- DNS ayarları;
- aktif ağ arayüzü;
- macOS izin verdiğinde Wi-Fi ağ adı.

Yedekler:

`~/.macdpi-oneclick/network-backups/`

altında tutulur. O anda kurtarma için kullanılacak yedeğin yolu:

`~/.macdpi-oneclick/active-backup`

ile işaretlenir.

Böylece kullanıcı bugün ev Wi-Fi'sinde, yarın Ethernet'te veya başka bir modemdeyse tek bir eski yedeğe sürekli güvenilmez. Yedek geçmişinin sınırsız büyümemesi için eski yedekler otomatik sınırlandırılır.

### v1.3 / v1.4 yükseltme koruması

Eski sürümlerde tek yedek klasörü kullanılıyordu:

`~/.macdpi-oneclick/network-backup`

v1.5.0 bu eski formatı algılar ve çalışan eski servise dokunmadan önce yeni yedek sistemine aktarır. Amaç, güncelleme sırasında eski kurtarma bilgisini kaybetmemektir.

### `.240` IP çakışması

Upstream MacDPI geçici olarak `.240` ile biten bir LAN adresi kullanmayı deneyebilir. v1.5.0 bu adresi önceden kontrol eder.

Adres başka bir cihaz tarafından kullanılıyor gibi görünüyorsa wrapper bu adresi **bilerek zorlamaz**. Kullanıcıya uyarı gösterilir. Upstream MacDPI statik IP'yi uygulamadan çalışabiliyorsa devam edebilir ve daha sonra gerçek internet sağlık testi yapılır.

Bağlantı sağlıklı değilse servis otomatik durdurulur ve temiz ağ yedeği geri yüklenir.

### Otomatik bağlantı testi ve rollback

Kurulumdan veya DPI açılışından sonra birden fazla HTTPS hedefiyle bağlantı sağlığı kontrol edilir. Test başarısızsa:

1. MacDPI servisi durdurulur.
2. Temiz ağ yedeği geri yüklenir.
3. DNS cache temizlenir/yenilenir.
4. Normal internet bağlantısı tekrar test edilir.

Amaç, başarısız bir denemeden sonra kullanıcıyı bozuk ağ ayarıyla bırakmamaktır.

### 7 — Ağı Kurtar

Bu seçenek özellikle acil durum için ayrılmıştır. Kullanıcı sadece interneti normale döndürmek istiyorsa:

- MacDPI servisini durdurmayı;
- son temiz yedeği geri yüklemeyi;
- DNS'i yenilemeyi;
- normal interneti tekrar doğrulamayı

dener.

Kullanılabilir yedek hiç yoksa, son çare olarak aktif ağ servisini DHCP + otomatik DNS'e döndürmeyi **kullanıcıya sorarak** teklif eder. Bu işlem otomatik yapılmaz; çünkü bazı şirket veya özel ağlarda manuel IP/DNS gerçekten gerekli olabilir.

### VPN / Private Relay / kurumsal ağ uyarısı

`utun` arayüzü algılanırsa VPN, Private Relay veya başka bir macOS ağ özelliği olabileceği için uyarı verilir. `utun` görülmesi tek başına hata kabul edilmez; asıl karar bağlantı sağlık testine bırakılır.

Captive portal ihtimali de kontrol edilir. Otel, havaalanı, misafir Wi-Fi gibi giriş sayfası isteyen ağlarda önce ağ girişinin tamamlanması gerekebilir.

### Aynı anda iki ağ işlemini engelleme

Kurulum, açma, kapatma, kurtarma ve kaldırma işlemlerinde işlem kilidi bulunur. Amaç iki farklı MacDPI ağ işleminin aynı anda çalışıp birbirinin ayarlarını bozmasını önlemektir. Eski/kalmış kilitlerde kayıtlı işlem artık çalışmıyorsa kilit temizlenebilir.

### Repair / Onar düzeltmesi

Kurulum onarma işlemi kurulu launcher klasöründen çalıştırılabilir. v1.5.0, scriptlerin kendi dosyalarını yine kendi üstüne kopyalamaya çalışmasını engeller.

**Repair**, mevcut paketteki wrapper ve sabitlenmiş MacDPI kurulumunu yeniden kurar/onarmaya çalışır. Wrapper için internetten otomatik self-update olduğu iddia edilmez.

### 8 — Güvenli Tanılama

Masaüstüne paylaşılabilir bir tanılama `.txt` dosyası üretir. Raporda şu tür bilgiler bulunabilir:

- MacDPI OneClick sürümü;
- macOS sürümü ve mimari;
- servis aktif mi;
- internet sağlık testi sonucu;
- güvenli MacDPI ayarları;
- son servis log satırları.

Dosya oluşturulmadan önce IPv4/IPv6 benzeri adresler ve kullanıcı ana klasör yolu maskelenir. Yine de GitHub'a veya internete yüklemeden önce tanılama dosyasını gözle kontrol etmek en güvenli yaklaşımdır.

### Kaldırma güvenliği

**6 — Tamamen Kaldır** önce kayıtlı ağ durumunu geri yüklemeye çalışır. Sonra `com.macdpi` launchd servisini kaldırır ve servis kalıntısı olup olmadığını kontrol eder. Çalışma klasörü ve Masaüstü kısayolları Çöp Kutusu'na taşınır.

Homebrew, Go ve Apple Command Line Tools kaldırılmaz; çünkü bunlar başka uygulamalar tarafından da kullanılıyor olabilir.

## DPI Aktifken Mac'te Neler Değişebilir?

Upstream MacDPI aktifken:

- TUN tabanlı bir ağ yolu kullanabilir;
- sing-box yerel olarak çalışır;
- ByeDPI/ciadpi yerel olarak çalışır;
- IP yapılandırması geçici değişebilir;
- DNS geçici değişebilir;
- QUIC/UDP 443 engellenerek trafiğin TCP'ye düşmesi sağlanabilir;
- `/Library/LaunchDaemons/com.macdpi.plist` üzerinden sistem servisi kurulabilir;
- servis Mac açılışında otomatik başlayabilir.

## Kaynak Kod Sabitleme ve Yerel Derleme

MacDPI şu upstream commit'e sabitlenmiştir:

`30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`

Bu sabit MacDPI build scripti ayrıca:

- ByeDPI/ciadpi `ba53229` ref'ini;
- sing-box `v1.13.14` sürümünü

kullanır.

Release ZIP'in içine hazır üçüncü taraf `ciadpi` veya `sing-box` binary'si koyulmaz. Kurulum sırasında sabitlenmiş upstream kaynaklardan kullanıcının Mac'inde derlenir.

Bu yöntem yayınlanmış bir sürümün gelecekte MacDPI `main` değişti diye sessizce farklı kod çalıştırmasını engeller. Ancak commit sabitleme kriptografik yayıncı imzasıyla aynı şey değildir; kullanılan MacDPI commit'i GitHub üzerinde GPG-verified değildir.

## Gizlilik ve Yönetici Parolası

Wrapper scriptlerinde bilerek eklenmiş telemetry sistemi yoktur ve proje kendi uzak VPN sunucusunu işletmez.

Yönetici parolası gerektiğinde macOS `sudo` tarafından istenir. Wrapper scripti parolayı okumaz veya bir dosyaya kaydetmez.

Kurulum sırasında GitHub'dan kaynak kod ve gerekirse resmi Homebrew kurucusu indirildiği için doğal olarak internet bağlantısı kullanılır.

## macOS “Apple doğrulayamadı” / Güvenlik Uyarısı

Proje şu anda Apple Developer ID ile imzalanmış/notarize edilmiş bir uygulama olarak dağıtılmıyor. Bu nedenle ilk açılışta Gatekeeper onayı gerekebilir.

Önce:

**MacDPI.command → sağ tık → Aç / Open → Aç / Open**

Olmazsa:

**Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç / Open Anyway → Aç / Open**

Yalnızca bu GitHub reposunun **Releases** sayfasından bilinçli olarak indirdiğin dosyaya izin ver.

## Destek ve Sınırlar

Scriptler Apple Silicon (`arm64`, M-serisi dahil) ve Intel (`x86_64`) macOS cihazlar için tasarlanmıştır.

VPN, şirket tarafından yönetilen Mac'ler, manuel IP kullanılan ağlar, captive portal, özel DNS, farklı modem subnet'leri ve gelecekteki macOS değişiklikleri farklı davranabilir. GitHub Actions shell syntax ve paket yapısını doğrular; gerçek dünyadaki her ağ kombinasyonunu simüle edemez.

## Bir Sorun Olursa Sıra

1. Masaüstündeki **MacDPI OneClick.command** dosyasını aç.
2. Önceliğin interneti normale döndürmekse **7 — Ağı Kurtar** seç.
3. İnternet geldikten sonra **4 — Sağlık Kontrolü** çalıştır.
4. Programı istemiyorsan **6 — Tamamen Kaldır** seç.
5. Gerekirse macOS **Sistem Ayarları → Ağ / Network** bölümünden ilgili servisi manuel kontrol et.

Güvenlik modeli için [SECURITY.md](SECURITY.md), sürüm değişiklikleri için [CHANGELOG.md](CHANGELOG.md) dosyasına bakabilirsin.

## Lisans

MacDPI OneClick wrapper scriptleri ve dokümantasyon MIT lisanslıdır. MacDPI, sing-box, ByeDPI ve diğer üçüncü taraf bileşenler kendi lisanslarına tabidir.
