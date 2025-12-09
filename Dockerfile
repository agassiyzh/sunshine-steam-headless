# Dockerfile - Ubuntu 24.04 base for Sunshine + Xorg dummy + Steam (optional)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV SUNSHINE_CONFIG_DIR=/config

# Install core deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget curl gnupg lsb-release \
    xserver-xorg-core xinit x11-xserver-utils xserver-xorg-video-dummy \
    dbus-x11 pulseaudio pulseaudio-utils alsa-utils \
    ca-certificates unzip fonts-noto lsof procps fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# Optional: install steam-installer if you want Steam in container
# (uncomment if you need Steam inside)
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y steam-installer && rm -rf /var/lib/apt/lists/*

# Download, install, and verify Sunshine
RUN set -eux; \
    wget -O /tmp/sunshine.deb "${SUNSHINE_DEB_URL}"; \
    \
    echo "--- Listing contents of sunshine.deb ---"; \
    dpkg -c /tmp/sunshine.deb; \
    echo "----------------------------------------"; \
    \
    # Attempt to install, this may fail due to missing dependencies
    dpkg -i /tmp/sunshine.deb || true; \
    \
    # Fix missing dependencies and finish the installation
    apt-get update; \
    apt-get -f install -y --no-install-recommends; \
    \
    # Verify that sunshine was installed correctly and is executable
    echo "--- Verifying sunshine installation ---"; \
    ls -l /usr/bin/sunshine; \
    /usr/bin/sunshine --version; \
    \
    # Clean up
    rm /tmp/sunshine.deb



# 僅安裝 gosu，動態建用戶與目錄交由 entrypoint.sh 處理
RUN apt-get update && apt-get install -y --no-install-recommends gosu && rm -rf /var/lib/apt/lists/*

# Copy xorg config and entrypoint
COPY xorg.conf /etc/X11/xorg.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Sunshine ports
EXPOSE 47989/tcp 47990/tcp 47998/udp 47999/udp

VOLUME ["/config"]

ENTRYPOINT ["/entrypoint.sh"]