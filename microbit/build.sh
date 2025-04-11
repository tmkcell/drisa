#!/bin/bash

ver=14.2.rel1

cd ../build
mkdir microbit && cd microbit
wget https://developer.arm.com/-/media/Files/downloads/gnu/$ver/binrel/arm-gnu-toolchain-$ver-x86_64-arm-none-eabi.tar.xz
tar xpf arm-gnu-toolchain*
export PATH="$(pwd)/arm-gnu-toolchain-$ver-x86_64-arm-none-eabi:$PATH"
git clone --depth 1 https://github.com/lancaster-university/microbit-v2-samples.git
cp ../../microbit/emu.cpp "microbit-v2-samples/source/main.cpp"
cd microbit-v2-samples
python3 build.py
cp MICROBIT.hex ../drisa-emu-microbit.hex
