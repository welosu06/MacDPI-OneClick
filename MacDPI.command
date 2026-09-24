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
  read -r -p "Menüye dönmek için Enter'a bas / Press Enter to return to menu..." _
}

service_status() {
  if [ ! -d "$ROOT/MacDPI" ]; then
    printf "${YELLOW}KURULU DEĞİL / NOT INSTALLED${RESET}"
  elif launchctl print "system/$LABEL" >/dev/null 2>&1; then
    printf "${GREEN}AKTİF / ACTIVE${RESET}"
  else
    printf "${RED}KAPALI / OFF${RESET}"
  fi
}

run_helper() {
  local file="$1"
  if [ ! -f "$SCRIPT_DIR/$file" ]; then
    echo
    echo "HATA / ERROR: $file bulunamadı / was not found."
    echo "En güncel Release paketini yeniden indir / Download the latest Release package again."
    wait_key
    return 1
  fi
  chmod +x "$SCRIPT_DIR/$file" >/dev/null 2>&1 || true
  /bin/bash "$SCRIPT_DIR/$file"
}

while true; do
  clear
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET}             ${BOLD}MacDPI OneClick Control Center${RESET}             ${CYAN}║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "${BOLD}Hızlı Başlangıç / Quick Start${RESET}"
  echo
  echo "  İlk kez kullanıyorsan / First time:"
  echo "  1 yaz ve Enter'a bas / Type 1 and press Enter."
  echo
  echo "  Kurulum bittikten sonra DPI'yi açmak için / After installation, to enable DPI:"
  echo "  2 yaz ve Enter'a bas / Type 2 and press Enter."
  echo
  echo "  Normal internete dönmek için / To return to normal internet:"
  echo "  3 yaz ve Enter'a bas / Type 3 and press Enter."
  echo
  echo "  Sadece aşağıdaki numaralardan birini yazman yeterli."
  echo "  Just type one of the numbers below."
  echo
  echo -e "Durum / Status: $(service_status)"
  echo
  echo "  1) MacDPI'yi Kur / Install MacDPI"
  echo "  2) DPI Bypass'ı Aç / Enable DPI Bypass"
  echo "  3) DPI Bypass'ı Kapat / Disable DPI Bypass"
  echo "  4) Bağlantı Durumunu Kontrol Et / Check Connection Status"
  echo "  5) Kurulumu Güncelle veya Onar / Update or Repair Installation"
  echo "  6) MacDPI'yi Tamamen Kaldır / Uninstall MacDPI Completely"
  echo
  echo "  0) Çıkış / Exit"
  echo
  read -r -p "Seçimin / Your choice: " choice

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
      echo "Geçersiz seçim / Invalid choice."
      echo "0 ile 6 arasında bir sayı gir / Enter a number between 0 and 6."
      sleep 2
      ;;
  esac
done
