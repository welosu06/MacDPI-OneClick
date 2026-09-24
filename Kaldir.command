#!/bin/bash
set -e

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
SAFETY="$ROOT/launcher/NetworkSafety.sh"

clear
echo "MacDPI OneClick kaldırılacak / MacDPI OneClick will be uninstalled."
read -r -p "Devam edilsin mi? / Continue? [e/y = Yes, H/n = No] " ans
case "${ans:-H}" in
  e|E|y|Y) ;;
  *) exit 0 ;;
esac

if [ -d "$DIR" ]; then
  cd "$DIR"
  ./ServiceRemove.sh || true
fi

if [ -f "$SAFETY" ]; then
  # shellcheck source=/dev/null
  source "$SAFETY"
  restore_network "$ROOT/network-backup" || true
fi

if [ -d "$ROOT" ]; then
  mv "$ROOT" "$HOME/.Trash/macdpi-oneclick-$(date +%Y%m%d-%H%M%S)"
fi

for f in "MacDPI OneClick.command" MacDPI.command DPI_Ac.command DPI_Kapat.command Kaldir.command Durum.command; do
  [ -e "$HOME/Desktop/$f" ] && mv "$HOME/Desktop/$f" "$HOME/.Trash/" || true
done

echo
echo "MacDPI OneClick kaldırıldı / MacDPI OneClick was removed."
echo "Orijinal ağ ayarları geri yüklendi / Original network settings were restored."
echo "Homebrew, Go ve Xcode Command Line Tools kaldırılmadı / Homebrew, Go and Xcode Command Line Tools were kept."
read -r -p "Kapatmak için Enter'a bas / Press Enter to close..." _ || true
