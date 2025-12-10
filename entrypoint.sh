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
  
  # Add user to the standard 'video' group
  usermod -aG video "$STEAM_USER" || true

  # Handle RENDER_GID if passed (for /dev/dri access)
  if [ -n "${RENDER_GID:-}" ]; then
    echo "[init-setup] RENDER_GID provided: $RENDER_GID"
    if ! getent group "$RENDER_GID" >/dev/null; then
      echo "[init-setup] Creating group for GID $RENDER_GID"
      groupadd -g "$RENDER_GID" render_custom
    fi
    usermod -aG "$RENDER_GID" "$STEAM_USER" || true
  fi

  # Add to input group if it exists (for /dev/uinput fallback)
  if getent group input >/dev/null; then
    usermod -aG input "$STEAM_USER" || true
  fi

  # Change ownership of uinput to the steam user
  chown "$STEAM_UID:$STEAM_GID" /dev/uinput || true
  
  
  
# 確保主目錄和 /config 權限正確
  # Generate machine-id for dbus
  dbus-uuidgen --ensure

  mkdir -p /run/dbus
  chown -R "$STEAM_UID:$STEAM_GID" "$STEAM_HOME" /config 2>/dev/null || true
  chown -R "$STEAM_UID:$STEAM_GID" /run/dbus 2>/dev/null || true
  
  echo "[init-setup] Initialization complete." > /dev/console
fi

