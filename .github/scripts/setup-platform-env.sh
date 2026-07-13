#!/bin/bash

echo "Setup env for ${PLATFORM} platform..."
echo "/home/runner/py-env/bin" >> $GITHUB_PATH

if [[ "$PLATFORM" == "pico" ]]; then
    echo "PICO_SDK_PATH=${WORKSPACE}/libraries/pico-sdk" >> $GITHUB_ENV
elif [[ "$PLATFORM" == "maxim" ]]; then
    echo "CMAKE_GENERATOR=Ninja" >> $GITHUB_ENV
    echo "test ninja"
    which "ninja"
elif [[ "$PLATFORM" == "aducm3029" ]]; then
    sudo apt-get update && sudo apt-get install -y \
        wget cmake build-essential zip unzip git \
        python3 python3-pip python3.12-venv
    python3 -m venv /home/runner/py-env
    python3 -m pip install cloudsmith-cli
    sudo dpkg --add-architecture i386 && sudo apt update && apt-get install -y \
        libgpm2:i386 libc6:i386 libstdc++6:i386 gtk2-engines-murrine:i386 libcanberra-gtk-module:i386 gtk2-engines:i386
    sudo wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_i386.deb && \
        sudo apt-get install -y ./libtinfo5_6.3-2_i386.deb
    sudo wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_i386.deb && \
        sudo apt-get install -y ./libncurses5_6.3-2_i386.deb
    sudo wget wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.2_amd64.deb && \
        sudo apt-get install -y ./libtinfo5_6.3-2ubuntu0.2_amd64.deb
    sudo wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncursesw5_6.3-2ubuntu0.2_amd64.deb && \
        sudo apt-get install -y ./libncursesw5_6.3-2ubuntu0.2_amd64.deb
    sudo cp ${WORKSPACE}/.github/config/_ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources && \
        sudo apt update && apt-get install -y libwebkitgtk-6.0-4 libwebkit2gtk-4.1-0 libwebkit2gtk-4.0-37
    sudo mkdir -p /opt/analog/cces/3.0.4
    clousmith pull ${TOOLS_REPO}/analog_cces.tar.gz
    tar -xvf analog_cces.tar.gz
    cp -r analog_cces/* /opt/analog/cces/3.0.4/
    wget https://github.com/Open-CMSIS-Pack/cpackget/releases/download/v2.2.1/cpackget_2.2.1_linux_amd64.tar.gz && \
        tar -xvf cpackget_2.2.1_linux_amd64.tar.gz && sudo mv cpackget_2.2.1_linux_amd64/cpackget /usr/local/bin
    cpackget add -a --insecure-skip-verify AnalogDevices::ADuCM302x_DFP@4.0.0
    cpackget add -a --insecure-skip-verify ARM::CMSIS@6.3.0
fi
