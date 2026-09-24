#!/bin/bash

# Network safety helpers for MacDPI OneClick.
# Designed for the system Bash shipped with macOS.

MACDPI_ROOT="${MACDPI_ROOT:-$HOME/.macdpi-oneclick}"
NETWORK_BACKUP_DIR="${NETWORK_BACKUP_DIR:-$MACDPI_ROOT/network-backup}"

default_interface() {
  route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}'
}

network_service_for_interface() {
  local iface="$1"
  networksetup -listallhardwareports 2>/dev/null | awk -v dev="$iface" '
    /^Hardware Port:/ { port = substr($0, 16) }
    /^Device:/ { if ($2 == dev) { print port; exit } }'
}

active_network_service() {
  local iface svc
  iface="$(default_interface)"
  [ -n "$iface" ] || return 1
  svc="$(network_service_for_interface "$iface")"
  [ -n "$svc" ] || svc="Wi-Fi"
  printf '%s\n' "$svc"
}

backup_network() {
  local dir="${1:-$NETWORK_BACKUP_DIR}"
  local svc info mode ip mask router dns

  if [ -f "$dir/complete" ]; then
    echo "Ağ yedeği zaten mevcut / Network backup already exists."
    return 0
  fi

  svc="$(active_network_service)" || {
    echo "Aktif ağ servisi bulunamadı / Active network service not found."
    return 1
  }

  mkdir -p "$dir"
  info="$(networksetup -getinfo "$svc" 2>/dev/null || true)"
  [ -n "$info" ] || {
    echo "Ağ bilgisi okunamadı / Could not read network information."
    return 1
  }

  if printf '%s\n' "$info" | head -1 | grep -qi "DHCP"; then
    mode="dhcp"
  else
    mode="manual"
  fi

  ip="$(printf '%s\n' "$info" | awk -F': ' '/^IP address:/{print $2; exit}')"
  mask="$(printf '%s\n' "$info" | awk -F': ' '/^Subnet mask:/{print $2; exit}')"
  router="$(printf '%s\n' "$info" | awk -F': ' '/^Router:/{print $2; exit}')"

  printf '%s\n' "$svc" > "$dir/service"
  printf '%s\n' "$mode" > "$dir/mode"
  printf '%s\n' "$ip" > "$dir/ip"
  printf '%s\n' "$mask" > "$dir/mask"
  printf '%s\n' "$router" > "$dir/router"

  dns="$(networksetup -getdnsservers "$svc" 2>&1 || true)"
  if printf '%s\n' "$dns" | grep -q "There aren't any DNS Servers"; then
    : > "$dir/dns.empty"
    rm -f "$dir/dns"
  else
    printf '%s\n' "$dns" > "$dir/dns"
    rm -f "$dir/dns.empty"
  fi

  date > "$dir/created_at"
  touch "$dir/complete"

  echo "Mevcut ağ ayarları yedeklendi / Current network settings backed up."
}

restore_network() {
  local dir="${1:-$NETWORK_BACKUP_DIR}"
  local svc mode ip mask router
  local dns_args=()
  local line

  [ -f "$dir/complete" ] || {
    echo "Ağ yedeği bulunamadı / Network backup not found."
    return 1
  }

  svc="$(cat "$dir/service" 2>/dev/null || true)"
  mode="$(cat "$dir/mode" 2>/dev/null || true)"
  ip="$(cat "$dir/ip" 2>/dev/null || true)"
  mask="$(cat "$dir/mask" 2>/dev/null || true)"
  router="$(cat "$dir/router" 2>/dev/null || true)"

  [ -n "$svc" ] || return 1

  echo "Ağ ayarları geri yükleniyor / Restoring network settings..."

  if [ "$mode" = "manual" ] && [ -n "$ip" ] && [ -n "$mask" ] && [ -n "$router" ]; then
    sudo networksetup -setmanual "$svc" "$ip" "$mask" "$router"
  else
    sudo networksetup -setdhcp "$svc"
  fi

  if [ -f "$dir/dns.empty" ]; then
    sudo networksetup -setdnsservers "$svc" "Empty"
  elif [ -f "$dir/dns" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && dns_args[${#dns_args[@]}]="$line"
    done < "$dir/dns"

    if [ "${#dns_args[@]}" -gt 0 ]; then
      sudo networksetup -setdnsservers "$svc" "${dns_args[@]}"
    else
      sudo networksetup -setdnsservers "$svc" "Empty"
    fi
  fi

  sudo dscacheutil -flushcache >/dev/null 2>&1 || true
  sudo killall -HUP mDNSResponder >/dev/null 2>&1 || true

  echo "Ağ ayarları geri yüklendi / Network settings restored."
}

check_static_host_conflict() {
  local iface router current candidate

  iface="$(default_interface)"
  [ -n "$iface" ] || return 1

  router="$(route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}')"
  current="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"

  [ -n "$router" ] || return 1
  candidate="${router%.*}.240"

  if [ "$candidate" = "$router" ]; then
    echo "Güvenli statik IP seçilemedi / Could not select a safe static IP."
    return 1
  fi

  if [ "$candidate" = "$current" ]; then
    echo "Statik IP zaten bu Mac tarafından kullanılıyor / Static IP is already used by this Mac: $candidate"
    return 0
  fi

  if ping -c 1 -t 1 "$candidate" >/dev/null 2>&1; then
    echo "IP çakışması tespit edildi / IP conflict detected: $candidate"
    echo ".240 adresi kullanılmayacak; güvenli şekilde devam edilecek."
    echo ".240 will not be relied on; continuing under connectivity-check protection."
    echo "MacDPI statik IP ayarlayamazsa mevcut DHCP bağlantısıyla devam edebilir."
    echo "If MacDPI cannot set the static IP, it may continue with the current DHCP connection."
    echo "Bağlantı testi başarısız olursa otomatik rollback uygulanacak."
    echo "If connectivity fails, automatic rollback will restore the saved network settings."
    return 0
  fi

  echo "Statik IP ön kontrolü geçti / Static IP pre-check passed: $candidate"
  return 0
}

internet_ok() {
  local url
  for url in     "https://www.apple.com/library/test/success.html"     "https://www.cloudflare.com/cdn-cgi/trace"     "https://www.google.com/generate_204"
  do
    if curl -fsS --connect-timeout 5 --max-time 10 -o /dev/null "$url" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}
