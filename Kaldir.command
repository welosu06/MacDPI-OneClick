#!/bin/bash
set -u

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
SAFETY="$ROOT/launcher/NetworkSafety.sh"

[ -f "$SAFETY" ] && source "$SAFETY"

clear
echo "MacDPI OneClick tamamen kaldırılacak / MacDPI OneClick will be fully removed."
read -r -p "Devam? / Continue? [e/y = Yes, H/n = No] " ans
case "${ans:-H}" in e|E|y|Y) ;; *) exit 0 ;; esac

acquire_lock || exit 1
trap 'release_lock >/dev/null 2>&1 || true' EXIT

if [ -d "$DIR" ] && [ -f "$DIR/ServiceRemove.sh" ]; then
  (cd "$DIR" && ./ServiceRemove.sh) || true
else
  sudo launchctl bootout system/com.macdpi >/dev/null 2>&1 || true
fi

restore_active_backup || true
verify_restored_network || true

sudo launchctl bootout system/com.macdpi >/dev/null 2>&1 || true
sudo rm -f /Library/LaunchDaemons/com.macdpi.plist >/dev/null 2>&1 || true

if launchctl print system/com.macdpi >/dev/null 2>&1; then
  echo "UYARI: launchd servisi hâlâ kayıtlı görünüyor / service may still be loaded."
else
  echo "Servis kalıntısı kontrolü: temiz / Service residue check: clean."
fi

release_lock
trap - EXIT

if [ -d "$ROOT" ]; then
  dest="$HOME/.Trash/macdpi-oneclick-$(date +%Y%m%d-%H%M%S)"
  mv "$ROOT" "$dest"
fi

for f in "MacDPI OneClick.command" MacDPI.command DPI_Ac.command DPI_Kapat.command Kaldir.command Durum.command Agi_Kurtar.command Tani.command; do
  [ -e "$HOME/Desktop/$f" ] && mv "$HOME/Desktop/$f" "$HOME/.Trash/" || true
done

echo
echo "MacDPI OneClick kaldırıldı / MacDPI OneClick removed."
echo "Homebrew, Go ve Apple Command Line Tools sistemde bırakıldı."
echo "Homebrew, Go and Apple Command Line Tools were left installed."
read -r -p "Kapatmak için Enter / Press Enter to close..." _ || true
