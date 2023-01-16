FROM ubuntu:bionic

# needed for spidermonkey build
ENV SHELL=/bin/bash

ENV CC=gcc-8 CXX=g++-8
RUN apt update &&   \
    apt -y upgrade && \
    apt install -y  \
        $CC \
        $CXX \
        build-essential \
        cargo   \
        cmake   \
        libboost-dev    \
        libboost-filesystem-dev \
        libboost-system-dev   \
        libcurl4-gnutls-dev \
        libenet-dev \
        libfmt-dev   \
        libfreetype6-dev    \
        libgloox-dev    \
        libicu-dev \
        libminiupnpc-dev \
        libogg-dev  \
        libopenal-dev   \
        libpng-dev  \
        libsdl2-dev \
        libsodium-dev   \
        libvorbis-dev \
        libvulkan-dev   \
        libwxgtk3.0-gtk3-dev \
        libxml2-dev \
        m4 \
        python3 \
        subversion \
        rustc   \
        zlib1g-dev &&  \
    apt install -y  \
        curl    \
        patchelf    \
        wget && \
    rm -rf /var/lib/apt/lists

ENV TOOLS_DIR="/tools"
RUN mkdir -m 777 -p $TOOLS_DIR

RUN /bin/bash -c 'cd $TOOLS_DIR \
    && curl -LO https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/linuxdeploy-x86_64.AppImage \
    && chmod +x linuxdeploy-x86_64.AppImage \
    && ./linuxdeploy-x86_64.AppImage --appimage-extract \
    && rm ./linuxdeploy-x86_64.AppImage \
    && cd -'

RUN useradd -M -U 0ad && passwd -d 0ad
ENV DOCKER_0AD_BUILD=TRUE
CMD ["/bin/bash","-l"]
