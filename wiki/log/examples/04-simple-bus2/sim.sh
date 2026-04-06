#!/usr/bin/env bash

#-- Simulacion con iverilog
#iverilog -g2012 -o ledon.out ledon.sv ledon_tb.sv
#vvp ledon.out

#-- Simulacion con verilator
verilator --binary  --trace-fst -sv --top-module TB interface.sv \
simple_bus_tb.sv simple_bus.sv && ./obj_dir/VTB
