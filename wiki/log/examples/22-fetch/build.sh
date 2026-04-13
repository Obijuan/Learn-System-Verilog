#!/usr/bin/env bash

#-- Crear directorio de construccion de apio, si no lo está ya
mkdir -p _build/default

#-- Sintesis con Yosys
apio raw -- yosys -m slang \
    -p "read -sv memory.sv" \
    -p "read_slang --ignore-unknown-modules constants.sv \
        pipeline_status.sv wishbone_interface.sv wishbone_interconnect.sv \
        wishbone_ram.sv fetch_stage.sv \
         wishbone_leds.sv wishbone_buttons.sv top.sv \
        synchronizer.sv wishbone_switches.sv uart_tx.sv uart_rx.sv \
        wishbone_uart.sv " \
    -p "synth_ice40 -top top -json _build/default/hardware.json"  \
    -DSYNTHESIZE -q #> log_yosys.txt

#-- Place and Route con nextpnr
apio raw -- nextpnr-ice40 --hx8k --package tq144:4k \
--json _build/default/hardware.json \
 --asc _build/default/hardware.asc --report _build/default/hardware.pnr \
 --pcf pinout.pcf #-q   #2> log_next.txt

apio raw -- icepack _build/default/hardware.asc _build/default/hardware.bin

