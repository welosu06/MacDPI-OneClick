#!/bin/bash
set -u

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
SAFETY="$ROOT/launcher/NetworkSafety.sh"

[ -f "$SAFETY" ] || { echo "NetworkSafety.sh bulunamadı / missing."; exit 1; }
# shellcheck source=/dev/null
source "$SAFETY"
acquire_lock || exit 1
trap 'release_lock >/dev/null 2>&1 || true' EXIT

clear
echo "=========================================================="
echo "       ACİL AĞ KURTARMA / EMERGENCY NETWORK RESTORE"
echo "=========================================================="
echo
echo "Bu seçenek DPI servisini kapatır ve son temiz ağ yedeğini geri yükler."
echo "This stops the DPI service and restores the last clean network backup."
echo

if [ -d "$DIR" ] && [ -f "$DIR/ServiceRemove.sh" ]; then
  (cd "$DIR" && ./ServiceRemove.sh) || true
else
  sudo launchctl bootout system/com.macdpi >/dev/null 2>&1 || true
  sudo rm -f /Library/LaunchDaemons/com.macdpi.plist >/dev/null 2>&1 || true
fi

if restore_active_backup; then
  verify_restored_network || true
else
  echo
  echo "Yedek bulunamadı. Son çare olarak aktif ağ servisi DHCP'ye alınabilir."
  echo "No backup was found. As a last resort, the active service can be switched to DHCP."
  read -r -p "DHCP'ye dönülsün mü? / Switch to DHCP? [e/y = Yes, H/n = No] " ans
  case "${ans:-H}" in
    e|E|y|Y)
      svc="$(active_network_service 2>/dev/null || true)"
      if [ -n "$svc" ]; then
        sudo networksetup -setdhcp "$svc"
        sudo networksetup -setdnsservers "$svc" "Empty"
        sudo dscacheutil -flushcache >/dev/null 2>&1 || true
        sudo killall -HUP mDNSResponder >/dev/null 2>&1 || true
        verify_restored_network || true
      fi
      ;;
  esac
fi

echo
read -r -p "Menüye dönmek için Enter / Press Enter to return..." _ || true
