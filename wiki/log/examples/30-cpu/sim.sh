#!/usr/bin/env bash


#-- Simulacion con verilator
verilator --binary  --trace-fst --trace-structs -sv --top-module top_tb \
-Wall -Wno-fatal -y rtl -Mdir obj_dir \
constants.sv synchronizer.sv pipeline_status.sv fetch_stage.sv \
forwarding.sv op.sv csr.sv instruction.sv  decode_stage.sv \
instruction_decoder.sv memory_stage.sv \
csr_file writeback_stage.sv \
wishbone_interface.sv top_tb.sv wishbone_leds.sv \
wishbone_buttons.sv wishbone_switches.sv uart_tx uart_rx \
memory.sv wishbone_ram.sv mcu.sv   &&
cd _build && ../obj_dir/Vtop_tb

echo ""

