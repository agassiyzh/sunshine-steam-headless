#!/bin/bash
set -euo pipefail

echo "[entrypoint] Starting dbus if needed..."
if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
  dbus-daemon --system --fork || true
fi

echo "[entrypoint] Starting pulseaudio (system-less)..."
pulseaudio --start || true

# Start Xorg with dummy/nvidia headless config
echo "[entrypoint] Starting Xorg :0 ..."
# -nolisten tcp avoids binding TCP
# -noreset keeps X running
Xorg :0 -config /etc/X11/xorg.conf -nolisten tcp -noreset >/var/log/xorg.log 2>&1 &

# Give Xorg a moment to initialize and let the driver bind
sleep 2

export DISPLAY=:0
echo "[entrypoint] DISPLAY=$DISPLAY"

# Optional: start Steam Big Picture (uncomment if Steam is installed and you want auto-start)
# echo "[entrypoint] Starting Steam (Big Picture)..."
# su -s /bin/bash -c "DISPLAY=:0 steam -tenfoot &" $(whoami) || true

# Start Sunshine pointing to /config
echo "[entrypoint] Starting Sunshine..."
# Sunshine will create its config under /config if missing
sunshine -c /config

# If sunshine exits, keep container alive for debugging
sleep infinity