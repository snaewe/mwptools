FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-24.04

ENV PYTHONUNBUFFERED 1

# [Optional] If your requirements rarely change, uncomment this section to add them to the image.
# COPY requirements.txt /tmp/pip-tmp/
# RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
#    && rm -rf /tmp/pip-tmp

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
     && apt-get -y install --no-install-recommends \
     libvte-2.91-gtk4-dev \
     blueprint-compiler \
     libprotobuf-c-dev \
     libshumate-dev \
     libpaho-mqtt-dev \
     libgtk-4-dev \
     libadwaita-1-dev \
     libsecret-1-dev \
     valac \
     pkg-config \
     build-essential \
     ninja-build \
     libbluetooth-dev \
     libespeak-dev \
     libgudev-1.0-dev \
     libgstreamer1.0-dev \
     libgstreamer-plugins-base1.0-dev \
     libprotobuf-c-dev \
     librsvg2-dev \
     libxml2-utils \
     desktop-file-utils \
     libncurses5-dev \
     golang-go \
     ruby \
     ruby-json \
     pipx

RUN pipx install meson
