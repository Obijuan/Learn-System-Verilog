/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: execute_stage.sv
 */


module execute_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]   rs1_data_in,
    input logic [31:0]   rs2_data_in,
    input instruction::t instruction_in,
    input logic [31:0]   program_counter_in,

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

    //-----------
    //-- SIGNALS
    //-----------
    logic [31:0] rd_data;
    logic [31:0] source_data;
    logic [31:0] next_program_counter;

    //-------- Control signals
    logic ctrl_data_valid;
    logic ctrl_is_misaligned;

    //-- Pipeline control
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
            status_forwards_out <= pipeline_status::BUBBLE;
            next_program_counter_reg_out <= RESET_ADDRESS;
        end
        else begin

            //-- Update the registers only when the pipeline is
            //-- not stalled
            if (status_backwards_in != pipeline_status::STALL) begin

                //-- Propagate the instruction
                instruction_reg_out <= instruction_in;

                //-- Propagate the PC
                program_counter_reg_out <= program_counter_in;

                //-- Register the rd_data
                rd_data_reg_out <= rd_data;

                //-- Register the source_data
                source_data_reg_out <= source_data;

                //-- Register the next program counter
                next_program_counter_reg_out <= next_program_counter;

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
     always_comb begin : u_fw_exe
        
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
 
    //---------------------------------------------
    //-- Perform calculations
    //---------------------------------------------
    
    //-- Operation rs1 <u rs2 
    logic rs1_unsigned_less_than_rs2;
    assign rs1_unsigned_less_than_rs2 = 
        unsigned'(rs1_data_in) < unsigned'(rs2_data_in);

    //-- Operation: rs1 <s rs2
    logic rs1_less_than_rs2;
    assign rs1_less_than_rs2 = signed'(rs1_data_in) < signed'(rs2_data_in);

    //-- Operation: rs1 >=u rs2
    logic rs1_unsigned_greather_eq_than_rs2;
    assign rs1_unsigned_greather_eq_than_rs2 =
        unsigned'(rs1_data_in) >= unsigned'(rs2_data_in);

    //-- Operation: rs1 >=s rs2
    logic rs1_greather_eq_than_rs2;
    assign rs1_greather_eq_than_rs2 = signed'(rs1_data_in) >= signed'(rs2_data_in);

    //-- Operation rs1 == rs2
    logic equal;
    assign equal = (rs1_data_in == rs2_data_in);

    //-- Operation: rs1 + rs2
    logic [31:0] rs1_plus_rs2;
    assign rs1_plus_rs2 = rs1_data_in + rs2_data_in;

    //-- Operation: rs1 - rs2
    logic [31:0] rs1_minus_rs2;
    assign rs1_minus_rs2 = rs1_data_in - rs2_data_in;
    
    //-- Operation: rs1 << rs2
    logic [31:0] rs1_shift_left_rs2;
    assign rs1_shift_left_rs2 = rs1_data_in << rs2_data_in[4:0];

    //-- Operation: rs1 >> rs2
    logic [31:0] rs1_shift_right_rs2;
    assign rs1_shift_right_rs2 = rs1_data_in >> rs2_data_in[4:0];

    //-- Operation: rs1 >>s rs2
    logic [31:0] rs1_shift_right_arith_rs2;
    assign rs1_shift_right_arith_rs2 = 
        signed'(rs1_data_in) >>> rs2_data_in[4:0];

    //-- Operation: rs1 ^ rs2
    logic [31:0] rs1_xor_rs2;
    assign rs1_xor_rs2 = rs1_data_in ^ rs2_data_in;

    //-- Operation: rs1 | rs2
    logic [31:0] rs1_or_rs2;
    assign rs1_or_rs2 = rs1_data_in | rs2_data_in;

    //-- Operation: rs1 & rs2
    logic [31:0] rs1_and_rs2;
    assign rs1_and_rs2 = rs1_data_in & rs2_data_in;

    //-- Operation: rs1 <s imm
    logic rs1_less_than_imm;
    assign rs1_less_than_imm = 
        signed'(rs1_data_in) < signed'(instruction_in.immediate);

    //-- Operation: rs1 <u imm
    logic rs1_unsigned_less_than_imm;
    assign rs1_unsigned_less_than_imm = 
        unsigned'(rs1_data_in) < unsigned'(instruction_in.immediate);

    //-- Operation: rs1 + imm
    logic [31:0] rs1_plus_imm;
    assign rs1_plus_imm = rs1_data_in + instruction_in.immediate;

    //-- Operation: rs1 ^ imm
    logic [31:0] rs1_xor_imm;
    assign rs1_xor_imm = rs1_data_in ^ instruction_in.immediate;

    //-- Operation: rs1 | imm
    logic [31:0] rs1_or_imm;
    assign rs1_or_imm = rs1_data_in | instruction_in.immediate;

    //-- Operation: rs1 & imm
    logic [31:0] rs1_and_imm;
    assign rs1_and_imm = rs1_data_in & instruction_in.immediate;

    //-- Operation: rs1 << imm
    logic [31:0] rs1_shift_left_imm;
    assign rs1_shift_left_imm = rs1_data_in << instruction_in.immediate[4:0];

    //-- Operation: rs1 >> imm
    logic [31:0] rs1_shift_right_imm;
    assign rs1_shift_right_imm = rs1_data_in >> instruction_in.immediate[4:0];

    //-- Operation: rs1 >>s imm
    logic [31:0] rs1_shift_right_arith_imm;
    assign rs1_shift_right_arith_imm = 
        signed'(rs1_data_in) >>> instruction_in.immediate[4:0];

    //-- Operation: pc + imm
    logic [31:0] pc_plus_imm;
    assign pc_plus_imm = program_counter_in + instruction_in.immediate;

    //-- Operation: pc + 4
    logic [31:0] pc_plus_4;
    assign pc_plus_4 = program_counter_in + 32'(unsigned'(4));

    
    //-----------------------------------
    //-- Check for misaligned addresses
    //-----------------------------------
    always_comb begin : u_misaligned

        //-- The address for the pc should always be a
        //-- multiple of 4. If not, there is misalignement
        if ((next_program_counter & 32'h0000_0003) != 32'h0) begin
            ctrl_is_misaligned = 1;
        end
        else
            ctrl_is_misaligned = 0;
    end
    


    //---------------------------------
    //--- Execute the instructions
    //---------------------------------

    //-------- Control signals
    logic ctrl_jump;
    

    always_comb begin : u_control

        //-- Default value
        rd_data = 32'b0;
        source_data = 32'b0;
        ctrl_jump = 0;
        ctrl_data_valid = 1;
        next_program_counter = pc_plus_4;


        //-- Execute the instruction, only if it is valid!
        if (is_instruction_valid) begin

            casez(instruction_in.op)
                op::LUI: begin  //-- 0
                    //-- x[rd] = sext(immediate[31:12] << 12)
                    rd_data = instruction_in.immediate;
                end
                op::AUIPC: begin  //-- 1
                    //-- auipc rd,imm
                    //-- x[rd] = pc + sext(immediate[31:12] << 12)
                    rd_data = pc_plus_imm;
                end
                op::JAL: begin    //-- 2
                    //-- jal rd,offset
                    //-- x[rd] = pc+4; pc += sext(offset)
                    rd_data = pc_plus_4;
                    next_program_counter = pc_plus_imm;
                    ctrl_jump = 1;
                end
                op::JALR: begin
                    //-- jalr rd,rs1,offset
                    //-- t =pc+4; pc=(x[rs1]+sext(offset))&∼1; x[rd]=t
                    //-- NOTE!: the least significant bit should be set to 0!
                    rd_data = pc_plus_4;
                    next_program_counter = {rs1_plus_imm[31:1], 1'b0};
                    ctrl_jump = 1;
                end
                op::BEQ: begin  //-- 4
                    //-- beq rs1,rs2,offset
                    //-- if (x[rs1] == x[rs2]) pc += sext(offset)
                    if (equal) begin
                        next_program_counter = pc_plus_imm;
                        ctrl_jump = 1;
                    end
                end
                op::BNE: begin
                    //-- bne rs1,rs2,offset
                    //-- if (x[rs1] != x[rs2]) pc += sext(offset)
                    if (!equal) begin
                        next_program_counter = pc_plus_imm;
                        ctrl_jump = 1;
                    end
                end
                op::BLT: begin   //-- 6
                    //-- blt rs1,rs2,offset
                    //-- if (x[rs1] <s x[rs2]) pc += sext(offset)
                    if (rs1_less_than_rs2) begin
                        next_program_counter = pc_plus_imm;
                        ctrl_jump = 1;
                    end
                end
                op::BGE: begin    //-- 7
                    //-- bge rs1,rs2,offset
                    //-- if (x[rs1] >=s x[rs2]) pc += sext(offset)
                    if (rs1_greather_eq_than_rs2) begin
                        next_program_counter = pc_plus_imm;
                        ctrl_jump = 1;
                    end
                end
                op::BLTU: begin   //-- 8
                    //-- bltu rs1,rs2,offset
                    //-- if (x[rs1] <u x[rs2]) pc += sext(offset)
                    if (rs1_unsigned_less_than_rs2) begin
                        next_program_counter = pc_plus_imm;
                        ctrl_jump = 1;
                    end
                end
                op::BGEU: begin   //-- 9
                    //-- bgeu rs1,rs2,offset
                    //-- if (x[rs1] >=u x[rs2]) pc += sext(offset)
                    if (rs1_unsigned_greather_eq_than_rs2) begin
                        next_program_counter = pc_plus_imm;
                        ctrl_jump = 1;
                    end
                end
                op::LB,            //-- 10
                op::LH,            //-- 11
                op::LW,            //-- 12
                op::LBU,           //-- 13
                op::LHU: begin     //-- 14
                    //-- l{b,h,w} rd,offset(rs1)
                    //-- x[rd] = sext(M[x[rs1] + sext(offset)][7:0])
                    rd_data = rs1_plus_imm;

                    //-- The rd is not yet calculated
                    //-- (it is done in the next stage)
                    ctrl_data_valid = 0;
                end
                op::SB,        //-- 15
                op::SH,        //-- 16
                op::SW: begin  //-- 17
                    //M[x[rs1] + sext(offset)] = x[rs2][31:0]
                    //-- Calculate the efective address
                    rd_data = rs1_plus_imm;
                    source_data = rs2_data_in;
                end
                op::ADDI: begin //-- 18
                    //-- x[rd] = x[rs1] + sext(immediate)
                    rd_data = rs1_plus_imm;
                end
                op::SLTI: begin   //-- 19
                    //-- slti rd,rs1,imm
                    //-- x[rd] = x[rs1] <s sext(immediate)
                    rd_data = 32'(unsigned'(rs1_less_than_imm));
                end
                op::SLTIU: begin  //-- 20
                    //-- sltiu rd,rs1,imm
                    //-- x[rd] = x[rs1] <u sext(immediate)
                    rd_data = 32'(unsigned'(rs1_unsigned_less_than_imm));
                end
                op::XORI: begin   //-- 21
                    //-- xori rd,rs1,imm
                    //-- x[rd] = x[rs1] ^ sext(immediate)
                    rd_data = rs1_xor_imm;
                end
                op::ORI: begin    //-- 22
                    //-- ori rd,rs1,imm
                    //-- x[rd] = x[rs1] | sext(immediate)
                    rd_data = rs1_or_imm;
                end
                op::ANDI: begin   //-- 23
                    //-- andi rd,rs1,imm
                    //-- x[rd] = x[rs1] & sext(immediate)
                    rd_data = rs1_and_imm;
                end
                op::SLLI: begin  //-- 24
                    //-- slli rd,rs1,shamt
                    //-- x[rd] = x[rs1] << shamt
                    rd_data = rs1_shift_left_imm;
                end
                op::SRLI: begin   //-- 25
                    //-- srli rd,rs1,shamt
                    //-- x[rd] = x[rs1] >>u shamt
                    rd_data = rs1_shift_right_imm;
                end
                op::SRAI: begin   //-- 26
                    //-- srai rd,rs1,shamt
                    //-- x[rd] = x[rs1] >>s shamt
                    rd_data = rs1_shift_right_arith_imm;
                end
                op::ADD: begin    //-- 27
                    //-- add rd,rs1,rs2
                    //-- x[rd] = x[rs1] + x[rs2]
                    rd_data = rs1_plus_rs2;
                end
                 op::SUB: begin   //-- 28
                    //-- sub rd,rs1,rs2
                    //-- x[rd] = x[rs1] - x[rs2]
                    rd_data = rs1_minus_rs2;
                end
                op::SLL: begin    //-- 29
                    //-- sll rd,rs1,rs2
                    //-- x[rd] = x[rs1] << x[rs2]
                    rd_data = rs1_shift_left_rs2;
                end
                op::SLT: begin    //-- 30
                    //-- slt rd,rs1,rs2
                    //-- x[rd] = x[rs1] <s x[rs2]
                    rd_data = 32'(unsigned'(rs1_less_than_rs2));
                end
                op::SLTU: begin   //-- 31
                    //-- sltu rd,rs1,rs2
                    //-- x[rd] = x[rs1] <u x[rs2]
                    rd_data = 32'(unsigned'(rs1_unsigned_less_than_rs2));
                end
                op::XOR: begin    //-- 32
                    //-- xor rd,rs1,rs2
                    //-- x[rd] = x[rs1] ^ x[rs2]
                    rd_data = rs1_xor_rs2;
                end
                op::SRL: begin    //-- 33
                    //-- srl rd,rs1,rs2
                    //-- x[rd] = x[rs1] >>u x[rs2]
                    rd_data = rs1_shift_right_rs2;
                end
                op::SRA: begin    //-- 34
                    //-- sra rd,rs1,rs2
                    //-- x[rd] = x[rs1] >>s x[rs2]
                    rd_data = rs1_shift_right_arith_rs2;
                end
                op::OR: begin     //-- 35
                    //-- or rd,rs1,rs2
                    //-- x[rd] = x[rs1] | x[rs2]
                    rd_data = rs1_or_rs2;
                end
                op::AND: begin    //-- 36
                    //-- and rd,rs1,rs2
                    //-- x[rd] = x[rs1] & x[rs2]
                    rd_data = rs1_and_rs2;
                end
                op::FENCE,        //-- 37
                op::FENCE_I,      //-- 38
                op::ECALL,        //-- 39
                op::EBREAK: begin  //-- 40
                    rd_data = 32'b0;
                end
                op::CSRRW,        //-- 41
                op::CSRRS,        //-- 42
                op::CSRRC: begin  //-- 43
                    //-- csrrw rd,offset,rs1
                    //-- t = CSRs[csr]; CSRs[csr] = x[rs1]; x[rd] = t
                    source_data = rs1_data_in;

                    //-- The rd is not yet calculated
                    //-- (it is done in the writeback stage)
                    ctrl_data_valid = 0;
                end
                op::CSRRWI,        //-- 44 
                op::CSRRSI,        //-- 45
                op::CSRRCI: begin  //-- 46
                    //-- csrrwi rd,offset,uimm
                    //-- x[rd] = CSRs[csr]; CSRs[csr] = zimm
                    source_data = instruction_in.immediate;
                    ctrl_data_valid = 0;
                end
                op::MRET,       //-- 47
                op::WFI: begin  //-- 48
                    rd_data = 32'b0;
                end

                default: begin
                    rd_data = 32'b0;
                    ctrl_data_valid = 0;
                    ctrl_jump = 0;
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

    always_comb begin: u_exe_status_forwards

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

        //-- Data from previous stage is VALID, it can be used
        //-- in the exe stage
        else if (status_forwards_in == pipeline_status::VALID) begin

            //-- Jump generated in this stage
            if (ctrl_jump) begin
                if (ctrl_is_misaligned) begin

                    status_fw_wire = pipeline_status::FETCH_MISALIGNED;

                    //-- ?? Comprobar su valor con golden 
                    status_bw_wire = pipeline_status::JUMP;
                end
                else
                    status_bw_wire = pipeline_status::JUMP;
            end
        end
    end


    //---------- Mux for generating/propagating the jump address
    always_comb begin : u_mux_jump

        //-- Later stages has higer priority fro jump
        if (status_backwards_in == pipeline_status::JUMP)
            jump_address_backwards_out = jump_address_backwards_in;

        //-- If no jumps in latter stages, check the exe stage
        else if (ctrl_jump) begin
            jump_address_backwards_out = next_program_counter;
        end

        //-- In the rest of cases, just propagate pc
        else begin
            jump_address_backwards_out = program_counter_in;
        end
    end

endmodule
