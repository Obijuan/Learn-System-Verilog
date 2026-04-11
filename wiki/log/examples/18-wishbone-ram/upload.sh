#!/usr/bin/env bash

apio raw -- openFPGALoader --verify -b ice40_generic \
--vid 0403 --pid 6010 --busdev-num 1:16 _build/default/hardware.bin

