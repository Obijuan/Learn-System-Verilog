/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: decode_stage.sv
 */



module decode_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]  instruction_in, 
    input logic [31:0]  program_counter_in, 
    input forwarding::t exe_forwarding_in, 
    input forwarding::t mem_forwarding_in, 
    input forwarding::t wb_forwarding_in, 

    // Output Registers
    output logic [31:0]   rs1_data_reg_out, 
    output logic [31:0]   rs2_data_reg_out, 
    output logic [31:0]   program_counter_reg_out, 
    output instruction::t instruction_reg_out, 

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

    //-- Reference implementation
    //ref_decode_stage golden(.*);

    import constants::RESET_ADDRESS;

    //---------------------------------------
    //-- DECODE THE INSTRUCTION
    //---------------------------------------//
    //--  | | | |
    //-   v v v v

     //-- Decoded instruction
     instruction::t instruction;

     instruction_decoder u_inst_decoder (
        .instruction_in(instruction_in),
        .instruction_out(instruction)
     );

     //-- Indicate if the current decoded instruction
     //-- is valid or not (it can be garbage generated
     //-- by a BUBBLE or a FETCH_FAIL)
     logic is_instruction_valid;
     assign is_instruction_valid = 
             status_forwards_in == pipeline_status::VALID;

     //-- Forwarding the operands
     logic [31:0] rs1_data_fw;
     logic [31:0] rs2_data_fw;

     //-- Pipeline control signals
     pipeline_status::forwards_t status_fw_wire;

    //-------------------------------------------
    // STAGE REGISTERS
    //-------------------------------------------
    //-- All the stage register are grouped in
    //-- the same process
    //--  | | | |
    //--  v v v v
     always_ff @(posedge clk) begin
 
         //-- Registers initialization
         if (rst) begin
             instruction_reg_out <= instruction::NOP;
             program_counter_reg_out <= RESET_ADDRESS;
             rs1_data_reg_out <= 32'h0000_0000;
             rs2_data_reg_out <= 32'h0000_0000;
             status_forwards_out <= pipeline_status::BUBBLE;
         end
 
         //-- Registers update
         else begin
 
             //-- Update the registers only when the pipeline is
             //-- not stalled
             if (status_backwards_in != pipeline_status::STALL) begin
 
                 //-- Propagate the program counter
                 program_counter_reg_out <= program_counter_in;
 
                 //-- Register the calculated operands
                 rs1_data_reg_out <= rs1_data_fw;
                 rs2_data_reg_out <= rs2_data_fw;
 
                 //---- Register the forward status
                 //-- HIGH PRIORITY FOR THE JUMP
                 if (status_backwards_in == pipeline_status::JUMP)
                     status_forwards_out <= pipeline_status::BUBBLE;
                 else
                     status_forwards_out <= status_fw_wire;
 
                 //-- Captura the decoded instruction ONLY if
                 //-- the instruction coming from the Fetch stage
                 //-- is valid. It case of bubble or fetch_fault
                 //-- the decoded instrucction is NOT passed
                 if (is_instruction_valid)
                   instruction_reg_out <= instruction;
                 else
                   //-- In case of BUBBLE or FETCH_FAIL, the instruction
                   //-- NOP is passed
                   instruction_reg_out <= instruction::NOP;
             end
         end
     end

    //-----------------------------------------------------------
    //---   REGISTER FILE
    //-----------------------------------------------------------
    //--   | | | |
    //--   v v v v
     logic [4:0] write_address;
     logic [31:0] write_data;
     logic write_enable;
     logic [31:0] rs1_data;
     logic [31:0] rs2_data;

     //------------------------------------------------
     //-- Writing to the register file
     //------------------------------------------------
     always_comb begin : u_write

        //-- Only data from the Write-Back Stage
        //-- is written in the file register, if it is valid
        if (wb_forwarding_in.address != 5'b0) begin
            write_address = wb_forwarding_in.address;
            write_data = wb_forwarding_in.data;
            write_enable = wb_forwarding_in.data_valid;
        end
        else begin
            write_address = 5'b0;
            write_data = 32'b0;
            write_enable = 1'b0;
        end
     end

     //-- Instantiate the register file
     register_file u_reg_file (
        .clk(clk),
        .rst(rst),

        // read ports
        .read_address1(instruction.rs1_address),
        .read_data1(rs1_data), 
        .read_address2(instruction.rs2_address),
        .read_data2(rs2_data),

        // write port
        .write_address(write_address),
        .write_data(write_data), 
        .write_enable(write_enable)
     );

    //--------------------------------------------------
    //--- FORWARDING UNIT
    //--------------------------------------------------
    //--   | | | |
    //--   v v v v

     //--- Combinational logic for Forwarding the operands
      assign rs1_data_fw = forward_operand(instruction.rs1_address, rs1_data);
      assign rs2_data_fw = forward_operand(instruction.rs2_address, rs2_data);

     //------------------------------------------------------
     //-- Forward the given operand
     //------------------------------------------------------
     function automatic logic [31:0] forward_operand(

        //-- Operators address
        input logic [4:0] rs,

        //-- Value coming from the register file
        input logic [31:0] rs_data_file
     );

        logic [31:0] data_fw;

        //-- Forward the data from the exe stage: HIGHER PRIORITY
        if ((rs == exe_forwarding_in.address) &&
            (rs != 5'b0) && is_instruction_valid)
 
             //-- Forward the data only if it is valid
             if (exe_forwarding_in.data_valid)
                 data_fw = exe_forwarding_in.data;
             else
                 data_fw = 32'b0;
 
        //-- Forward the data from the mem stage
        else if ((rs == mem_forwarding_in.address) &&
                 (rs != 5'b0) && is_instruction_valid)
 
             //-- Forward the data only if it is valid
             if (mem_forwarding_in.data_valid)
                 data_fw = mem_forwarding_in.data;
             else
                 data_fw = 32'b0;
 
        //-- Forward the data from the wb stage
        else if ((rs == wb_forwarding_in.address) &&
                 (rs != 5'b0) &&
                  is_instruction_valid)
 
             //-- Forward the data only if it is valid
             if (wb_forwarding_in.data_valid)
                 data_fw = wb_forwarding_in.data;
             else
                 data_fw = 32'b0;
        else
             //-- Data coming from the file register
             data_fw = rs_data_file;

         //-- Return the forwared operator
         return data_fw;
     endfunction


    //---------------------------------------------------
    //--   PIPELINE CONTROL
    //---------------------------------------------------

    //------------- COMBINATIONAL LOGIC FOR THE PIPELINE STALL
    //--   | | | |
    //--   v v v v
    
     //------ More glue logic
     //-- Data in exe stage NOT READY YET
     logic exe_not_ready;
     assign exe_not_ready = exe_forwarding_in.data_valid == 1'b0;
 
     //-- Data in mem stage NOT READY YET
     logic mem_not_ready;
     assign mem_not_ready = mem_forwarding_in.data_valid == 1'b0;

     //-- Data in wb stage NOT READY YET
     logic wb_not_ready;
     assign wb_not_ready = wb_forwarding_in.data_valid == 1'b0;
 

     //--------- STALL GENERATION LOGIC

     //-- Check if an Stall should be generated for the
     //-- given operand
     logic stall;
     assign stall = check_stall_rs_R5(instruction.rs1_address) ||
                    check_stall_rs_R5(instruction.rs2_address);

     //-----------------------------------------------------------
     //-- Calculate when to STALL the stage for a given operand
     //-----------------------------------------------------------
     function automatic check_stall_rs_R5(
        input logic [4:0] rs
     );

        //-- Auxiliary wires
        logic stall_rs;
        logic rs_in_exe;
        logic rs_in_mem;
        logic rs_in_wb;

        //-- Get the forwared register address from all the stages
        rs_in_exe = (rs == exe_forwarding_in.address);
        rs_in_mem = (rs == mem_forwarding_in.address);
        rs_in_wb =  (rs == wb_forwarding_in.address);

        //-- Default value: no STALL
        stall_rs = 1'b0;

        //-- It only have sense when the input data from the
        //-- fetch stage is valid...
        if (is_instruction_valid) begin

            //-- When the operan is x0: do not stall
            if (rs != 5'b0) begin
                
                //-- The priority is for the EXE Stage
                //-- The operand is in the exe stage...
                if (rs_in_exe) begin

                    //-- Generate a stall if this operand
                    //-- is not ready yet
                    if (exe_not_ready)
                        stall_rs = 1'b1;
                end

                //-- The operand comes from the mem stage...
                else if (rs_in_mem) begin

                    //-- Generate a stall if not ready...
                    if (mem_not_ready)
                        stall_rs = 1'b1;
                end

                //-- The operand comes from the wb stage...
                else if (rs_in_wb) begin

                    //-- Generate a stall if not ready
                    if (wb_not_ready)
                       stall_rs = 1'b1;
                end
            end
        end
        return stall_rs;
     endfunction;


    //--------- GENERATE STATUS_BACKWARDS
    //--   | | | |
    //--   v v v v
     //-- Combinational logic (no registers in the stage)
     pipeline_status::backwards_t status_bw_wire;
     always_comb begin: u_status_backwards

        //-- Propagate the JUMP
        if (status_backwards_in == pipeline_status::JUMP)
            status_backwards_out = pipeline_status::JUMP;

        //-- Propagate the STALL
        else if (status_backwards_in == pipeline_status::STALL)
            status_backwards_out = pipeline_status::STALL;

        //-- The next stage is READY
        else
            //-- The value is calculated in the status forwards logic
            status_backwards_out = status_bw_wire;
     end


    //---------- GENERATE STATUS_FORWARDS
    //--   | | | |
    //--   v v v v
     //-- Ecall instruction
     logic is_ecall;
     assign is_ecall = (instruction.op == op::ECALL) &&
                        is_instruction_valid;

     //-- Ebreak instruction
     logic is_ebreak;
     assign is_ebreak = (instruction.op == op::EBREAK) &&
                         is_instruction_valid;

     //-- Illegal instruction
     logic is_illegal;
     assign is_illegal = (instruction.op == op::ILLEGAL) &&
                          is_instruction_valid;

     //-- COMBINATIONAL logic for calculating the status_forwards_out signal
     always_comb begin: u_status_forwards

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

        //-- Data from previous stage is VALID, it can be used
        //-- in the decode stage
        else if (status_forwards_in == pipeline_status::VALID) begin
            
            //-- INSTRUCTION ECALL
            if (is_ecall)
                status_fw_wire = pipeline_status::ECALL;

            //-- INSTRUCTION EBREAK
            else if (is_ebreak) 
                status_fw_wire = pipeline_status::EBREAK;

            //-- ILLEGAL INSTRUCTION
            else if (is_illegal)
                status_fw_wire = pipeline_status::ILLEGAL_INSTRUCTION;

            //-- REST OF INSTRUCTIONS
            //-- STALL the pipeline
            else if (stall) begin
                status_bw_wire = pipeline_status::STALL;
                status_fw_wire = pipeline_status::BUBBLE;
            end
        end
     end
    
     //-- Propagate the JUMP_ADDRESS to the previous stage
     assign jump_address_backwards_out = jump_address_backwards_in;

endmodule
