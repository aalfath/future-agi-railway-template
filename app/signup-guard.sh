#!/usr/bin/env bash
# Closes public sign-up (POST /accounts/signup/ at the edge proxy) once the
# first account exists, so people who find the URL can't create their own
# organizations on your instance. Invite teammates from the app instead.
# Set FUTURE_AGI_OPEN_SIGNUP=true to keep sign-up open.
# The flag lives on the volume (/data) so it survives redeploys; nginx workers
# run as nobody and can't read /data, so it's mirrored to /run/railway-edge.
FLAG=/data/.railway-signup-closed
EDGE_FLAG=/run/railway-edge/signup-closed
mkdir -p /run/railway-edge && chmod 755 /run/railway-edge
if [ "${FUTURE_AGI_OPEN_SIGNUP:-false}" = "true" ]; then
  rm -f "$FLAG" "$EDGE_FLAG"
  echo "[signup-guard] FUTURE_AGI_OPEN_SIGNUP=true: sign-up stays open"
  exec sleep infinity
fi
while true; do
  if [ -f "$FLAG" ]; then
    [ -f "$EDGE_FLAG" ] || { touch "$EDGE_FLAG"; chmod 644 "$EDGE_FLAG"; }
  else
    if python -I -S - <<'PY' 2>/dev/null
import json, sys, urllib.request as u
o = u.build_opener(u.ProxyHandler({}))
with o.open("http://127.0.0.1:8000/api/setup-checks/?mode=live", timeout=30) as r:
    body = json.load(r)
sys.exit(0 if (body.get("result") or {}).get("account_exists") else 1)
PY
    then
      touch "$FLAG" "$EDGE_FLAG"; chmod 644 "$EDGE_FLAG"
      echo "[signup-guard] the first account exists: public sign-up is now closed (invite teammates from the app)"
    fi
  fi
  sleep 10
done
