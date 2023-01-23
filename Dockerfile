FROM ubuntu:bionic
ARG DEBIAN_FRONTEND=noninteractive
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
ARG ARCH=x86_64
RUN /bin/bash -c 'cd $TOOLS_DIR \
    && curl -LO https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/linuxdeploy-${ARCH}.AppImage \
    && chmod +x linuxdeploy-${ARCH}.AppImage \
    && ./linuxdeploy-${ARCH}.AppImage --appimage-extract \
    && rm ./linuxdeploy-${ARCH}.AppImage \
    && cd -'

ARG MINISIGN_VERSION="0.11"
ENV MINISIGN_PATH=${TOOLS_DIR}/minisign
ARG MINISIGN_URL=https://github.com/jedisct1/minisign/releases/download/${MINISIGN_VERSION}
RUN /bin/bash -c 'curl -LO ${MINISIGN_URL}/minisign-${MINISIGN_VERSION}-linux.tar.gz \
    && curl -LO ${MINISIGN_URL}/minisign-${MINISIGN_VERSION}-linux.tar.gz.minisig \
    && tar xf minisign-${MINISIGN_VERSION}-linux.tar.gz -C ${TOOLS_DIR} \
    && mv ${TOOLS_DIR}/minisign-linux/${ARCH}/minisign ${TOOLS_DIR} \
    && $MINISIGN_PATH -Vm minisign-$MINISIGN_VERSION-linux.tar.gz -P RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3 \
    && rm -rf ${TOOLS_DIR}/minisign-${MINISIGN_VERSION}-linux/${ARCH} minisign-${MINISIGN_VERSION}-linux.tar.gz'

RUN useradd -m 0adbuilder && passwd -d 0adbuilder
ENV DOCKER_0AD_BUILD=TRUE
# needed for spidermonkey build
ENV SHELL=/bin/bash

ENV CC=gcc-8 CXX=g++-8
CMD ["/bin/bash","-l"]
