#!/bin/bash

LABEL="com.macdpi"
ROOT="$HOME/.macdpi-oneclick"
INSTALLED_LAUNCHER="$ROOT/launcher"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$INSTALLED_LAUNCHER" ] && [ -f "$INSTALLED_LAUNCHER/Install.command" ]; then
  SCRIPT_DIR="$INSTALLED_LAUNCHER"
else
  SCRIPT_DIR="$SELF_DIR"
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

wait_key() {
  echo
  read -r -p "Menüye dönmek için Enter'a bas..." _
}

service_status() {
  if [ ! -d "$ROOT/MacDPI" ]; then
    printf "${YELLOW}KURULU DEĞİL${RESET}"
  elif launchctl print "system/$LABEL" >/dev/null 2>&1; then
    printf "${GREEN}AKTİF${RESET}"
  else
    printf "${RED}KAPALI${RESET}"
  fi
}

run_helper() {
  local file="$1"
  if [ ! -f "$SCRIPT_DIR/$file" ]; then
    echo
    echo "HATA: $file bulunamadı."
    echo "En güncel Release paketini yeniden indir."
    wait_key
    return 1
  fi
  chmod +x "$SCRIPT_DIR/$file" >/dev/null 2>&1 || true
  /bin/bash "$SCRIPT_DIR/$file"
}

while true; do
  clear
  echo -e "${CYAN}╔════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET}        ${BOLD}MacDPI OneClick Control Center${RESET}       ${CYAN}║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "Durum: $(service_status)"
  echo
  echo "  1) MacDPI'yi Kur"
  echo "  2) DPI Bypass'ı Aç"
  echo "  3) DPI Bypass'ı Kapat / Normal İnternete Dön"
  echo "  4) Bağlantı Durumunu Kontrol Et"
  echo "  5) Kurulumu Güncelle / Onar"
  echo "  6) MacDPI OneClick'i Tamamen Kaldır"
  echo
  echo "  0) Çıkış"
  echo
  read -r -p "Seçimin: " choice

  case "$choice" in
    1)
      run_helper "Install.command"
      ;;
    2)
      run_helper "DPI_Ac.command"
      wait_key
      ;;
    3)
      run_helper "DPI_Kapat.command"
      wait_key
      ;;
    4)
      run_helper "Durum.command"
      ;;
    5)
      run_helper "Install.command"
      ;;
    6)
      run_helper "Kaldir.command"
      exit 0
      ;;
    0)
      clear
      exit 0
      ;;
    *)
      echo
      echo "Geçersiz seçim. 0 ile 6 arasında bir sayı gir."
      sleep 1
      ;;
  esac
done
