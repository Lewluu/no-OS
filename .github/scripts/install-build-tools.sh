#!/bin/bash

echo "Installing tools for ${PLATFORM} platform..."

if [[ "$PLATFORM" == "pico" ]]; then
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
elif [[ "$PLATFORM" == "maxim" ]]; then
    sudo apt update && sudo apt install -y \
        libxcb-glx0 libxcb-icccm4 libxcb-image0 libxcb-shm0 libxcb-util1 libxcb-keysyms1 \
        libxcb-randr0 libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-sync1 \
        libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxcb1 libxkbcommon-x11-0 libxkbcommon0 \
        libgl1 libusb-0.1-4 libhidapi-libusb0 libhidapi-hidraw0

    # Installing libncurses
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.2_amd64.deb
    sudo apt-get install -y ./libtinfo5_6.3-2ubuntu0.2_amd64.deb
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2ubuntu0.2_amd64.deb
    sudo apt-get install -y ./libncurses5_6.3-2ubuntu0.2_amd64.deb
    
    # Installing ninja
    wget https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-linux.zip
    unzip ninja-linux.zip
    sudo mv ninja /usr/local/bin/
    export "CMAKE_GENERATOR=Ninja" >> $GITHUB_ENV

    # Installing MaximSDK
    cloudsmith download ${TOOLS_REPO} MaximMicrosSDK_linux.run --version 1.0.1
    sudo chmod +x MaximMicrosSDK_linux.run
    sudo ./MaximMicrosSDK_linux.run in --root ~/MaximSDK --accept-licenses --accept-messages --confirm-command
    echo "MAXIM_LIBRARIES=/home/runner/MaximSDK/Libraries" >> $GITHUB_ENV
elif [[ "$PLATFORM" == "xilinx" ]]; then
    echo "VIVADO_VERSION=2023.2" >> $GITHUB_ENV
    echo "VIVADO_TOOLCHAIN_PATH=$VITIS_PATH/gnu/aarch32/lin/gcc-arm-linux-gnueabi" >> $GITHUB_ENV
    echo "VIVADO_SETTINGS=$VIVADO_PATH/settings64.sh" >> $GITHUB_ENV
    echo "CROSS_COMPILE=$VITIS_PATH/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin/arm-linux-gnueabihf-" >> $GITHUB_ENV
    echo "XILINX_VIVADO=$VIVADO_PATH" >> $GITHUB_ENV
    echo "XILINX_HLS=/opt/Xilinx/Vitis_HLS/2023.2" >> $GITHUB_ENV
    echo "XILINX_VITIS=$VITIS_PATH" >> $GITHUB_ENV
    echo "PATH=/opt/Xilinx/Vitis_HLS/2023.2/bin:/opt/Xilinx/Model_Composer/2023.2/bin:$VITIS_PATH/bin:$VITIS_PATH/gnu/microblaze/lin/bin:$VITIS_PATH/gnu/microblaze/linux_toolchain/lin64_le/bin:$VITIS_PATH/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin:$VITIS_PATH/gnu/aarch32/lin/gcc-arm-none-eabi/bin:$VITIS_PATH/gnu/aarch64/lin/aarch64-linux/bin:$VITIS_PATH/gnu/aarch64/lin/aarch64-none/bin:$VITIS_PATH/gnu/armr5/lin/gcc-arm-none-eabi/bin:$VITIS_PATH/tps/lnx64/cmake-3.3.2/bin:$VITIS_PATH/aietools/bin:$VITIS_PATH/gnu/riscv/lin/riscv64-unknown-elf/bin:$VIVADO_PATH/bin:/opt/Xilinx/DocNav:$PATH" >> $GITHUB_ENV
    
    mkdir -p ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA}
    sudo apt-get install python3
    python3 -m pip install cloudsmith-cli
    cloudsmith download ${TOOLS_REPO} new_hardware.tar.gz --tag latest --outfile ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA}/new_hardware.tar.gz
    tar -xzvf ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA}/new_hardware.tar.gz -C ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA} --strip-components 2
    
    cloudsmith download ${TOOLS_REPO} hardware.tar.gz --tag latest --outfile ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA}/hardware.tar.gz
    tar -xzvf ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA}/hardware.tar.gz -C ${BUILDS_DIR}_${HDL_BRANCH}/${GITHUB_SHA} --strip-components 2
    
elif [[ "$PLATFORM" == "aducm3029" ]]; then
    # Install i386 architecture dependencies 
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install -y libc6:i386
    sudo apt install -y libstdc++6:i386

    # Installing libncursesw
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2ubuntu0.2_amd64.deb
    sudo apt-get install -y ./libtinfo5_6.3-2ubuntu0.2_amd64.deb
    wget http://security.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncursesw5_6.3-2ubuntu0.2_amd64.deb
    sudo apt-get install -y ./libncursesw5_6.3-2ubuntu0.2_amd64.deb

    # Installing crosscore embedded studio
    echo "Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://gb.archive.ubuntu.com/ubuntu
Suites: jammy
Components: main
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" > ubuntu.sources
    sudo mv ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources
    cat /etc/apt/sources.list.d/ubuntu.sources
    sudo apt update
    sudo apt-get install -y libwebkitgtk-6.0-4 libwebkit2gtk-4.1-0 libwebkit2gtk-4.0-37
    cloudsmith download ${TOOLS_REPO} adi-cces-linux-amd64.deb --version 2.12.1
    sudo apt-get install -y -f ./adi-cces-linux-amd64.deb
    
    # Installing cpackget
    wget https://github.com/Open-CMSIS-Pack/cpackget/releases/download/v2.2.1/cpackget_2.2.1_linux_amd64.tar.gz
    tar -xvf cpackget_2.2.1_linux_amd64.tar.gz
    sudo mv cpackget_2.2.1_linux_amd64/cpackget /usr/local/bin/ 

    # Installing ADuCM302x Device Family Pack
    cpackget add -a --insecure-skip-verify AnalogDevices::ADuCM302x_DFP@4.0.0

    # Installing ARM.CMSIS pack
    cpackget add -a --insecure-skip-verify ARM::CMSIS@6.3.0

    echo "CCES_HOME=/opt/analog/cces/3.0.4" >> $GITHUB_ENV
fi
