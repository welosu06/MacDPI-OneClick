#!/bin/bash
set -euo pipefail

APP_NAME="MacDPI OneClick"
INSTALL_ROOT="$HOME/.macdpi-oneclick"
UPSTREAM_DIR="$INSTALL_ROOT/MacDPI"
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
  echo "Kurulum hata verdi / Installation failed."

  if [ "$NETWORK_CHANGED" = "1" ]; then
    echo "Güvenlik geri alma işlemi başlatılıyor / Safety rollback is starting..."

    if [ -d "$UPSTREAM_DIR" ] && [ -f "$UPSTREAM_DIR/ServiceRemove.sh" ]; then
      (cd "$UPSTREAM_DIR" && /bin/bash ./ServiceRemove.sh) >/dev/null 2>&1 || true
    else
      sudo launchctl bootout "system/$LABEL" >/dev/null 2>&1 || true
    fi

    if type restore_network >/dev/null 2>&1; then
      restore_network "$INSTALL_ROOT/network-backup" || true
    fi
  fi

  echo "Ağ güvenli duruma döndürülmeye çalışıldı / Network was returned to a safe state."
  pause_exit
  exit "$code"
}

trap rollback_on_error ERR

clear
echo "=========================================================="
echo "              MacDPI OneClick Installer"
echo "=========================================================="
echo
echo "Bu araç ağ ayarlarını geçici olarak değiştirir."
echo "This tool temporarily changes network settings."
echo
echo "Güvenlik önlemleri / Safety protections:"
echo "  • Mevcut IP ve DNS ayarlarını yedekler / Backs up current IP and DNS settings"
echo "  • .240 IP çakışmasını önceden kontrol eder / Checks .240 IP conflict first"
echo "  • Hata olursa ağı otomatik geri alır / Automatically rolls back on failure"
echo "  • Kurulum sonrası interneti test eder / Tests internet after installation"
echo "  • MacDPI kaynağını test edilmiş commit'e sabitler / Pins MacDPI to a tested commit"
echo
echo "Yönetici parolan istenebilir / Your administrator password may be requested."
echo

[ "$(uname -s)" = "Darwin" ] || die "Bu paket yalnızca macOS içindir / This package is for macOS only."

[ -f "$SAFETY_FILE" ] || die "NetworkSafety.sh bulunamadı / NetworkSafety.sh is missing."
# shellcheck source=/dev/null
source "$SAFETY_FILE"

ARCH="$(uname -m)"
case "$ARCH" in
  arm64) echo "Mimari / Architecture: Apple Silicon ($ARCH)" ;;
  x86_64) echo "Mimari / Architecture: Intel ($ARCH)" ;;
  *) die "Desteklenmeyen mimari / Unsupported architecture: $ARCH" ;;
esac

echo
echo "[1/8] Xcode Command Line Tools kontrol ediliyor / Checking Xcode Command Line Tools..."
if ! xcode-select -p >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
  echo "Apple kurulum penceresi açılıyor / Apple installer is opening..."
  xcode-select --install >/dev/null 2>&1 || true
  echo "Kurulumu tamamla; program bekleyecek / Complete the installation; this window will wait."
  n=0
  until xcode-select -p >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; do
    sleep 5
    n=$((n + 1))
    if [ "$n" -ge 360 ]; then
      die "Command Line Tools kurulumu zaman aşımına uğradı / Command Line Tools installation timed out."
    fi
  done
fi
echo "Tamam / OK."

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$p" ]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

echo
echo "[2/8] Homebrew kontrol ediliyor / Checking Homebrew..."
BREW="$(find_brew || true)"
if [ -z "${BREW:-}" ]; then
  echo "Homebrew bulunamadı / Homebrew was not found."
  echo "Resmi Homebrew kurucusu kullanılacak / The official Homebrew installer will be used."
  read -r -p "Devam edilsin mi? / Continue? [E/y = Yes, H/n = No] " ans
  case "${ans:-E}" in
    h|H|n|N) die "Kurulum kullanıcı tarafından iptal edildi / Installation cancelled." ;;
  esac
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW="$(find_brew || true)"
  [ -n "${BREW:-}" ] || die "Homebrew kuruldu ancak brew bulunamadı / Homebrew installed but brew was not found."
fi
eval "$("$BREW" shellenv)" >/dev/null 2>&1 || true
echo "Homebrew: $("$BREW" --version | head -1)"

echo
echo "[3/8] Uyumlu Go sürümü hazırlanıyor / Preparing compatible Go..."
if ! "$BREW" list --versions go@1.25 >/dev/null 2>&1; then
  "$BREW" install go@1.25
fi
GO_PREFIX="$("$BREW" --prefix go@1.25)"
export PATH="$GO_PREFIX/bin:$("$BREW" --prefix)/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
GO_BIN="$GO_PREFIX/bin/go"
[ -x "$GO_BIN" ] || die "Go 1.25 bulunamadı / Go 1.25 was not found."
echo "Go: $("$GO_BIN" version)"

echo
echo "[4/8] Mevcut ağ korunuyor / Protecting current network settings..."
mkdir -p "$INSTALL_ROOT"

if sudo launchctl print "system/$LABEL" >/dev/null 2>&1; then
  echo "Çalışan eski servis durduruluyor / Stopping existing service..."
  NETWORK_CHANGED=1
  if [ -f "$UPSTREAM_DIR/ServiceRemove.sh" ]; then
    (cd "$UPSTREAM_DIR" && /bin/bash ./ServiceRemove.sh) || true
  else
    sudo launchctl bootout "system/$LABEL" >/dev/null 2>&1 || true
  fi

  if [ -f "$INSTALL_ROOT/network-backup/complete" ]; then
    restore_network "$INSTALL_ROOT/network-backup" || true
  fi
fi

backup_network "$INSTALL_ROOT/network-backup"
check_static_host_conflict

echo
echo "[5/8] Sabitlenmiş MacDPI kaynağı hazırlanıyor / Preparing pinned MacDPI source..."
if [ ! -d "$UPSTREAM_DIR/.git" ]; then
  rm -rf "$UPSTREAM_DIR"
  mkdir -p "$UPSTREAM_DIR"
  git -C "$UPSTREAM_DIR" init -q
  git -C "$UPSTREAM_DIR" remote add origin "$UPSTREAM_URL"
else
  git -C "$UPSTREAM_DIR" remote set-url origin "$UPSTREAM_URL"
fi

git -C "$UPSTREAM_DIR" fetch --depth 1 origin "$UPSTREAM_COMMIT"
git -C "$UPSTREAM_DIR" checkout -f "$UPSTREAM_COMMIT"
git -C "$UPSTREAM_DIR" clean -fdx

cd "$UPSTREAM_DIR"

ACTUAL_COMMIT="$(git rev-parse HEAD)"
[ "$ACTUAL_COMMIT" = "$UPSTREAM_COMMIT" ] || die "MacDPI commit doğrulanamadı / MacDPI commit verification failed."

sed -i '' 's/^MODE=.*/MODE=global/' settings.conf
sed -i '' 's/^BLOCK_QUIC=.*/BLOCK_QUIC=true/' settings.conf
sed -i '' 's/^MAX_CONN=.*/MAX_CONN=8192/' settings.conf

echo "MacDPI commit: $ACTUAL_COMMIT"
echo "Mode: $(grep '^MODE=' settings.conf)"
echo "QUIC: $(grep '^BLOCK_QUIC=' settings.conf)"

echo
echo "[6/8] Bileşenler yerel olarak derleniyor / Building components locally..."
rm -f bin/ciadpi bin/sing-box
PATH="$GO_PREFIX/bin:$PATH" ./bin/Build.sh

[ -x bin/ciadpi ] || die "ciadpi derlenemedi / ciadpi build failed."
[ -x bin/sing-box ] || die "sing-box derlenemedi / sing-box build failed."

echo
echo "[7/8] Servis kuruluyor / Installing service..."
NETWORK_CHANGED=1
PATH="$GO_PREFIX/bin:$PATH" ./ServiceInstall.sh

echo "İnternet bağlantısı test ediliyor / Testing internet connection..."
sleep 4
if ! internet_ok; then
  echo
  echo "Bağlantı testi başarısız / Connectivity test failed."
  echo "Otomatik geri alma uygulanıyor / Automatic rollback is being applied."
  ./ServiceRemove.sh || true
  restore_network "$INSTALL_ROOT/network-backup" || true
  NETWORK_CHANGED=0
  die "Kurulum geri alındı; mevcut ağ ayarların korundu / Installation rolled back; your previous network settings were preserved."
fi
echo "Bağlantı testi başarılı / Connectivity test passed."

echo
echo "[8/8] Kontrol merkezi ve Masaüstü kısayolu hazırlanıyor / Preparing Control Center and Desktop shortcut..."
LAUNCHER_DIR="$INSTALL_ROOT/launcher"
mkdir -p "$LAUNCHER_DIR"

for f in MacDPI.command Install.command DPI_Ac.command DPI_Kapat.command Durum.command Kaldir.command NetworkSafety.sh; do
  if [ -f "$SELF_DIR/$f" ]; then
    cp -p "$SELF_DIR/$f" "$LAUNCHER_DIR/$f"
    chmod +x "$LAUNCHER_DIR/$f"
  fi
done

if [ -f "$LAUNCHER_DIR/MacDPI.command" ]; then
  cp -p "$LAUNCHER_DIR/MacDPI.command" "$HOME/Desktop/MacDPI OneClick.command"
  chmod +x "$HOME/Desktop/MacDPI OneClick.command"
fi

rm -f "$HOME/Desktop/MacDPI.command"       "$HOME/Desktop/DPI_Ac.command"       "$HOME/Desktop/DPI_Kapat.command"       "$HOME/Desktop/Durum.command"       "$HOME/Desktop/Kaldir.command"

cat > "$INSTALL_ROOT/install-info.txt" <<EOF
Installed: $(date)
Architecture: $ARCH
Upstream: $UPSTREAM_URL
Pinned MacDPI commit: $UPSTREAM_COMMIT
Mode: global
Go: $("$GO_BIN" version)
Network backup: $INSTALL_ROOT/network-backup
EOF

NETWORK_CHANGED=0
trap - ERR

echo
echo "=========================================================="
echo "KURULUM TAMAMLANDI / INSTALLATION COMPLETE"
echo "=========================================================="
echo
echo "DPI GLOBAL modda aktif / DPI is active in GLOBAL mode."
echo "Terminali kapatabilirsin; servis arka planda çalışmaya devam eder."
echo "You can close Terminal; the service continues running in the background."
echo
echo "Masaüstü kısayolu / Desktop shortcut:"
echo "MacDPI OneClick.command"
echo
echo "Orijinal ağ ayarlarının yedeği / Original network backup:"
echo "$INSTALL_ROOT/network-backup"
echo

osascript -e 'display notification "Kurulum tamamlandı ve ağ güvenlik kontrolü geçti." with title "MacDPI OneClick"' >/dev/null 2>&1 || true
pause_exit
