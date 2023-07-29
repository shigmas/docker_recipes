FROM ubuntu:22.04

ARG QT_VERSION=6.6

ENV QT_VERSION=$QT_VERSION

# got this from https://www.ics.com/blog/how-build-qt-640-source-ubuntu-linux
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive TZ=Asia/Japan \
	apt install -y bison build-essential clang flex gperf \
	libatspi2.0-dev libbluetooth-dev libclang-dev libcups2-dev libdrm-dev \
	libegl1-mesa-dev libfontconfig1-dev libfreetype6-dev \
	libgstreamer1.0-dev libhunspell-dev libnss3-dev libopengl-dev \
	libpulse-dev libssl-dev libts-dev libx11-dev libx11-xcb-dev \
	libxcb-glx0-dev libxcb-icccm4-dev libxcb-image0-dev \
	libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render-util0-dev \
	libxcb-shape0-dev libxcb-shm0-dev libxcb-sync-dev libxcb-util-dev \
	libxcb-xfixes0-dev libxcb-xinerama0-dev libxcb-xkb-dev libxcb1-dev \
	libxcomposite-dev libxcursor-dev libxdamage-dev libxext-dev \
	libxfixes-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev \
	libxkbfile-dev libxrandr-dev libxrender-dev libxshmfence-dev \
	libxshmfence1 llvm ninja-build nodejs python-is-python3 python3

# May or not be already installed. vim, sudo, and cmake is needed. Maybe git
# and perl are part of build-essential? Too much time rebuild to find out.
RUN DEBIAN_FRONTEND=noninteractive TZ=Asia/Japan \
    apt-get install -y sudo vim git perl cmake

WORKDIR /opt/qt"$QT_VERSION"
RUN useradd -ms /bin/bash builder && usermod -aG sudo builder
RUN echo builder:builder | chpasswd
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/010_system_sudoers
RUN chmod 440 /etc/sudoers.d/010_system_sudoers
USER builder

WORKDIR /build/src
RUN git clone git://code.qt.io/qt/qt5.git
WORKDIR /build/src/qt5
RUN perl init-repository

RUN DEBIAN_FRONTEND=noninteractive TZ=Asia/Japan \
    sudo apt-get install -y 

# out of source build
WORKDIR /build/qt"$QT_VERSION"
RUN /build/src/qt5/configure -prefix /opt/qt"$QT_VERSION" -release
RUN cmake --build . --parallel 4
#RUN cmake --install .
