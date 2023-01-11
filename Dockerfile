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
        libgloox-dev libicu-dev \
        libminiupnpc-dev \
        libogg-dev  \
        libopenal-dev   \
        libpng-dev  \
        libsdl2-dev \
        libsodium-dev   \
        libvorbis-dev \
        libwxgtk3.0-gtk3-dev \
        libxml2-dev \
        python3 \
        rustc   \
        zlib1g-dev &&  \
    apt install -y  \
        curl    \
        patchelf    \
        wget && \
    rm -rf /var/lib/apt/lists

RUN useradd -M -U 0ad && passwd -d 0ad
