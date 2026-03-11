#!/bin/sh
set -eu

CONF=/tmp/dnsmasq.conf
PID=/tmp/dnsmasq.pid
LOG=/tmp/dnsmasq.log

# Upstreams from resolv.conf, excluding localhost to avoid loops
UPSTREAMS="$(awk '/^nameserver[ \t]+/ {print $2}' /etc/resolv.conf | grep -vE '^(127\.0\.0\.1|::1)$' || true)"

{
  echo "listen-address=127.0.0.1"
  echo "bind-interfaces"
  echo "port=53"

  # IMPORTANT: prevent dnsmasq from trying to switch to user 'dnsmasq'
  echo "user=dev"
  echo "group=dev"

  # Filter out IPv6 answers
  echo "filter-AAAA"

  echo "no-resolv"
  echo "pid-file=$PID"
  echo "log-facility=$LOG"

  if [ -n "$UPSTREAMS" ]; then
    for ns in $UPSTREAMS; do
      echo "server=$ns"
    done
  else
    # fallback
    echo "server=1.1.1.1"
    echo "server=8.8.8.8"
  fi
} > "$CONF"

dnsmasq --test --conf-file="$CONF" >/dev/null

# Start dnsmasq; if it fails, print log and exit non-zero (so you see why)
dnsmasq --conf-file="$CONF" || { echo "dnsmasq failed"; [ -f "$LOG" ] && tail -n 200 "$LOG"; exit 1; }

exec "$@"
