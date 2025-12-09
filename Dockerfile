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

# Download Sunshine deb from releases (if URL unavailable, replace with local deb)
ARG SUNSHINE_DEB_URL="https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-ubuntu-24.04-amd64.deb"
RUN set -eux; \
    wget -O /tmp/sunshine.deb "${SUNSHINE_DEB_URL}" || true; \
    if [ -f /tmp/sunshine.deb ]; then dpkg -i /tmp/sunshine.deb || apt-get -f install -y; fi; \
    rm -f /tmp/sunshine.deb || true

# Create config dir
RUN mkdir -p ${SUNSHINE_CONFIG_DIR} && chmod 777 ${SUNSHINE_CONFIG_DIR}

# Copy xorg config and entrypoint
COPY xorg.conf /etc/X11/xorg.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Sunshine ports
EXPOSE 47989/tcp 47990/tcp 47998/udp 47999/udp

VOLUME ["/config"]

ENTRYPOINT ["/entrypoint.sh"]