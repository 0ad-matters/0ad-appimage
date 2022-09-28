FROM ubuntu:bionic

# needed for spidermonkey build
ENV SHELL=/bin/bash

ENV WORKDIR_PATH=/build
ENV CC=gcc-8 CXX=g++-8
RUN apt update && apt -y upgrade && \
    apt install -y $CC $CXX build-essential cargo cmake libboost-dev libboost-system-dev   \
    libboost-filesystem-dev libcurl4-gnutls-dev libenet-dev libfmt-dev   \
    libfreetype6-dev libgloox-dev libicu-dev \
    libpng-dev libsdl2-dev libsodium-dev libvorbis-dev \
    libxml2-dev python3 rustc zlib1g-dev libminiupnpc-dev \
    libopenal-dev libogg-dev libwxgtk3.0-gtk3-dev && \
    apt install -y wget patchelf

WORKDIR $WORKDIR_PATH
RUN useradd -M -U 0ad && passwd -d 0ad
RUN chown 0ad:0ad $WORKDIR_PATH
USER 0ad

