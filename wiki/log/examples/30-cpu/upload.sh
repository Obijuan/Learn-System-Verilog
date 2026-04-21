#!/usr/bin/env bash

BUILD_DIR="_build"

apio raw -- openFPGALoader --verify -b ice40_generic --cable ft2232 \
    $BUILD_DIR/hardware.bin


