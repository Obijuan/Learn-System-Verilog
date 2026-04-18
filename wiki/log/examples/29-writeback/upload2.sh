#!/usr/bin/env bash

apio raw -- openFPGALoader --verify -b ice40_generic --cable ft2232 \
    _build/default/hardware2.bin


