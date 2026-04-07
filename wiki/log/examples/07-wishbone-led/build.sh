#!/usr/bin/env bash

#-- Crear directorio de construccion de apio, si no lo está ya
mkdir -p _build/default

#-- Sintesis con Yosys
apio raw -- yosys -m slang -p "read_slang wishbone_interface.sv \
wishbone_leds.sv top.sv \
; synth_ice40 -top top -json _build/default/hardware.json" -q -DSYNTHESIZE

#-- Place and Route con nextpnr
apio raw -- nextpnr-ice40 --hx8k --package tq144:4k \
--json _build/default/hardware.json \
 --asc _build/default/hardware.asc --report _build/default/hardware.pnr \
 --pcf pinout.pcf -q

apio raw -- icepack _build/default/hardware.asc _build/default/hardware.bin

