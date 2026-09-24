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

if [ -d "$DIR" ] && [ -f "$DIR/ServiceRemove.sh" ]; then
  (cd "$DIR" && ./ServiceRemove.sh) || true
else
  sudo launchctl bootout system/com.macdpi >/dev/null 2>&1 || true
fi

restore_active_backup || true
verify_restored_network || true

echo
echo "DPI KAPALI / DPI OFF"
echo "Kayıtlı ağ ayarları geri yüklendi / Saved network settings restored."
