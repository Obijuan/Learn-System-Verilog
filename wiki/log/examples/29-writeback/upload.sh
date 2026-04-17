#!/usr/bin/env bash

apio raw -- openFPGALoader --verify -b ice40_generic --cable ft2232 \
    _build/default/hardware.bin

#apio raw -- openFPGALoader --verify -b ice40_generic \
#--vid 0403 --pid 6010 --busdev-num:1:8 _build/default/hardware.bin
