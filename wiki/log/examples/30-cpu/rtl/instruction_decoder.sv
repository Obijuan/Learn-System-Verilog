/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: instruction_decoder.sv
 */



module instruction_decoder (
    input  logic [31:0]   instruction_in,
    output instruction::t instruction_out
);

    //-- Reference implementation
    //ref_instruction_decoder golden(.*);

    
    //-----------------------------------------
    //--- Decode the OPCODE
    //-----------------------------------------
    //-- Raw opcode
    logic [4:0] opcode;
    assign opcode = instruction_in[6:2];

    //-- This bits should always be 11 for the RV32i
    logic is_rv32i;
    assign is_rv32i = (instruction_in[1:0] == 2'b11);

    //-- func3 field
    logic [2:0] func3;
    assign func3 = instruction_in[14:12];

    //-- func7 field
    logic [6:0] func7;
    assign func7 = instruction_in[31:25];

    //-- 12 bits immediate field
    logic [11:0] imm12;
    assign imm12 = instruction_in[31:20];

    //------------------ Process de opcode

    //-- Temporal decoded operation
    op::t op;

    //-- Auxiliary wires
    logic is_branch;
    logic is_store;
    logic is_system;
    logic is_illegal;
    logic is_lui;
    logic is_auipc;
    logic is_jal;
    logic is_csrrwi;
    logic is_csrrsi;
    logic is_csrrci;
    logic is_csrrw;
    logic is_csrrs;
    logic is_csrrc;
    logic is_type_r;
    logic is_csr;

    assign is_illegal = (op == op::ILLEGAL);
    assign is_lui = (op == op::LUI);
    assign is_auipc = (op == op::AUIPC);
    assign is_jal = (op == op::JAL);
    assign is_csrrwi = (op == op::CSRRWI);
    assign is_csrrsi = (op == op::CSRRSI);
    assign is_csrrci = (op == op::CSRRCI);
    assign is_csrrw = (op == op::CSRRW);
    assign is_csrrs = (op == op::CSRRS);
    assign is_csrrc = (op == op::CSRRC);
    assign is_csr = (is_csrrw  || is_csrrs  || is_csrrc ||
                     is_csrrwi || is_csrrsi || is_csrrci);

    //-- Process the opcode
    always_comb begin : u_opcode

        //-- Default values
        is_branch = 0;
        is_store = 0;
        is_system = 0;
        is_type_r = 0;
        op = op::ILLEGAL;

        //-- The 2 least significant bit of the opcode
        //-- should always be 11 (for RVI32)
        
        if (is_rv32i)
            casez(opcode)
                5'b01101: op = op::LUI;
                5'b00101: op = op::AUIPC;
                5'b11011: op = op::JAL;
                5'b11001: op = op::JALR;

                //-- Type B instructions
                5'b11000: begin
                    is_branch = 1;
                    casez(func3)
                        3'b000:  op = op::BEQ;
                        3'b001:  op = op::BNE;
                        3'b100:  op = op::BLT;
                        3'b101:  op = op::BGE;
                        3'b110:  op = op::BLTU;
                        3'b111:  op = op::BGEU;
                        default: op = op::ILLEGAL;
                    endcase
                end

                //-- LOAD instructions
                5'b00000: begin
                    casez(func3)
                        3'b000:  op = op::LB;
                        3'b001:  op = op::LH;
                        3'b010:  op = op::LW;
                        3'b100:  op = op::LBU;
                        3'b101:  op = op::LHU;
                        default: op = op::ILLEGAL;
                    endcase
                end

                //-- STORE instructions
                5'b01000: begin
                    is_store = 1;
                    casez(func3)
                        3'b000:  op = op::SB;
                        3'b001:  op = op::SH;
                        3'b010:  op = op::SW;
                        default: op = op::ILLEGAL; 
                    endcase
                end

                //-- Type I Instructions
                5'b00100: begin
                    casez(func3)
                        3'b000: op = op::ADDI;
                        3'b001: begin
                            if (func7 == 7'b0)
                            op = op::SLLI;
                        end
                        3'b010: op = op::SLTI;
                        3'b011: op = op::SLTIU;
                        3'b100: op = op::XORI;
                        3'b101: begin
                            if (func7 == 7'b0)
                                op = op::SRLI;
                            else if (func7 == 7'b0100000)
                                op = op::SRAI;
                        end
                        3'b110: op = op::ORI;
                        3'b111: op = op::ANDI;
                    endcase
                end

                //-- Type R instructions
                5'b01100: begin
                    is_type_r = 1;
                    casez(func3)
                        3'b000: casez(func7)
                            7'b0000000: op = op::ADD;
                            7'b0100000: op = op::SUB;
                            default: op = op::ILLEGAL;
                        endcase
                        3'b001: begin
                            if (func7 == 7'b0)
                              op = op::SLL;
                        end
                        3'b010: begin
                            if (func7 == 7'b0)
                                op = op::SLT;
                        end
                        3'b011: begin
                            if (func7 == 7'b0)
                                op = op::SLTU;
                        end
                        3'b100: begin
                            if (func7 == 7'b0)
                                op = op::XOR;
                        end
                        3'b101: begin
                            if (func7 == 7'b0)
                                op = op::SRL;
                            else if (func7 == 7'b0100000)
                                op = op::SRA;
                        end
                        3'b110: begin
                            if (func7 == 7'b0)
                                op = op::OR;
                        end
                        3'b111: begin
                            if (func7 == 7'b0)
                                op = op::AND;
                        end
                    endcase
                end

                //-- FENCE
                5'b00011: begin
                    casez(func3)
                        3'b000: op = op::FENCE;
                        3'b001: op = op::FENCE_I;
                        default: op = op::ILLEGAL;
                    endcase
                end

                //-- SYSTEM Instruction
                5'b11100: begin
                    casez(func3)
                        3'b000: begin 
                            is_system = 1;
                            case(imm12)
                                12'b000000000000: op = op::ECALL;
                                12'b000000000001: op = op::EBREAK;
                                12'b001100000010: op = op::MRET;
                                12'b000100000101: op = op::WFI;
                                default: op = op::ILLEGAL;
                            endcase
                        end
                        3'b001: op = op::CSRRW;
                        3'b010: op = op::CSRRS;
                        3'b011: op = op::CSRRC;
                        3'b101: op = op::CSRRWI;
                        3'b110: op = op::CSRRSI;
                        3'b111: op = op::CSRRCI;
                        default: op = op::ILLEGAL;
                    endcase
                end
                default: op = op::ILLEGAL;
            endcase
    end

    //----------------------------------------------------------
    //----      Get the REGISTERS
    //----------------------------------------------------------

    logic [4:0] rd_address;
    logic [4:0] rs1_address;
    logic [4:0] rs2_address;
    assign rd_address = instruction_in[11:7];
    assign rs1_address = instruction_in[19:15];
    assign rs2_address = instruction_in[24:20];

    //-- Get the destination register
    //-- If the instruction does not use rd, it should be 0
    always_comb begin : u_rd;

        //-- Illegal instruction
        if (is_illegal)
            instruction_out.rd_address = 5'b0;

        //-- Instruction with no rd
        else if (is_branch || is_store || is_system)
            instruction_out.rd_address = 5'b0;

        //-- The rest of instrucctions has rd
        else
            instruction_out.rd_address = rd_address;
    end

    //-- Get the rs1 register
    //-- If the instruction does not use rs1, it should be 0
    always_comb begin : u_rs1;

        //-- Illegal instruction
        if (is_illegal)
            instruction_out.rs1_address = 5'b0;

        //-- Instructions with no rs1
        else if (is_lui    || is_auipc  || is_jal    || is_system ||
                 is_csrrwi || is_csrrsi || is_csrrci)
                    instruction_out.rs1_address = 5'b0;
        else
            instruction_out.rs1_address = rs1_address;
    end

    //-- Get the rs2 register
    //-- If the instruction does not use rs2, it should be 0
    always_comb begin : u_rs2;

        //-- Illegall instruction
        if (is_illegal)
            instruction_out.rs2_address = 5'b0;

        //-- Instructions with rs2
        else if (is_branch || is_store || is_type_r)
            instruction_out.rs2_address = rs2_address;

        //-- Instruction with no rs2
        else
            instruction_out.rs2_address = 5'b0;
    end


    //-----------------------------------------------------
    //--- DECODE the Inmediate value
    //-----------------------------------------------------
    logic [19:0] imm20;
    assign imm20 = instruction_in[31:12];

    //------- Different fields for constructing the immediate value
    //------- for the JAL instruction
    //-- Bit 20 of the immediate for jal
    bit ji20;
    assign ji20 = instruction_in[31];

    //-- Bits 10:1 of the immediate for jal
    logic [9:0] ji10_1;
    assign ji10_1 = instruction_in[30:21];

    //-- Bit 11 of the inmediate for jal
    bit ji11;
    assign ji11 = instruction_in[20];

    //-- Bits 19:12 of the inmediate for jal
    logic [7:0] ji19_12;
    assign ji19_12 = instruction_in[19:12];

    //----- Fields for constructing the immediate value of B instructions
    //-- Bit 12 of the immediate for Bxx
    bit bi12;
    assign bi12 = instruction_in[31];

    //-- Bit 11 of the immediate for Bxx
    bit bi11;
    assign bi11 = instruction_in[7];

    //-- Bits 10:5 of the immediate for BXX
    logic [5:0] bi10_5;
    assign bi10_5 = instruction_in[30:25];

    //-- Bits 4:1 of the immediate for Bxx
    logic [3:0] bi4_1;
    assign bi4_1 = instruction_in[11:8];

    //----- Fields for constructing the immediate value of
    //----- the STORE instructions
    logic [6:0] si11_5;
    assign si11_5 = instruction_in[31:25];

    logic [4:0] si4_0;
    assign si4_0 = instruction_in[11:7];

    //----- Fiels for the SHIFT instrucctions
    logic [4:0] shamt;
    assign shamt = instruction_in[24:20];

    //---- Fields for CSRs instructions (with immediate)
    logic [4:0] uimm;
    assign uimm = instruction_in[19:15]; 

    always_comb begin : u_inmm
        casez(op)

            //-- Instructions with a 20-bits immmediate value
            op::LUI, 
            op::AUIPC: instruction_out.immediate = {imm20, 12'h000};

            //-- JAL Instruction: imm[20|10:1|11|19:12]
            //--- 31 |  30:21  |20 | 19-12   |
            //--- i20| i10-i1  |i11| i19-i12 |
            op::JAL: instruction_out.immediate = 
                32'(signed'({ji20, ji19_12, ji11, ji10_1, 1'b0}));

            //-- Instructions with a 12-bits immediate value
            //-- TODO: Maybe some instructions do not requiere
            //--   sign expansion
            op::JALR,
            op::LB,
            op::LH,
            op::LW,
            op::LBU,
            op::LHU,
            op::ADDI,
            op::SLTI,
            op::SLTIU,
            op::XORI,
            op::ORI,
            op::ANDI,
            op::FENCE,
            op::FENCE_I: instruction_out.immediate = 32'(signed'(imm12));

            //-- B instructions
            //-- 31 | 30:25  |...| 11:8  | 7   |
            //-- i12| i10-i5 |...| i4-i1 | i11 |
            //-- imm[12|10:5]      imm[4:1|11]
            op::BEQ,
            op::BNE,
            op::BLT,
            op::BGE,
            op::BLTU,
            op::BGEU: instruction_out.immediate = 
               32'(signed'({bi12, bi11, bi10_5, bi4_1, 1'b0}));

            //-- STORE instructions
            //-- 31:25    |...| 11:7     |
            //-- si11-si5 |...| si4-si0  |
            // imm[11:5]  |...| imm[4:0] |
            op::SB,
            op::SH,
            op::SW: instruction_out.immediate = 
               32'(signed'({si11_5, si4_0}));

            //-- SHIFT instructions (with immediate)
            //--  24:20
            //--  shamt[4:0]
            op::SLLI,
            op::SRLI,
            op::SRAI: instruction_out.immediate = 
                32'(unsigned'(shamt));

            //-- CSR instructions (with immediate)
            //-- 19:15
            //-- uimm[4:0]
            op::CSRRWI,
            op::CSRRSI,
            op::CSRRCI: instruction_out.immediate = 
                32'(unsigned'(uimm));

            default: instruction_out.immediate = 32'h0000_0000;
        endcase
    end

    //------------------------------------------
    //--- CSR Registers
    //------------------------------------------
    //-- Get the raw CSR address
    logic [11:0] csr_address;
    assign csr_address = instruction_in[31:20];

    //-- It is a Read-Only register
    logic csr_is_ro;
    assign csr_is_ro = (csr_address[11:10] == 2'b11);

    //-- Group the registers for checking the available
    //-- address. 
    logic csr_group1;
    //-- MVENDORID, MARCHID, MIMPID, MHARTID, MCONFIGPTR
    assign csr_group1 = (csr_address >= 12'hF11) && 
                        (csr_address <= 12'hF15);

    logic csr_group2;
    //-- MSTATUS,  MISA, MEDELEG, MIDELEG, MIE, MTVEC, MCOUNTEREN
    assign csr_group2 = (csr_address >= 12'h300) && 
                        (csr_address <= 12'h306);

    logic csr_group3;
    //-- MSCRATCH, MEPC, MCAUSE, MTVAL, MIP
    assign csr_group3 = (csr_address >= 12'h340) && 
                        (csr_address <= 12'h344);

    logic csr_group4;
    //-- MINSTRET, MHPMCOUNTER3 - MHPMCOUNTER31
    assign csr_group4 = (csr_address >= 12'hB02) &&
                        (csr_address <= 12'hB1F);

    logic csr_group5;
    //-- MINSTRETH, MHPMCOUNTER3H - MHPMCOUNTER31H
    assign csr_group5 = (csr_address >= 12'hB83) &&
                        (csr_address <= 12'hB9F);

    logic csr_group6;
    //-- MHPMEVENT3 - MHPMEVENT31
    assign csr_group6 = (csr_address >= 12'h323) &&
                        (csr_address <= 12'h33F);

    //-------------------------------------------------
    //-- FINAL generation of the instruction
    //--   In the case of CSR, It should be checked that
    //--   the csr_address is correct, and also that we are not
    //--   writing in a Read-Only CSR
    //----------------------------------------------------------
    always_comb begin : u_final
        
        //-- Check the csr instruction
        if (is_csr) begin

            //-- Check for valid CSR address
            if (csr_group1 || csr_group2 || 
                csr_group3 || csr_group4 ||
                csr_group5 || csr_group6 ||
               (csr_address == 12'h310)  ||    //-- MSTATUSH
               (csr_address == 12'hB00)  ||    //-- MCYCLE  
               (csr_address == 12'hB80)) begin //-- MCYCLEH

                    //-- VALID ADDRES!!!

                    //-- Check for Read-only CSR
                    if (csr_is_ro) begin

                        //-- Not allowed to write in a RO CSR 
                        if (is_csrrw || is_csrrwi) begin
                            instruction_out.op = op::ILLEGAL;
                            instruction_out.csr = csr::t'(12'b0);
                        end
                        else if (is_csrrs || is_csrrc) begin

                            //-- Trying to modify a RO CSR
                            if (rs1_address != 5'b0) begin
                                instruction_out.op = op::ILLEGAL;
                                instruction_out.csr = csr::t'(12'b0);
                            end
                            else begin
                                //-- CSR can be read normally (no writting)
                                instruction_out.op = op;
                                instruction_out.csr = csr::t'(csr_address);
                            end

                        end
                        else if (is_csrrsi || is_csrrci) begin
                            
                            if (instruction_out.immediate[4:0] != 5'b0) begin
                                instruction_out.op = op::ILLEGAL;
                                instruction_out.csr = csr::t'(12'b0);
                            end
                            else begin
                                //-- CSR can be read normally
                                instruction_out.op = op;
                                instruction_out.csr = csr::t'(csr_address);
                            end
                        end
                        //-- Other cases...
                        else begin
                            instruction_out.op = op::ILLEGAL;
                            instruction_out.csr = csr::t'(12'b0);
                        end
                    end

                    //-- CSR is not RO: No problem
                    else begin
                        instruction_out.op = op;
                        instruction_out.csr = csr::t'(csr_address);
                    end
            end

            //-- Not valid CSR addr
            else begin
                instruction_out.op = op::ILLEGAL;
                instruction_out.csr = csr::t'(12'b0);
            end
        end

        //-- Not a csr instruction
        else begin
            instruction_out.op = op;
            instruction_out.csr = csr::t'(12'b0);
        end 
    end


endmodule
