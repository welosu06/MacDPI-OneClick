## Türkçe

Discord uygulamasındaki **Update Failed / Retrying** sorunu için doğrulanan düzeltmeler:

- gVisor TUN ağ yığını.
- ciadpi dış bağlantılarının fiziksel ağ arayüzüne bağlanması.
- macOS SecureTransport ile doğrulanan `--split 2` yöntemi.
- Varsayılan `.240` statik IP değişiminin kaldırılması; DNS yedeği ve geri yüklemenin korunması.
- Kurulum ve Onar işlemlerinin kaynak yamalarını yeniden uygulaması.
- Yeni ZIP'in eski kurucuyu seçmesi ve başarısız kurulumun işlem kilidini tutması sorunlarının düzeltilmesi.
- Genel internet ve Discord güncelleme HTTPS testlerinin ayrı raporlanması.

**İndir:** `MacDPI-OneClick-v1.6.0.zip`. ZIP'i aç, yeni klasördeki `MacDPI.command` dosyasını çalıştır ve **1** seç. Yükseltmeden sonra Masaüstü kısayolunu kullanabilirsin.

Sorunun yaşandığı Apple Silicon Mac'te Discord güncellemeleri tamamlayıp açıldı. Sesli kanal/UDP ve tüm ağlar için doğrulama yapılmadı. Paket hazır üçüncü taraf binary içermez; yamalı kaynaklar yerel derlenir. Sertifika doğrulaması açık kalır.

## English

Fixes the reproduced Discord desktop **Update Failed / Retrying** case with gVisor TUN, macOS physical-interface socket binding and the native-TLS-tested `--split 2` strategy. The current IP configuration is kept by default. Install/Repair reapply the source patches; upgrades prefer the extracted package over older installed launchers, and failed installers release their own operation lock before waiting for input.

General internet and Discord updater health are reported separately. Download the ZIP, extract it and run option **1** from the new package. The ZIP contains scripts and auditable patches; third-party binaries are built locally. Certificate verification remains enabled.

The updater completed and the application opened on the Apple Silicon Mac where the fault was reproduced. Voice/UDP and every possible network are not covered by that test. See README and SECURITY for the recovery flow and limitations.
