#!/bin/bash

echo "Setup env for ${PLATFORM} platform..."

if [[ "$PLATFORM" == "pico" ]]; then
    echo "/home/runner/py-env/bin" >> $GITHUB_PATH
    echo "VIRTUAL_ENV=/home/runner/py-env" >> $GITHUB_PATH
    echo "PICO_SDK_PATH=${WORKSPACE}/libraries/pico-sdk" >> $GITHUB_ENV
elif [[ "$PLATFORM" == "maxim" ]]; then
    echo "/home/runner/py-env/bin" >> $GITHUB_PATH
    echo "VIRTUAL_ENV=/home/runner/py-env" >> $GITHUB_PATH
    echo "CMAKE_GENERATOR=Ninja" >> $GITHUB_ENV
elif [[ "$PLATFORM" == "aducm3029" ]]; then
    echo "CCES_HOME=/opt/analog/cces/3.0.4" >> $GITHUB_ENV
    echo "/opt/analog/cces/3.0.4/ARM/arm-none-eabi/bin" >> $GITHUB_PATH
    echo "/opt/analog/cces/3.0.4/Eclipse" >> $GITHUB_PATH
    sudo apt-get update && sudo apt-get install -y \
        wget cmake build-essential zip unzip git \
        python3 python3-pip python3.12-venv gcc-arm-none-eabi
    python3 -m pip install cloudsmith-cli
    cloudsmith download ${TOOLS_REPO} build_aducm3029.tar.gz --version 1.0.0
    tar -xzf build_aducm3029.tar.gz --strip-components 1
    sudo dpkg --add-architecture i386 && sudo apt update && sudo apt-get install -y \
        libgpm2:i386 libc6:i386 libstdc++6:i386 gtk2-engines-murrine:i386 libcanberra-gtk-module:i386 gtk2-engines:i386
    sudo wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_i386.deb && \
        sudo apt-get install -y ./libtinfo5_6.3-2_i386.deb
    sudo wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_i386.deb && \
        sudo apt-get install -y ./libncurses5_6.3-2_i386.deb
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.2_amd64.deb && \
        sudo apt-get install -y ./libtinfo5_6.3-2ubuntu0.2_amd64.deb
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncursesw5_6.3-2ubuntu0.2_amd64.deb && \
        sudo apt-get install -y ./libncursesw5_6.3-2ubuntu0.2_amd64.deb
    sudo cp ${WORKSPACE}/.github/config/_ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources && \
        sudo apt update && sudo apt-get install -y libwebkitgtk-6.0-4 libwebkit2gtk-4.1-0 libwebkit2gtk-4.0-37
    sudo mkdir -p /opt/analog/cces/3.0.4
    cloudsmith download ${TOOLS_REPO} analog_cces.tar.gz  --version 3.0.4
    tar -xf analog_cces.tar.gz
    cp -r analog_cces/* /opt/analog/cces/3.0.4/
    wget https://github.com/Open-CMSIS-Pack/cpackget/releases/download/v2.2.1/cpackget_2.2.1_linux_amd64.tar.gz && \
        tar -xvf cpackget_2.2.1_linux_amd64.tar.gz && sudo mv cpackget_2.2.1_linux_amd64/cpackget /usr/local/bin
    cpackget add -a --insecure-skip-verify AnalogDevices::ADuCM302x_DFP@4.0.0
    cpackget add -a --insecure-skip-verify ARM::CMSIS@6.3.0
fi
