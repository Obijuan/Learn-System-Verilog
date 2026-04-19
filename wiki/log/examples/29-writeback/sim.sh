#!/usr/bin/env bash

#-- Simulacion con iverilog
#iverilog -g2012 -o ledon.out ledon.sv ledon_tb.sv
#vvp ledon.out

#-- Simulacion con verilator
verilator --binary  --trace-fst --trace-structs -sv --top-module TB \
constants.sv synchronizer.sv utils.sv pipeline_status.sv fetch_stage.sv \
forwarding.sv op.sv csr.sv instruction.sv  decode_stage.sv \
instruction_decoder.sv memory_stage.sv \
csr_file writeback_stage.sv \
wishbone_interface.sv top_tb.sv wishbone_leds.sv \
wishbone_buttons.sv wishbone_switches.sv uart_tx uart_rx \
memory.sv wishbone_ram.sv mcu.sv   &&
 ./obj_dir/VTB

echo ""
#-- Otros flags para verilator
#--timing --assert --main --exe 
# --prefix top -Mdir $(BUILD_DIR)/$(SIM_DIR) --top-module top sim/top.sv
