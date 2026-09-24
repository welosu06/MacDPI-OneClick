#!/bin/bash
set -euo pipefail

VERSION="1.5.0"
ROOT="$HOME/.macdpi-oneclick"
UPSTREAM_DIR="$ROOT/MacDPI"
UPSTREAM_URL="https://github.com/monotter/MacDPI.git"
UPSTREAM_COMMIT="30556c5dd90d23819e32b4c2bfb8b8b670cde8a4"
LABEL="com.macdpi"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
SAFETY_FILE="$SELF_DIR/NetworkSafety.sh"
NETWORK_CHANGED=0

pause_exit() {
  echo
  read -r -p "Kapatmak için Enter'a bas / Press Enter to close..." _ || true
}

die() {
  echo
  echo "HATA / ERROR: $*"
  pause_exit
  exit 1
}

rollback_on_error() {
  code=$?
  trap - ERR
  set +e
  echo
  echo "Kurulum tamamlanamadı / Installation could not be completed."

  if [ "$NETWORK_CHANGED" = "1" ]; then
    echo "Otomatik güvenlik geri alması başlatılıyor / Automatic safety rollback is starting..."
    if [ -d "$UPSTREAM_DIR" ] && [ -f "$UPSTREAM_DIR/ServiceRemove.sh" ]; then
      (cd "$UPSTREAM_DIR" && /bin/bash ./ServiceRemove.sh) >/dev/null 2>&1 || true
    else
      sudo launchctl bootout "system/$LABEL" >/dev/null 2>&1 || true
    fi
    restore_active_backup || true
    verify_restored_network || true
  fi

  release_lock || true
  pause_exit
  exit "$code"
}

clear
echo "=========================================================="
echo "       MacDPI OneClick v$VERSION — Safe Installer"
echo "=========================================================="
echo
echo "HIZLI BAŞLANGIÇ / QUICK START"
echo "macOS dosyayı engellerse / If macOS blocks the file:"
echo "  1) MacDPI.command → sağ tık / right-click → Aç / Open"
echo "  2) Olmazsa / If needed:"
echo "     Sistem Ayarları / System Settings"
echo "     → Gizlilik ve Güvenlik / Privacy & Security"
echo "     → Yine de Aç / Open Anyway"
echo "     → Aç / Open"
echo
echo "Bu araç ağ ayarlarını geçici olarak değiştirebilir."
echo "This tool may temporarily change network settings."
echo
echo "Güvenlik / Safety:"
echo "  • Her etkinleştirmeden önce güncel ağ yapılandırması yedeklenir."
echo "    The current network configuration is backed up before activation."
echo "  • .240 çakışması zorlanmaz; bağlantı sağlık testi yapılır."
echo "    A .240 conflict is never forced; connectivity is health-checked."
echo "  • Hata olursa servis durdurulur ve kayıtlı ağ ayarları geri yüklenir."
echo "    On failure, the service is stopped and saved network settings are restored."
echo "  • Yönetici parolası scriptler tarafından kaydedilmez."
echo "    The administrator password is not stored by these scripts."
echo "  • Bu proje uzak bir VPN sunucusu işletmez."
echo "    This project does not operate a remote VPN server."
echo

[ "$(uname -s)" = "Darwin" ] || die "Bu paket yalnızca macOS içindir / macOS only."
[ -f "$SAFETY_FILE" ] || die "NetworkSafety.sh bulunamadı / NetworkSafety.sh is missing."

# shellcheck source=/dev/null
source "$SAFETY_FILE"
mkdir -p "$ROOT"
acquire_lock || die "Başka bir işlem devam ediyor / Another operation is in progress."
trap rollback_on_error ERR
trap 'release_lock >/dev/null 2>&1 || true' EXIT

# v1.3/v1.4 used a single legacy backup directory. Import it before touching an existing service.
import_legacy_backup || true

ARCH="$(uname -m)"
case "$ARCH" in
  arm64) echo "Mimari / Architecture: Apple Silicon ($ARCH)" ;;
  x86_64) echo "Mimari / Architecture: Intel ($ARCH)" ;;
  *) die "Desteklenmeyen mimari / Unsupported architecture: $ARCH" ;;
esac

echo
echo "[1/9] Sistem gereksinimleri / System requirements..."
check_disk_space || die "Yeterli boş alan yok / Not enough free disk space."

if ! xcode-select -p >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
  echo "Xcode Command Line Tools gerekli / Xcode Command Line Tools are required."
  xcode-select --install >/dev/null 2>&1 || true
  echo "Apple penceresindeki kurulumu tamamla / Complete the Apple installer."
  n=0
  until xcode-select -p >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; do
    sleep 5
    n=$((n + 1))
    [ "$n" -lt 360 ] || die "Command Line Tools kurulumu zaman aşımına uğradı / Installation timed out."
  done
fi
echo "Tamam / OK."

find_brew() {
  if command -v brew >/dev/null 2>&1; then command -v brew; return 0; fi
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

echo
echo "[2/9] Homebrew kontrolü / Checking Homebrew..."
BREW="$(find_brew || true)"
if [ -z "${BREW:-}" ]; then
  echo "Homebrew bulunamadı / Homebrew not found."
  echo "Yalnızca resmi Homebrew kurucusu kullanılacak / Only the official Homebrew installer will be used."
  read -r -p "Devam? / Continue? [E/y = Yes, H/n = No] " ans
  case "${ans:-E}" in h|H|n|N) die "İptal edildi / Cancelled." ;; esac
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW="$(find_brew || true)"
  [ -n "${BREW:-}" ] || die "Homebrew bulunamadı / brew was not found."
fi
eval "$("$BREW" shellenv)" >/dev/null 2>&1 || true
echo "Homebrew: $("$BREW" --version | head -1)"

echo
echo "[3/9] Go hazırlanıyor / Preparing Go..."
if ! "$BREW" list --versions go@1.25 >/dev/null 2>&1; then
  "$BREW" install go@1.25
fi
GO_PREFIX="$("$BREW" --prefix go@1.25)"
GO_BIN="$GO_PREFIX/bin/go"
export PATH="$GO_PREFIX/bin:$("$BREW" --prefix)/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
[ -x "$GO_BIN" ] || die "Go 1.25 bulunamadı / Go 1.25 not found."
echo "Go: $("$GO_BIN" version)"

echo
echo "[4/9] Mevcut servis güvenli duruma getiriliyor / Preparing a clean network state..."
if service_loaded; then
  NETWORK_CHANGED=1
  echo "Mevcut servis durduruluyor / Existing service is being stopped..."
  if [ -f "$UPSTREAM_DIR/ServiceRemove.sh" ]; then
    (cd "$UPSTREAM_DIR" && ./ServiceRemove.sh) || true
  else
    sudo launchctl bootout "system/$LABEL" >/dev/null 2>&1 || true
  fi
  restore_active_backup || true
  verify_restored_network || true
fi

echo
echo "[5/9] Güncel ağ ayarları yedekleniyor / Backing up current network settings..."
backup_current_network
vpn_warning
captive_portal_warning
check_static_host_conflict

echo
echo "[6/9] Sabitlenmiş upstream kaynak hazırlanıyor / Preparing pinned upstream source..."
if [ ! -d "$UPSTREAM_DIR/.git" ]; then
  rm -rf "$UPSTREAM_DIR"
  mkdir -p "$UPSTREAM_DIR"
  git -C "$UPSTREAM_DIR" init -q
  git -C "$UPSTREAM_DIR" remote add origin "$UPSTREAM_URL"
else
  git -C "$UPSTREAM_DIR" remote set-url origin "$UPSTREAM_URL"
fi

git -c advice.detachedHead=false -C "$UPSTREAM_DIR" fetch --depth 1 origin "$UPSTREAM_COMMIT"
git -c advice.detachedHead=false -C "$UPSTREAM_DIR" checkout -f "$UPSTREAM_COMMIT"
git -C "$UPSTREAM_DIR" clean -fdx

cd "$UPSTREAM_DIR"
ACTUAL_COMMIT="$(git rev-parse HEAD)"
[ "$ACTUAL_COMMIT" = "$UPSTREAM_COMMIT" ] || die "Upstream commit doğrulanamadı / Upstream commit verification failed."

sed -i '' 's/^MODE=.*/MODE=global/' settings.conf
sed -i '' 's/^BLOCK_QUIC=.*/BLOCK_QUIC=true/' settings.conf
sed -i '' 's/^MAX_CONN=.*/MAX_CONN=8192/' settings.conf

echo "MacDPI commit: $ACTUAL_COMMIT"

echo
echo "[7/9] Bileşenler yerel olarak derleniyor / Building components locally..."
rm -f bin/ciadpi bin/sing-box
PATH="$GO_PREFIX/bin:$PATH" ./bin/Build.sh
[ -x bin/ciadpi ] || die "ciadpi build başarısız / ciadpi build failed."
[ -x bin/sing-box ] || die "sing-box build başarısız / sing-box build failed."

echo
echo "[8/9] Servis kuruluyor ve sağlık testi yapılıyor / Installing service and running health check..."
NETWORK_CHANGED=1
PATH="$GO_PREFIX/bin:$PATH" ./ServiceInstall.sh

sleep 4
if ! internet_ok; then
  echo "Bağlantı testi başarısız / Connectivity test failed."
  ./ServiceRemove.sh || true
  restore_active_backup || true
  verify_restored_network || true
  NETWORK_CHANGED=0
  die "Kurulum güvenli şekilde geri alındı / Installation was safely rolled back."
fi
echo "Bağlantı testi başarılı / Connectivity test passed."

echo
echo "[9/9] Kontrol merkezi hazırlanıyor / Preparing Control Center..."
LAUNCHER_DIR="$ROOT/launcher"
mkdir -p "$LAUNCHER_DIR"

HELPERS="MacDPI.command Install.command DPI_Ac.command DPI_Kapat.command Durum.command Kaldir.command Agi_Kurtar.command Tani.command NetworkSafety.sh VERSION"
if [ "$SELF_DIR" != "$LAUNCHER_DIR" ]; then
  for f in $HELPERS; do
    if [ -f "$SELF_DIR/$f" ]; then
      cp -p "$SELF_DIR/$f" "$LAUNCHER_DIR/$f"
    fi
  done
else
  echo "Onarım mevcut launcher üzerinden çalışıyor; kendi üzerine kopyalama atlandı."
  echo "Repair is running from the installed launcher; self-copy was skipped."
fi

chmod +x "$LAUNCHER_DIR"/*.command "$LAUNCHER_DIR/NetworkSafety.sh" 2>/dev/null || true

if [ -f "$LAUNCHER_DIR/MacDPI.command" ]; then
  cp -p "$LAUNCHER_DIR/MacDPI.command" "$HOME/Desktop/MacDPI OneClick.command"
  chmod +x "$HOME/Desktop/MacDPI OneClick.command"
fi

cat > "$ROOT/install-info.txt" <<EOF
Version: $VERSION
Installed: $(date)
Architecture: $ARCH
Upstream: $UPSTREAM_URL
Pinned MacDPI commit: $UPSTREAM_COMMIT
Mode: global
Go: $("$GO_BIN" version)
EOF

NETWORK_CHANGED=0
trap - ERR
release_lock
trap - EXIT

echo
echo "=========================================================="
echo "KURULUM TAMAMLANDI / INSTALLATION COMPLETE"
echo "=========================================================="
echo
echo "DPI aktif / DPI active."
echo "Terminal'i kapatabilirsin; servis arka planda çalışmaya devam eder."
echo "You can close Terminal; the service continues in the background."
echo
echo "Masaüstü / Desktop: MacDPI OneClick.command"
echo
echo "Acil durumda menüden 7 = Ağı Kurtar / Emergency Restore Network."
echo
osascript -e 'display notification "Kurulum tamamlandı ve bağlantı sağlık kontrolü geçti." with title "MacDPI OneClick"' >/dev/null 2>&1 || true
pause_exit
