#!/bin/bash
set -euo pipefail


# --- 自動安裝與宿主機相同版本的 NVIDIA 驅動 ---
# if command -v nvidia-smi >/dev/null 2>&1; then
#   HOST_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
#   echo "[entrypoint] 宿主機 NVIDIA 驅動版本: $HOST_DRIVER_VERSION"
#   # 檢查容器內驅動版本
#   if modinfo nvidia 2>/dev/null | grep -q "version: *$HOST_DRIVER_VERSION"; then
#     echo "[entrypoint] 容器內已安裝相同版本 NVIDIA 驅動 ($HOST_DRIVER_VERSION)"
#   else
#     echo "[entrypoint] 容器內未安裝 NVIDIA 驅動或版本不符，開始安裝..."
#     # 下載對應版本驅動，優先中國鏡像，失敗則回退官方 US 站點
#     DRIVER_RUN="NVIDIA-Linux-x86_64-$HOST_DRIVER_VERSION.run"
#     TUNA_URL="https://mirrors.tuna.tsinghua.edu.cn/nvidia/driver/$DRIVER_RUN"
#     US_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/$HOST_DRIVER_VERSION/$DRIVER_RUN"
#     echo "[entrypoint] 嘗試從 TUNA 清華鏡像下載 NVIDIA 驅動... ($TUNA_URL)"
#     if wget -O "/tmp/$DRIVER_RUN" "$TUNA_URL"; then
#       echo "[entrypoint] 成功從 TUNA 鏡像下載 NVIDIA 驅動。"
#     else
#       echo "[entrypoint] TUNA 鏡像下載失敗，回退官方 US 站點... ($US_URL)"
#       wget -O "/tmp/$DRIVER_RUN" "$US_URL"
#     fi
#     chmod +x "/tmp/$DRIVER_RUN"
#     # 安裝 kernel headers (假設基於 Debian/Ubuntu)
#     apt-get update && apt-get install -y linux-headers-$(uname -r) || true
#     # 安裝驅動（無互動、無 X、允許覆蓋）
#     sh "/tmp/$DRIVER_RUN" --silent --no-questions --disable-nouveau --no-x-check --no-kernel-module || true
#     rm -f "/tmp/$DRIVER_RUN"
#     echo "[entrypoint] NVIDIA 驅動安裝完成（如有錯誤請檢查 kernel headers 與特權模式）"
#   fi
# else
#   echo "[entrypoint] 無法偵測宿主機 NVIDIA 驅動，請確認 nvidia-smi 可用。"
# fi

echo "[entrypoint] Starting pulseaudio (system-less)..."
pulseaudio --start || true


# 根據環境變數動態建立 steam 用戶並切換
STEAM_UID=${STEAM_UID:-568}
STEAM_GID=${STEAM_GID:-568}
STEAM_USER=steam
STEAM_HOME=/home/$STEAM_USER

if [ "$(id -u)" = "0" ]; then
  if ! getent group "$STEAM_GID" >/dev/null; then
    groupadd -g "$STEAM_GID" "$STEAM_USER"
  fi
  if ! id -u "$STEAM_USER" >/dev/null 2>&1; then
    useradd -m -u "$STEAM_UID" -g "$STEAM_GID" "$STEAM_USER" -s /bin/bash
  fi
  # 確保主目錄和 /config 權限正確
  mkdir -p /run/dbus
  chown -R "$STEAM_UID:$STEAM_GID" "$STEAM_HOME" /config 2>/dev/null || true
  chown -R "$STEAM_UID:$STEAM_GID" /run/dbus 2>/dev/null || true
  echo "[entrypoint] 切換到 $STEAM_USER 用戶 (UID $STEAM_UID) 執行主流程..."
  exec gosu "$STEAM_USER" "$0" "$@"
fi

echo "[entrypoint] Starting pulseaudio (system-less)..."
pulseaudio --start || true

echo "[entrypoint] Starting dbus if needed..."
if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
  dbus-daemon --system --fork || true
fi

# Start Xorg with dummy/nvidia headless config
# -nolisten tcp avoids binding TCP
# -noreset keeps X running
Xorg :0 -config /etc/X11/xorg.conf -nolisten tcp -noreset >/home/steam/xorg.log 2>&1 &

# Give Xorg a moment to initialize and let the driver bind
sleep 2

export DISPLAY=:0
echo "[entrypoint] DISPLAY=$DISPLAY"

# Optional: start Steam Big Picture (uncomment if Steam is installed and you want auto-start)
# echo "[entrypoint] Starting Steam (Big Picture)..."
# steam -tenfoot &

# Start Sunshine pointing to /config
echo "[entrypoint] Starting Sunshine..."
SUNSHINE_CMD="/usr/bin/sunshine"

# Check if Sunshine is installed and executable
if [ ! -x "$SUNSHINE_CMD" ]; then
    echo "[entrypoint] ERROR: Sunshine executable not found or not executable at $SUNSHINE_CMD." >&2
    echo "[entrypoint] Please check if the Sunshine .deb package was installed correctly in the Dockerfile." >&2
    exit 1
fi

# Sunshine will create its config under /config if missing
"$SUNSHINE_CMD" /config/sunshine.conf

# If sunshine exits, keep container alive for debugging
sleep infinity