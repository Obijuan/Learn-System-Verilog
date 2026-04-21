/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: memory_stage.sv
 */

module memory_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    // Inputs
    input logic [31:0]   source_data_in,
    input logic [31:0]   rd_data_in,
    input instruction::t instruction_in,
    input logic [31:0]   program_counter_in,
    input logic [31:0]   next_program_counter_in,

    // Outputs
    output logic [31:0]   source_data_reg_out,
    output logic [31:0]   rd_data_reg_out,
    output instruction::t instruction_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output logic [31:0]   next_program_counter_reg_out,
    output forwarding::t  forwarding_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    import constants::RESET_ADDRESS;

    //-- The current instruction is valid
    logic is_instruction_valid;
    assign is_instruction_valid = 
             status_forwards_in == pipeline_status::VALID;

    //------------------------------
    //-- SIGNALS
    //------------------------------
    logic ctrl_is_load;
    logic ctrl_data_valid;
    logic ctrl_is_byte;
    logic ctrl_is_half;
    logic ctrl_is_word;
    logic ctrl_unsigned;
    logic [31:0] rd_data;
    logic [31:0] source_data;
    

    //-- Pipeline controls
    pipeline_status::forwards_t status_fw_wire;

    //-------------------------------------------
    // STAGE REGISTERS
    //-------------------------------------------
    //--  | | | |
    //--  v v v v
     always_ff @(posedge clk) begin : u_stage_reg

        if (rst) begin
            instruction_reg_out <= instruction::NOP;
            program_counter_reg_out <= RESET_ADDRESS;
            rd_data_reg_out <= 32'h0;
            source_data_reg_out <= 32'h0;
            next_program_counter_reg_out <= RESET_ADDRESS;
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else begin

            //-- Update the registers only when the pipeline is
            //-- not stalled
            if (status_backwards_in != pipeline_status::STALL) begin

                //-- Propagate the instruction
                instruction_reg_out <= instruction_in;

                //-- Propagate the PC
                program_counter_reg_out <= program_counter_in;

                //-- Destination register data
                //-- If it is a load instruction, the data comes from
                //-- the memory
                if (ctrl_is_load)
                    rd_data_reg_out <= rd_data;
                else 
                    //-- Data coming form the exe stage
                    rd_data_reg_out <= rd_data_in;

                //-- Register the source_data
                source_data_reg_out <= source_data_in;

                //-- Register the next program counter
                next_program_counter_reg_out <= next_program_counter_in;

                //---- Register the forward status
                //-- HIGH PRIORITY FOR THE JUMP
                if (status_backwards_in == pipeline_status::JUMP)
                    status_forwards_out <= pipeline_status::BUBBLE;
                else
                    status_forwards_out <= status_fw_wire;

                if (is_instruction_valid)
                   instruction_reg_out <= instruction_in;
                 else
                   //-- In case of BUBBLE or FETCH_FAIL, the instruction
                   //-- NOP is passed
                   instruction_reg_out <= instruction::NOP;
            end
        end
     end

    //-----------------------------------
    //-- Multiplexer for the forwarding
    //-----------------------------------
    //--  | | | |
    //--  v v v v
     always_comb begin : u_mem_fw
        
        //-------- Default values

        //-- Destination register
        forwarding_out.data = rd_data;

        //-- rd is not available
        forwarding_out.data_valid = 0;

        //-- Forward disabled
        forwarding_out.address = 5'b0;

        //-- Data is forwared if the input is valid
        if (status_forwards_in == pipeline_status::VALID) begin
            forwarding_out.data_valid = ctrl_data_valid;
            forwarding_out.address = instruction_in.rd_address;
        end
     end

    //-----------------------------------------------
    //-- Interface with the memory
    //-----------------------------------------------
    //-- Connect the address
    //-- Translate it to word address
    assign wb.adr = {2'b00, rd_data_in[31:2]};

    //-- Connect the data (for writing)
    assign wb.dat_mosi = source_data;

    //------------------------------------
    //-- Write data multiplexor
    //------------------------------------
    always_comb begin : u_write_mux

        if (ctrl_is_byte) begin
            source_data = source_data_in << {rd_data_in[1:0],3'b000};
        end
        else if (ctrl_is_half) begin
            source_data = source_data_in << {rd_data_in[1], 4'b0000};
        end
        else if (ctrl_is_word) begin
            source_data = source_data_in;
        end
        else begin
            source_data = 32'h0;
        end
        
    end

    //-------------------------------------
    //-- Read data multiplexor
    //-- Gets a byte, half word or a word
    //-------------------------------------
    logic [7:0] data_byte;
    logic [15:0] data_half;

    always_comb begin : u_rd_data_mux

        //-- Default values
        data_byte = 8'h0;
        data_half = 16'h0;

        if (ctrl_is_byte) begin

            //-- Select the byte according to its address
            case(rd_data_in[1:0])
                2'b00: data_byte = wb.dat_miso[7:0];
                2'b01: data_byte = wb.dat_miso[15:8];
                2'b10: data_byte = wb.dat_miso[23:16];
                2'b11: data_byte = wb.dat_miso[31:24];
                default: data_byte = 8'h0;
            endcase

            //-- Extend the sign
            if (ctrl_unsigned)
                rd_data = 32'(unsigned'(data_byte));
            else
                rd_data = 32'(signed'(data_byte));
        end

        else if (ctrl_is_half) begin

            //-- Select the half word according to its address
            case(rd_data_in[1:0])
                2'b00: data_half = wb.dat_miso[15:0];
                2'b10: data_half = wb.dat_miso[31:16];
                default:
                    data_half = 16'h0;
            endcase

            //-- Extend the sign
            if (ctrl_unsigned)
                rd_data = 32'(unsigned'(data_half));
            else
                rd_data = 32'(signed'(data_half));
        end 
        else if (ctrl_is_word) begin
            rd_data = wb.dat_miso;
        end

        else begin
            //-- Default value for the destination register
            //-- If load instruction, it should be update
            rd_data = rd_data_in;
        end
    end
    
    //------------------------------------
    //-- Mem control unit
    //------------------------------------
    logic ctrl_is_store;
    logic ctrl_is_misaligned;

    //-- Check for misaligned address
    always_comb begin

        //-- Default value
        ctrl_is_misaligned = 0;

        if ((ctrl_is_word && rd_data_in[1:0] != 2'b00) ||
            (ctrl_is_half && rd_data_in[0])) begin
                ctrl_is_misaligned = 1;
        end
    end

    //-- Generate the control signals
    always_comb begin : u_mem_ctrl
        
        //-- Default values
        wb.cyc = 0;
        wb.stb = 0;
        wb.sel = 4'b0;
        wb.we = 0;
        ctrl_data_valid = 1;
        ctrl_is_load = 0;
        ctrl_is_byte = 0;
        ctrl_is_half = 0;
        ctrl_is_word = 0;
        ctrl_is_store = 0;

        //-- Signed numbers by default;
        ctrl_unsigned = 0;

        //-- Generate ctrl signals only if the input is valid
        if (is_instruction_valid) begin
            case(instruction_in.op)

                op::LW: begin
                    ctrl_is_load = 1;
                    ctrl_is_word = 1;
                    wb.cyc = 1;
                    wb.stb = 1;
                    wb.sel = 4'b1111; 
                    //-- When reading from memory, the data
                    //-- is not available
                    if (wb.ack == 0)
                        ctrl_data_valid = 0;
                end

                op::LB: begin
                    ctrl_is_load = 1;
                    ctrl_is_byte = 1;
                    wb.cyc = 1;
                    wb.stb = 1;
                    wb.sel = 1 << rd_data_in[1:0]; 
                    //-- When reading from memory, the data
                    //-- is not available
                    if (wb.ack == 0)
                        ctrl_data_valid = 0;
                end

                op::LBU: begin
                    ctrl_is_load = 1;
                    ctrl_is_byte = 1;
                    wb.cyc = 1;
                    wb.stb = 1;
                    wb.sel = 1 << rd_data_in[1:0]; 

                    //-- Unsigned byte
                    ctrl_unsigned = 1;

                    //-- When reading from memory, the data
                    //-- is not available
                    if (wb.ack == 0)
                        ctrl_data_valid = 0;
                end

                op::LH: begin
                    ctrl_is_load = 1;
                    ctrl_is_half = 1;

                    wb.cyc = 1;
                    wb.stb = 1;
                    wb.sel = 3 << {rd_data_in[1], 1'b0};

                    //-- When reading from memory, the data
                    //-- is not available
                    if (wb.ack == 0)
                        ctrl_data_valid = 0; 
                end

                op::LHU: begin
                    ctrl_is_load = 1;
                    ctrl_is_half = 1;

                    wb.cyc = 1;
                    wb.stb = 1;
                    wb.sel = 3 << {rd_data_in[1], 1'b0};

                    //-- Unsigned half word
                    ctrl_unsigned = 1;

                    //-- When reading from memory, the data
                    //-- is not available
                    if (wb.ack == 0)
                        ctrl_data_valid = 0; 
                end

                op::SW: begin
                    //-- In case of JUMP, do NOT execute SW
                    if (status_backwards_in != pipeline_status::JUMP) begin
                        wb.cyc = 1;
                        wb.stb = 1;
                        wb.sel = 4'b1111;
                        wb.we = 1;
                        ctrl_is_word = 1;
                        ctrl_is_store = 1;
                    end
                end

                op::SB: begin
                    //-- In case of JUMP, do NOT execute SW
                    if (status_backwards_in != pipeline_status::JUMP) begin
                        wb.cyc = 1;
                        wb.stb = 1;
                        wb.sel = 1 << rd_data_in[1:0];
                        wb.we = 1;
                        ctrl_is_byte = 1;
                        ctrl_is_store = 1;
                    end
                end

                op::SH: begin
                    //-- In case of JUMP, do NOT execute SW
                    if (status_backwards_in != pipeline_status::JUMP) begin
                        wb.cyc = 1;
                        wb.stb = 1;
                        wb.sel = 3 << {rd_data_in[1], 1'b0};
                        wb.we = 1;
                        ctrl_is_half = 1;
                        ctrl_is_store = 1;
                    end
                end

                op::CSRRW,   
                op::CSRRS,  
                op::CSRRC, 
                op::CSRRWI,        
                op::CSRRSI,       
                op::CSRRCI: begin  
                    ctrl_data_valid = 0;
                end

                default: begin
                    //-- Use default values
                end
            endcase
        end
    end


    //--------- GENERATE STATUS_BACKWARDS
    //--   | | | |
    //--   v v v v
    //-- Combinational logic (no registers in the stage)
    pipeline_status::backwards_t status_bw_wire;

    always_comb begin : u_status_backwards

        //-- The JUMP from the next stage has the higher priority
        if (status_backwards_in == pipeline_status::JUMP)
            status_backwards_out = pipeline_status::JUMP;

        //-- Propagate the STALL
        else if (status_backwards_in == pipeline_status::STALL)
            status_backwards_out = pipeline_status::STALL;

        else begin
            status_backwards_out = status_bw_wire;
        end
    end

    //---------- GENERATE STATUS_FORWARDS
    //--   | | | |
    //--   v v v v

    always_comb begin: u_mem_status_forwards

        //--Default values
        status_bw_wire = pipeline_status::READY;
        status_fw_wire = pipeline_status::VALID;

        //----------- Logic for the status_forward_out
        //-- Propagate the FETCH FAULT
        if (status_forwards_in == pipeline_status::FETCH_FAULT) 
            status_fw_wire = pipeline_status::FETCH_FAULT;

        //-- Propagate the BUBBLE
        else if (status_forwards_in == pipeline_status::BUBBLE)
            status_fw_wire = pipeline_status::BUBBLE;

        //-- Propagate ECALL
        else if (status_forwards_in == pipeline_status::ECALL)
            status_fw_wire = pipeline_status::ECALL; 

        //-- Propagate EBREAK
        else if (status_forwards_in == pipeline_status::EBREAK)
            status_fw_wire = pipeline_status::EBREAK; 

        //-- Propagate ILLEGAL INSTRUCTION
        else if (status_forwards_in == pipeline_status::ILLEGAL_INSTRUCTION)
            status_fw_wire = pipeline_status::ILLEGAL_INSTRUCTION;

        //-- Propagate FETCH_MISALIGNED
        else if (status_forwards_in == pipeline_status::FETCH_MISALIGNED)
            status_fw_wire = pipeline_status::FETCH_MISALIGNED; 

        //-- Data from previous stage is VALID, it can be used
        //-- in the mem stage
        else if (status_forwards_in == pipeline_status::VALID) begin


            //-- Check STORE_MISALIGNED
            if (ctrl_is_store && ctrl_is_misaligned) begin
                status_fw_wire = pipeline_status::STORE_MISALIGNED;
            end
            //-- Check STORE FAULT
            else if (ctrl_is_store && wb.err) begin
                status_fw_wire = pipeline_status::STORE_FAULT;
            end

            //-- Check LOAD_MISALIGNED
            else if (ctrl_is_load && ctrl_is_misaligned) begin
                status_fw_wire = pipeline_status::LOAD_MISALIGNED;
            end

            //-- Check LOAD FAULT
            else if (ctrl_is_load && wb.err) begin
                status_fw_wire = pipeline_status::LOAD_FAULT;
            end

            //-- Stall if the data from memory is not ready
            else if (wb.stb && wb.cyc && (wb.ack==0)) begin
                status_bw_wire = pipeline_status::STALL;
                status_fw_wire = pipeline_status::BUBBLE;
            end
        end
    end

    //-- Propagate the JUMP_ADDRESS to the previous stage
     assign jump_address_backwards_out = jump_address_backwards_in;

endmodule
