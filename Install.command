#!/bin/bash
set -euo pipefail

APP_NAME="MacDPI OneClick"
INSTALL_ROOT="$HOME/.macdpi-oneclick"
UPSTREAM_DIR="$INSTALL_ROOT/MacDPI"
UPSTREAM_URL="https://github.com/monotter/MacDPI.git"
LABEL="com.macdpi"

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

pause_exit() {
  echo
  read -r -p "Kapatmak için Enter'a bas..." _ || true
}

die() {
  echo
  echo "HATA: $*"
  pause_exit
  exit 1
}

trap 'echo; echo "Kurulum bir hatayla durdu. Yukarıdaki mesajı kontrol et."; pause_exit' ERR

clear
echo "=========================================="
echo "        MacDPI OneClick Kurulum"
echo "=========================================="
echo
echo "Bu kurulum:"
echo "  • macOS mimarisini otomatik algılar"
echo "  • MacDPI kaynağını resmi GitHub deposundan indirir"
echo "  • sing-box için uyumlu Go 1.25 kullanır"
echo "  • GLOBAL modu etkinleştirir"
echo "  • launchd servisini kurar; açılışta otomatik başlar"
echo
echo "Yönetici parolan istenebilir."
echo

[ "$(uname -s)" = "Darwin" ] || die "Bu paket yalnızca macOS içindir."

ARCH="$(uname -m)"
case "$ARCH" in
  arm64) echo "Mimari: Apple Silicon ($ARCH)" ;;
  x86_64) echo "Mimari: Intel ($ARCH)" ;;
  *) die "Desteklenmeyen mimari: $ARCH" ;;
esac

echo
echo "[1/6] Xcode Command Line Tools kontrol ediliyor..."
if ! xcode-select -p >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
  echo "Xcode Command Line Tools gerekli. Apple'ın kurulum penceresi açılıyor..."
  xcode-select --install >/dev/null 2>&1 || true
  echo "Açılan Apple penceresinden kurulumu tamamla."
  echo "Kurulumun bitmesi bekleniyor..."
  n=0
  until xcode-select -p >/dev/null 2>&1 && command -v cc >/dev/null 2>&1; do
    sleep 5
    n=$((n + 1))
    if [ "$n" -ge 360 ]; then
      die "Command Line Tools kurulumu zaman aşımına uğradı. Kurulumu tamamlayıp Install.command dosyasını yeniden aç."
    fi
  done
fi
echo "Tamam."

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
echo "[2/6] Homebrew kontrol ediliyor..."
BREW="$(find_brew || true)"
if [ -z "${BREW:-}" ]; then
  echo "Homebrew bulunamadı."
  echo "Resmi Homebrew kurucusu çalıştırılacak: brew.sh"
  read -r -p "Devam edilsin mi? [E/h] " ans
  case "${ans:-E}" in
    h|H|n|N) die "Kurulum kullanıcı tarafından iptal edildi." ;;
  esac
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW="$(find_brew || true)"
  [ -n "${BREW:-}" ] || die "Homebrew kuruldu ancak brew komutu bulunamadı."
fi
eval "$("$BREW" shellenv)" >/dev/null 2>&1 || true
echo "Homebrew: $("$BREW" --version | head -1)"

echo
echo "[3/6] Uyumlu Go sürümü hazırlanıyor..."
if ! "$BREW" list --versions go@1.25 >/dev/null 2>&1; then
  "$BREW" install go@1.25
fi
GO_PREFIX="$("$BREW" --prefix go@1.25)"
export PATH="$GO_PREFIX/bin:$("$BREW" --prefix)/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
GO_BIN="$GO_PREFIX/bin/go"
[ -x "$GO_BIN" ] || die "Go 1.25 bulunamadı."
echo "Go: "$("$GO_BIN" version)

echo
echo "[4/6] MacDPI indiriliyor/güncelleniyor..."
mkdir -p "$INSTALL_ROOT"

sudo launchctl bootout "system/$LABEL" >/dev/null 2>&1 || true

if [ -d "$UPSTREAM_DIR/.git" ]; then
  git -C "$UPSTREAM_DIR" fetch --depth 1 origin main
  git -C "$UPSTREAM_DIR" reset --hard origin/main
  git -C "$UPSTREAM_DIR" clean -fd
else
  rm -rf "$UPSTREAM_DIR"
  git clone --depth 1 "$UPSTREAM_URL" "$UPSTREAM_DIR"
fi

cd "$UPSTREAM_DIR"

sed -i '' 's/^MODE=.*/MODE=global/' settings.conf
sed -i '' 's/^BLOCK_QUIC=.*/BLOCK_QUIC=true/' settings.conf
sed -i '' 's/^MAX_CONN=.*/MAX_CONN=8192/' settings.conf

echo "Mod: $(grep '^MODE=' settings.conf)"
echo "QUIC: $(grep '^BLOCK_QUIC=' settings.conf)"

echo
echo "[5/6] Bileşenler bu Mac için derleniyor..."
rm -f bin/ciadpi bin/sing-box
PATH="$GO_PREFIX/bin:$PATH" ./bin/Build.sh

[ -x bin/ciadpi ] || die "ciadpi derlenemedi."
[ -x bin/sing-box ] || die "sing-box derlenemedi."

echo
echo "[6/6] Açılış servisi kuruluyor..."
PATH="$GO_PREFIX/bin:$PATH" ./ServiceInstall.sh

echo
echo "Masaüstüne Aç/Kapat/Kaldır kısayolları kopyalanıyor..."
for f in DPI_Ac.command DPI_Kapat.command Kaldir.command Durum.command; do
  if [ -f "$SELF_DIR/$f" ]; then
    cp -p "$SELF_DIR/$f" "$HOME/Desktop/$f"
    chmod +x "$HOME/Desktop/$f"
  fi
done

mkdir -p "$INSTALL_ROOT"
cat > "$INSTALL_ROOT/install-info.txt" <<EOF
Installed: $(date)
Architecture: $ARCH
Upstream: $UPSTREAM_URL
Mode: global
Go: $("$GO_BIN" version)
EOF

echo
echo "=========================================="
echo "KURULUM TAMAMLANDI"
echo "=========================================="
echo
echo "DPI GLOBAL modda aktif."
echo "Chrome, Safari, Edge, Discord ve diğer uygulamalar sistem genelinde kapsanır."
echo "Mac yeniden başladığında servis otomatik başlayacaktır."
echo
echo "Masaüstüne DPI_Ac.command ve DPI_Kapat.command kısayolları bırakıldı."
echo

osascript -e 'display notification "Global DPI bypass kuruldu ve aktif." with title "MacDPI OneClick"' >/dev/null 2>&1 || true
pause_exit
