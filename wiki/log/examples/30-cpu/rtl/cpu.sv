/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: cpu.sv
 */


module cpu (
    input logic clk,
    input logic rst,

    wishbone_interface.master memory_fetch_port,
    wishbone_interface.master memory_mem_port,

    input logic external_interrupt_in,
    input logic timer_interrupt_in
);

    //------- Signals from the Fetch stage
    logic [31:0] fetch_instruction_reg;
    logic [31:0] fetch_program_counter_reg;
    pipeline_status::forwards_t fetch_status_forwards;

    //------- Signals from the Decode stage
    pipeline_status::backwards_t decode_status_backwards;
    logic [31:0] decode_jump_address_backwards;
    logic [31:0] rs1_data_reg;
    logic [31:0] rs2_data_reg;
    instruction::t decode_instruction_reg;
    logic [31:0] decode_program_counter_reg;
    pipeline_status::forwards_t decode_status_forwards;

    //------- Signals from the Execute stage
    forwarding::t exe_forwarding;
    pipeline_status::backwards_t exe_status_backwards;
    logic [31:0] exe_jump_address_backwards;
    instruction::t exe_instruction_reg;
    logic [31:0] exe_program_counter_reg;
    logic [31:0] exe_next_program_counter_reg;
    logic [31:0] exe_rd_data_reg;
    logic [31:0] exe_source_data_reg;
    pipeline_status::forwards_t exe_status_forwards;
    pipeline_status::backwards_t mem_status_backwards;
    logic [31:0] memory_jump_address_backwards;

    //------- Signals from the Memory stage
    forwarding::t mem_forwarding;
    instruction::t mem_instruction_reg;
    logic [31:0] mem_program_counter_reg;
    logic [31:0] mem_next_program_counter_reg;
    logic [31:0] mem_source_data_reg;
    logic [31:0] mem_rd_data_reg;
    pipeline_status::forwards_t mem_status_forwards;

    //------- Signals from the Writeback stage
    logic [31:0] wb_jump_address_backwards;
    forwarding::t wb_forwarding;
    pipeline_status::backwards_t wb_status_backwards;

    //------------------------------------
    //-- Instantiate FETCH STAGE
    //------------------------------------
    fetch_stage u_fetch (
        .clk(clk), 
        .rst(rst),

        //-- Memory interface
        .wb(memory_fetch_port),

        //-- Output data
        .instruction_reg_out(fetch_instruction_reg),
        .program_counter_reg_out(fetch_program_counter_reg),

        //-- Pipeline control
        .status_forwards_out(fetch_status_forwards),
        .status_backwards_in(decode_status_backwards),
        .jump_address_backwards_in(decode_jump_address_backwards)
    );

    //---------------------------------------
    //-- Instantiate DECODE STAGE
    //---------------------------------------
    decode_stage u_decode(
        .clk(clk),
        .rst(rst),

        // Inputs
        .instruction_in(fetch_instruction_reg),
        .program_counter_in(fetch_program_counter_reg),

        .wb_forwarding_in(wb_forwarding),
        .mem_forwarding_in(mem_forwarding),
        .exe_forwarding_in(exe_forwarding),
        
        // Output Registers
        .instruction_reg_out(decode_instruction_reg),
        .program_counter_reg_out(decode_program_counter_reg),
        .rs1_data_reg_out(rs1_data_reg),
        .rs2_data_reg_out(rs2_data_reg),

        // Pipeline control
        .status_forwards_in(fetch_status_forwards), 
        .status_forwards_out(decode_status_forwards), 
        .status_backwards_in(exe_status_backwards), 
        .status_backwards_out(decode_status_backwards),
        .jump_address_backwards_in(exe_jump_address_backwards),
        .jump_address_backwards_out(decode_jump_address_backwards)
    );

    //-----------------------------------------------
    //-- Instantiate EXECUTE STAGE
    //-----------------------------------------------
    execute_stage u_execute (
        .clk(clk),
        .rst(rst),

        // Inputs
        .rs1_data_in(rs1_data_reg),
        .rs2_data_in(rs2_data_reg),
        .instruction_in(decode_instruction_reg),
        .program_counter_in(decode_program_counter_reg),

        // Outputs
        .forwarding_out(exe_forwarding),
        .instruction_reg_out(exe_instruction_reg),
        .program_counter_reg_out(exe_program_counter_reg),
        .next_program_counter_reg_out(exe_next_program_counter_reg),
        .rd_data_reg_out(exe_rd_data_reg),
        .source_data_reg_out(exe_source_data_reg),
        
        // Pipeline control
        .status_forwards_in(decode_status_forwards),
        .status_forwards_out(exe_status_forwards),
        .status_backwards_in(mem_status_backwards),
        .status_backwards_out(exe_status_backwards),
        .jump_address_backwards_in(memory_jump_address_backwards),
        .jump_address_backwards_out(exe_jump_address_backwards)
    );

    //--------------------------------------------------------
    //-- Instantiate MEMORY STAGE
    //--------------------------------------------------------
    memory_stage u_memory (
        .clk(clk),
        .rst(rst),

        // Memory interface
        .wb(memory_mem_port),

        // Inputs
        .source_data_in(exe_source_data_reg),
        .program_counter_in(exe_program_counter_reg),
        .next_program_counter_in(exe_next_program_counter_reg),
        .rd_data_in(exe_rd_data_reg),
        .instruction_in(exe_instruction_reg),
        
        // Outputs
        .forwarding_out(mem_forwarding),
        .instruction_reg_out(mem_instruction_reg),
        .program_counter_reg_out(mem_program_counter_reg),
        .next_program_counter_reg_out(mem_next_program_counter_reg),
        .source_data_reg_out(mem_source_data_reg),
        .rd_data_reg_out(mem_rd_data_reg),
        
        // Pipeline control
        .status_forwards_in(exe_status_forwards),
        .status_forwards_out(mem_status_forwards),
        .status_backwards_in(wb_status_backwards),
        .status_backwards_out(mem_status_backwards),
        .jump_address_backwards_in(wb_jump_address_backwards),
        .jump_address_backwards_out(memory_jump_address_backwards)
    );

    //----------------------------------------------------------------
    //-- Instantiate WRITEBACK STAGE
    //----------------------------------------------------------------
    writeback_stage u_writeback(
        .clk(clk),
        .rst(rst),

        // Inputs
        .source_data_in(mem_source_data_reg),
        .rd_data_in(mem_rd_data_reg),
        .instruction_in(mem_instruction_reg),
        .program_counter_in(mem_program_counter_reg),
        .next_program_counter_in(mem_next_program_counter_reg),

        // Interrupt signals
        .external_interrupt_in(external_interrupt_in),
        .timer_interrupt_in(timer_interrupt_in),

        // Outputs
        .forwarding_out(wb_forwarding),

        // Pipeline control
        .status_forwards_in(mem_status_forwards),
        .status_backwards_out(wb_status_backwards),
        .jump_address_backwards_out(wb_jump_address_backwards)
    );

endmodule
