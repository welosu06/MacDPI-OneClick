#!/bin/bash

VERSION="1.5.0"
ROOT="$HOME/.macdpi-oneclick"
INSTALLED_LAUNCHER="$ROOT/launcher"
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$INSTALLED_LAUNCHER" ] && [ -f "$INSTALLED_LAUNCHER/Install.command" ]; then
  SCRIPT_DIR="$INSTALLED_LAUNCHER"
  [ -f "$SCRIPT_DIR/VERSION" ] && VERSION="$(cat "$SCRIPT_DIR/VERSION")"
else
  SCRIPT_DIR="$SELF_DIR"
  [ -f "$SCRIPT_DIR/VERSION" ] && VERSION="$(cat "$SCRIPT_DIR/VERSION")"
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

wait_key() {
  echo
  read -r -p "Menüye dönmek için Enter / Press Enter to return..." _ || true
}

service_status() {
  if [ ! -d "$ROOT/MacDPI" ]; then
    printf "${YELLOW}KURULU DEĞİL / NOT INSTALLED${RESET}"
  elif launchctl print system/com.macdpi >/dev/null 2>&1; then
    printf "${GREEN}AKTİF / ACTIVE${RESET}"
  else
    printf "${RED}KAPALI / OFF${RESET}"
  fi
}

run_helper() {
  local file="$1"
  if [ ! -f "$SCRIPT_DIR/$file" ]; then
    echo "HATA / ERROR: $file bulunamadı / not found."
    wait_key
    return 1
  fi
  chmod +x "$SCRIPT_DIR/$file" >/dev/null 2>&1 || true
  /bin/bash "$SCRIPT_DIR/$file"
}

while true; do
  clear
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${RESET}        ${BOLD}MacDPI OneClick v$VERSION — Control Center${RESET}        ${CYAN}║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "${BOLD}Hızlı Başlangıç / Quick Start${RESET}"
  echo "  İlk kurulum / First install: 1 + Enter"
  echo "  DPI aç / Enable DPI:          2 + Enter"
  echo "  DPI kapat / Disable DPI:      3 + Enter"
  echo "  Acil ağ kurtarma / Recovery:  7 + Enter"
  echo
  echo "  macOS engellerse / If macOS blocks the launcher:"
  echo "  Sağ tık → Aç / Right-click → Open"
  echo "  veya / or"
  echo "  System Settings → Privacy & Security → Open Anyway"
  echo
  echo -e "Durum / Status: $(service_status)"
  echo
  echo "  1) Güvenli Kurulum / Safe Install"
  echo "  2) DPI'yi Aç / Enable DPI"
  echo "  3) DPI'yi Kapat / Disable DPI"
  echo "  4) Sağlık Kontrolü / Health Check"
  echo "  5) Kurulumu Onar / Repair Installation"
  echo "  6) Tamamen Kaldır / Uninstall Completely"
  echo "  7) Ağı Kurtar / Emergency Restore Network"
  echo "  8) Güvenli Tanılama Raporu / Safe Diagnostics"
  echo
  echo "  0) Çıkış / Exit"
  echo
  read -r -p "Seçimin / Your choice: " choice

  case "$choice" in
    1) run_helper "Install.command" ;;
    2) run_helper "DPI_Ac.command"; wait_key ;;
    3) run_helper "DPI_Kapat.command"; wait_key ;;
    4) run_helper "Durum.command" ;;
    5) run_helper "Install.command" ;;
    6) run_helper "Kaldir.command"; exit 0 ;;
    7) run_helper "Agi_Kurtar.command" ;;
    8) run_helper "Tani.command" ;;
    0) clear; exit 0 ;;
    *) echo "Geçersiz seçim / Invalid choice."; sleep 2 ;;
  esac
done
