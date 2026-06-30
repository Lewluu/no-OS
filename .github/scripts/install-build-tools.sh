#!/bin/bash

if [[ "$PLATFORM" == "pico" ]]; then
    echo "Installing tools for pico platform ..."

    # Installing pico tool
    sudo apt install cmake build-essential pkg-config libusb-1.0-0-dev python3 python3-pip git mercurial gcc-arm-none-eabi
    sudo python3 -m pip install mbed-cli pyelftools==0.29
    mbed config -G GCC_ARM_PATH "/usr/bin/arm-none-eabi-gcc"
    echo "GCC_ARM=/usr/bin/arm-none-eabi-gcc" >> $GITHUB_ENV
    pip install -r ${WORKSPACE}/libraries/mbed/mbed-os/requirements.txt
    git clone --branch 2.2.0 https://github.com/raspberrypi/picotool.git
    cd picotool
    mkdir build && cd build
    PICO_SDK_PATH=${WORKSPACE}/libraries/pico-sdk cmake ..
    make -j${NUM_JOBS}
    sudo make install

    # Install jlink server
    cloudsmith download ${TOOLS_REPO} JLink_Linux_V956_x86_64.deb --version V9.56
    sudo apt-get install ./JLink_Linux_V956_x86_64.deb

    echo "PICO_SDK_PATH=${WORKSPACE}/libraries/pico-sdk" >> $GITHUB_ENV
    echo "JLINK_SERVER_PATH=/opt/SEGGER/JLink/JLinkGDBServerCLExe" >> $GITHUB_ENV

elif [[ "$PLATFORM" == "mbed" ]]; then
    echo "Installing tools for mbed platform ..."
    sudo apt install python3 python3-pip git mercurial gcc-arm-none-eabi
    sudo python3 -m pip install mbed-cli pyelftools==0.29
    mbed config -G GCC_ARM_PATH "/usr/bin/arm-none-eabi-gcc"
    echo "GCC_ARM=/usr/bin/arm-none-eabi-gcc" >> $GITHUB_ENV
    pip install -r ${WORKSPACE}/libraries/mbed/mbed-os/requirements.txt
fi
