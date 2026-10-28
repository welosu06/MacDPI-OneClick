#!/bin/bash
set -eu
TARGET="${1:?patched upstream path required}"
source "$TARGET/core/NetworkReady.sh"
STATE="$(mktemp)"
trap 'rm -f "$STATE"' EXIT
printf 0 > "$STATE"
physical_network() {
  local n
  n=$(cat "$STATE"); n=$((n+1)); printf '%s' "$n" > "$STATE"
  case "$n" in 1|2) return 1 ;; 3) echo 'en0 192.0.2.1' ;; *) echo 'en0 192.0.2.2' ;; esac
}
sleep() { :; }
wait_for_network
test "$(cat "$STATE")" = 7
test "$MACDPI_BIND_INTERFACE" = en0
test "$MACDPI_NETWORK_SIGNATURE" = 'en0 192.0.2.2'
# Execute the shipped supervisor loop with real short-lived workers and stubbed network.
LOOP="$(sed -n '/^network_misses=0/,$p' "$TARGET/Run.sh")"
export LOOP
for scenario in worker_exit network_change; do
  if /bin/bash -c '
    scenario=$1
    sleep() { /bin/sleep 0.05; }
    /bin/sleep 5 & dpi_pid=$!
    /bin/sleep 5 & box_pid=$!
    trap '\''kill "$dpi_pid" "$box_pid" 2>/dev/null || true'\'' EXIT
    MACDPI_NETWORK_SIGNATURE="en0 192.0.2.2"
    physical_network() {
      if [ "$scenario" = network_change ]; then echo "en1 192.0.2.3"; else echo "$MACDPI_NETWORK_SIGNATURE"; fi
    }
    if [ "$scenario" = worker_exit ]; then kill "$dpi_pid"; wait "$dpi_pid" 2>/dev/null || true; fi
    eval "$LOOP"
  ' test "$scenario"; then
    echo "Supervisor did not fail closed: $scenario" >&2; exit 1
  fi
done
echo 'Boot readiness and supervisor regression checks passed.'
