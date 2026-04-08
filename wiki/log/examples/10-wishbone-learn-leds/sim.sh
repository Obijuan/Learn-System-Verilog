#!/usr/bin/env bash

#-- Simulacion con iverilog
#iverilog -g2012 -o ledon.out ledon.sv ledon_tb.sv
#vvp ledon.out

#-- Simulacion con verilator
verilator --binary  --trace-fst -sv --top-module TB \
wishbone_interface.sv wishbone_leds_tb.sv wishbone_leds.sv && \
 ./obj_dir/VTB
