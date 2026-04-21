#!/usr/bin/env bash

#-- Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
RESET='\033[0m'  #-- Color por defecto

#-- Directorio de construccion
BUILD_DIR="_build"

#-- Crear directorio de construccion de apio, si no lo está ya
mkdir -p $BUILD_DIR

#-- Obtener el archivo init.mem
cp _build/init.mem rtl/
cd rtl

#-- Sintesis con Yosys
apio raw -- yosys -m slang \
    -p "read -sv memory.sv" \
    -p "read_slang --ignore-unknown-modules constants.sv \
        synchronizer.sv pipeline_status.sv \
        wishbone_interface.sv wishbone_interconnect.sv \
        wishbone_ram.sv fetch_stage.sv forwarding.sv \
        op.sv csr.sv instruction.sv register_file.sv \
        instruction_decoder.sv decode_stage.sv \
        execute_stage.sv memory_stage.sv \
        csr_file.sv writeback_stage.sv \
        wishbone_leds.sv wishbone_buttons.sv cpu.sv mcu.sv top.sv \
        wishbone_switches.sv uart_tx.sv uart_rx.sv \
        wishbone_uart.sv " \
    -p "synth_ice40 -top top -json ../$BUILD_DIR/hardware.json"  \
    -DSYNTHESIZE -q #> log_yosys.txt

if [ $? -ne 0 ]; then
    echo -e $RED"> Abortando...\n"$RESET
    exit 1
fi

cd ..

#-- Place and Route con nextpnr
apio raw -- nextpnr-ice40 --hx8k --package tq144:4k \
--json $BUILD_DIR/hardware.json \
 --asc $BUILD_DIR/hardware.asc --report $BUILD_DIR/hardware.pnr \
 --pcf rtl/pinout.pcf #-q   #2> log_next.txt

apio raw -- icepack $BUILD_DIR/hardware.asc $BUILD_DIR/hardware.bin

