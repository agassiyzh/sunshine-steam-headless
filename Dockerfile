# Dockerfile - Ubuntu 24.04 base for Sunshine + Xorg dummy + Steam (optional)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV SUNSHINE_CONFIG_DIR=/config

# Install core dependencies and Sunshine
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    gnupg \
    lsb-release \
    xserver-xorg-core \
    xinit \
    x11-xserver-utils \
    xserver-xorg-video-dummy \
    dbus-x11 \
    pulseaudio \
    pulseaudio-utils \
    alsa-utils \
    libevdev2 \
    libminiupnpc17 \
    libayatana-appindicator3-1 \
    libnotify4 \
    unzip \
    fonts-noto \
    lsof \
    procps \
    fonts-noto-cjk \
    gosu \
    openbox \
    jq \
    && LATEST_TAG=$(curl -sL "https://api.github.com/repos/LizardByte/Sunshine/releases/latest" | jq -r '.tag_name') \
    && SUNSHINE_DEB_URL="https://github.com/LizardByte/Sunshine/releases/download/${LATEST_TAG}/sunshine-ubuntu-24.04-amd64.deb" \
    && wget -O /tmp/sunshine.deb "${SUNSHINE_DEB_URL}" \
    && apt-get install -y /tmp/sunshine.deb \
    && rm /tmp/sunshine.deb \
    && rm -rf /var/lib/apt/lists/*

# Optional: Install Steam if INSTALL_STEAM is set to true
ARG INSTALL_STEAM=true
RUN if [ "$INSTALL_STEAM" = "true" ]; then \
    dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y steam-installer \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Install systemd (Removed) and Supervisor
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Copy xorg config and entrypoint (now init-setup)
COPY xorg.conf /etc/X11/xorg.conf
COPY entrypoint.sh /usr/local/bin/init-setup.sh
RUN chmod +x /usr/local/bin/init-setup.sh

# Copy supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose Sunshine ports
EXPOSE 47989/tcp 47990/tcp 47998/udp 47999/udp

VOLUME ["/config"]
STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
