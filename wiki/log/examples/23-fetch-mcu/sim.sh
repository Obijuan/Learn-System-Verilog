#!/usr/bin/env bash

#-- Simulacion con iverilog
#iverilog -g2012 -o ledon.out ledon.sv ledon_tb.sv
#vvp ledon.out

#-- Simulacion con verilator
verilator --binary  --trace-fst -sv --top-module TB \
constants.sv pipeline_status.sv fetch_stage.sv \
wishbone_interface.sv top_tb.sv wishbone_leds.sv \
wishbone_buttons.sv wishbone_switches.sv uart_tx uart_rx \
memory.sv wishbone_ram.sv mcu.sv   &&
 ./obj_dir/VTB
