## Mac için yeni sürüm: v1.6.1

Mac'i kapatıp açınca internetin gelmemesi ve DPI'yi elle kapatıp açma gereği için düzeltme eklendi. Önceki Discord düzeltmeleri de bu pakette.

## Kurulum — sırayla yap

1. Aşağıdaki **MacDPI-OneClick-v1.6.1.zip** dosyasını indir. **Source code** yazanları indirme.
2. İndirilen ZIP'e iki kez tıkla. Açılan **MacDPI-OneClick-v1.6.1** klasörüne gir.
3. **MacDPI.command** dosyasını aç. Terminal penceresi açılacak; normaldir.
4. **1** yaz → **Enter** bas. **Eski sürüm yüklüyse de güncellemek için 1 seç.**
5. Mac şifren istenirse yaz → **Enter** bas. Şifre yazarken ekranda hiçbir şey görünmez; normaldir.
6. “Kurulum başarılı” mesajını bekle. İlk kurulum birkaç dakika sürebilir; pencereyi kapatma.
7. Discord'u tamamen kapatıp tekrar aç.

**[ZIP'i buradan indir](https://github.com/welosu06/MacDPI-OneClick/releases/download/v1.6.1/MacDPI-OneClick-v1.6.1.zip)**

Dosya yalnızca geliştiricisi doğrulanamadığı için açılmıyorsa: sağ tık → Aç; gerekirse Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç. Kötü amaçlı yazılım uyarısı çıkarsa çalıştırma.

## Kullanım

Masaüstündeki MacDPI kısayolunu aç: **2 = aç**, **3 = kapat**, **4 = kontrol et**, **7 = interneti kurtar**.
Mac açılırken artık ağın hazır olmasını bekler. Terminal menüsünü kapatmak DPI'yi kapatmaz.

Bu paket **yalnızca Mac içindir**; Windows beta paketiyle aynı değildir. İlgili Mac'te kullanıcı başarı bildirdi. Her ağ/Mac modeli ve Discord ses/UDP bağlantısı için garanti verilmez.

### Technical changes

Stable physical IPv4 network gating before TUN startup, worker supervision, restart after sustained network changes, and correct signal-driven exit. Install/Repair preserve the fix. Automated regression tests and ZIP verification run before publication.
