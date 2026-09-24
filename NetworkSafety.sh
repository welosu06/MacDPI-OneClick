#!/bin/bash

MACDPI_ROOT="${MACDPI_ROOT:-$HOME/.macdpi-oneclick}"
BACKUPS_ROOT="${BACKUPS_ROOT:-$MACDPI_ROOT/network-backups}"
ACTIVE_BACKUP_FILE="${ACTIVE_BACKUP_FILE:-$MACDPI_ROOT/active-backup}"
LEGACY_BACKUP_DIR="${LEGACY_BACKUP_DIR:-$MACDPI_ROOT/network-backup}"
LOCK_DIR="${LOCK_DIR:-$MACDPI_ROOT/.operation-lock}"
STATIC_HOST_CONFLICT=0

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

current_router() {
  route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}'
}

current_ssid() {
  local iface="$1"
  networksetup -getairportnetwork "$iface" 2>/dev/null | sed 's/^Current Wi-Fi Network: //' | grep -v '^You are not associated' || true
}

network_context_id() {
  local iface svc router ssid raw
  iface="$(default_interface)"
  svc="$(active_network_service 2>/dev/null || true)"
  router="$(current_router)"
  ssid="$(current_ssid "$iface")"
  raw="${iface}|${svc}|${router}|${ssid}"
  printf '%s' "$raw" | shasum -a 256 | awk '{print substr($1,1,12)}'
}

acquire_lock() {
  mkdir -p "$MACDPI_ROOT"
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    echo "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  local oldpid
  oldpid="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
    echo "Başka bir MacDPI işlemi zaten çalışıyor / Another MacDPI operation is already running."
    return 1
  fi

  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR"
  echo "$$" > "$LOCK_DIR/pid"
}

release_lock() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}

import_legacy_backup() {
  [ -f "$ACTIVE_BACKUP_FILE" ] && return 0
  [ -f "$LEGACY_BACKUP_DIR/complete" ] || return 0

  local stamp dest
  stamp="$(date +%Y%m%d-%H%M%S)"
  dest="$BACKUPS_ROOT/${stamp}-legacy"
  mkdir -p "$BACKUPS_ROOT"
  cp -R "$LEGACY_BACKUP_DIR" "$dest"
  printf '%s\n' "$dest" > "$ACTIVE_BACKUP_FILE"
  echo "Eski ağ yedeği yeni güvenlik sistemine aktarıldı / Legacy network backup imported."
}

prune_backups() {
  local keep="${1:-12}"
  [ -d "$BACKUPS_ROOT" ] || return 0
  local count=0 dir
  for dir in $(ls -1dt "$BACKUPS_ROOT"/* 2>/dev/null || true); do
    count=$((count + 1))
    if [ "$count" -gt "$keep" ]; then
      rm -rf "$dir"
    fi
  done
}

backup_current_network() {
  local svc info mode ip mask router dns context stamp dir line
  local dns_found=0

  svc="$(active_network_service)" || {
    echo "Aktif ağ servisi bulunamadı / Active network service not found."
    return 1
  }

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
  context="$(network_context_id)"
  stamp="$(date +%Y%m%d-%H%M%S)"
  dir="$BACKUPS_ROOT/${stamp}-${context}"

  mkdir -p "$dir"
  printf '%s\n' "$svc" > "$dir/service"
  printf '%s\n' "$mode" > "$dir/mode"
  printf '%s\n' "$ip" > "$dir/ip"
  printf '%s\n' "$mask" > "$dir/mask"
  printf '%s\n' "$router" > "$dir/router"
  printf '%s\n' "$(default_interface)" > "$dir/interface"
  printf '%s\n' "$(current_ssid "$(default_interface)")" > "$dir/ssid"

  dns="$(networksetup -getdnsservers "$svc" 2>&1 || true)"
  : > "$dir/dns"
  while IFS= read -r line; do
    if printf '%s\n' "$line" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9A-Fa-f:]+$'; then
      printf '%s\n' "$line" >> "$dir/dns"
      dns_found=1
    fi
  done <<EOF
$dns
EOF

  if [ "$dns_found" -eq 0 ]; then
    rm -f "$dir/dns"
    touch "$dir/dns.empty"
  fi

  date > "$dir/created_at"
  touch "$dir/complete"
  printf '%s\n' "$dir" > "$ACTIVE_BACKUP_FILE"
  prune_backups 12

  echo "Ağ ayarları yedeklendi / Network settings backed up."
  echo "Yedek / Backup: $dir"
}

active_backup_dir() {
  [ -f "$ACTIVE_BACKUP_FILE" ] || return 1
  local dir
  dir="$(cat "$ACTIVE_BACKUP_FILE" 2>/dev/null || true)"
  [ -n "$dir" ] && [ -f "$dir/complete" ] || return 1
  printf '%s\n' "$dir"
}

restore_backup_dir() {
  local dir="$1"
  local svc mode ip mask router line
  local dns_args=()

  [ -f "$dir/complete" ] || return 1

  svc="$(cat "$dir/service" 2>/dev/null || true)"
  mode="$(cat "$dir/mode" 2>/dev/null || true)"
  ip="$(cat "$dir/ip" 2>/dev/null || true)"
  mask="$(cat "$dir/mask" 2>/dev/null || true)"
  router="$(cat "$dir/router" 2>/dev/null || true)"

  [ -n "$svc" ] || return 1

  echo "Ağ ayarları geri yükleniyor / Restoring network settings..."
  echo "Servis / Service: $svc"

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

restore_active_backup() {
  local dir
  dir="$(active_backup_dir)" || {
    echo "Aktif ağ yedeği bulunamadı / Active network backup not found."
    return 1
  }
  restore_backup_dir "$dir"
}

check_static_host_conflict() {
  local iface router current candidate
  STATIC_HOST_CONFLICT=0

  iface="$(default_interface)"
  [ -n "$iface" ] || return 0
  router="$(current_router)"
  current="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
  [ -n "$router" ] || return 0

  candidate="${router%.*}.240"

  if [ "$candidate" = "$current" ]; then
    echo "Bu Mac zaten $candidate kullanıyor / This Mac already uses $candidate."
    return 0
  fi

  if ping -c 1 -t 1 "$candidate" >/dev/null 2>&1; then
    STATIC_HOST_CONFLICT=1
    echo "UYARI / WARNING: $candidate başka bir cihaz tarafından kullanılıyor olabilir."
    echo "$candidate may already be in use by another device."
    echo "Adres zorlanmayacak. MacDPI çalışırsa devam edilecek ve bağlantı test edilecek."
    echo "The address will not be forced. If MacDPI can continue, connectivity will be verified."
  else
    echo "Statik IP ön kontrolü geçti / Static IP pre-check passed: $candidate"
  fi
  return 0
}

vpn_warning() {
  if ifconfig 2>/dev/null | grep -Eq '^utun[0-9]+:'; then
    echo
    echo "UYARI / WARNING: VPN/Private Relay benzeri bir utun arayüzü algılandı."
    echo "A VPN/Private Relay-style utun interface was detected."
    echo "Bu her zaman sorun değildir; bağlantı testi sonucu belirleyici olacaktır."
    echo "This is not always a problem; the connectivity test will decide."
    echo
  fi
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

verify_restored_network() {
  local i
  for i in 1 2 3; do
    sleep 2
    if internet_ok; then
      echo "Normal internet bağlantısı doğrulandı / Normal internet connection verified."
      return 0
    fi
  done
  echo "UYARI / WARNING: Ağ ayarları geri yüklendi ancak internet doğrulanamadı."
  echo "Network settings were restored, but internet connectivity could not be verified."
  return 1
}

captive_portal_warning() {
  local body
  body="$(curl -fsS --connect-timeout 4 --max-time 8 https://www.apple.com/library/test/success.html 2>/dev/null || true)"
  if [ -n "$body" ] && ! printf '%s' "$body" | grep -qi "Success"; then
    echo "UYARI / WARNING: Giriş sayfası (captive portal) olan bir ağ kullanıyor olabilirsin."
    echo "You may be on a captive-portal network. Complete Wi-Fi sign-in first."
  fi
}

check_disk_space() {
  local available_kb
  available_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
  if [ -n "$available_kb" ] && [ "$available_kb" -lt 2097152 ]; then
    echo "En az yaklaşık 2 GB boş alan önerilir / About 2 GB of free space is recommended."
    return 1
  fi
  return 0
}

service_loaded() {
  launchctl print "system/com.macdpi" >/dev/null 2>&1
}

sanitize_stream() {
  sed -E     -e "s|$HOME|~|g"     -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/<IPv4-redacted>/g'     -e 's/[0-9A-Fa-f]{0,4}(:[0-9A-Fa-f]{0,4}){2,7}/<IPv6-redacted>/g'
}
