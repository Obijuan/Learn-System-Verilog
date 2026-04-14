/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: op.sv
 */



/*verilator lint_off UNUSED*/

package op;
    typedef enum logic [5:0] {
        LUI,    //-- 0  ✅   
        AUIPC,  //-- 1  ✅ 
        JAL,    //-- 2  ✅  
        JALR,   //-- 3  ✅
        BEQ,    //-- 4  ✅
        BNE,    //-- 5  ✅
        BLT,    //-- 6  ✅
        BGE,    //-- 7  ✅
        BLTU,   //-- 8  ✅
        BGEU,   //-- 9  ✅
        LB,     //-- 10 ✅
        LH,     //-- 11 ✅
        LW,     //-- 12 ✅
        LBU,    //-- 13 ✅
        LHU,    //-- 14 ✅
        SB,     //-- 15 ✅
        SH,     //-- 16 ✅
        SW,     //-- 17 ✅    
        ADDI,   //-- 18 ✅
        SLTI,   //-- 19 ✅
        SLTIU,  //-- 20 ✅
        XORI,   //-- 21 ✅
        ORI,    //-- 22 ✅
        ANDI,   //-- 23 ✅
        SLLI,   //-- 24 ✅
        SRLI,   //-- 25 ✅
        SRAI,   //-- 26 ✅
        ADD,    //-- 27 ✅ 
        SUB,    //-- 28 ✅    
        SLL,    //-- 29 ✅
        SLT,    //-- 30 ✅
        SLTU,   //-- 31 ✅  
        XOR,    //-- 32 ✅ 
        SRL,    //-- 33 ✅
        SRA,    //-- 34 ✅
        OR,     //-- 35 ✅
        AND,    //-- 36 ✅
        FENCE,  //-- 37 ✅
        FENCE_I,//-- 38 ✅
        ECALL,  //-- 39 ✅
        EBREAK, //-- 40 ✅
        CSRRW,  //-- 41 ✅
        CSRRS,  //-- 42 ✅
        CSRRC,  //-- 43 ✅
        CSRRWI, //-- 44 ✅
        CSRRSI, //-- 45 ✅
        CSRRCI, //-- 46 ✅
        MRET,   //-- 47 ⬅️
        WFI,    //-- 48
        ILLEGAL //-- 49
    } t;
endpackage

/*verilator lint_on UNUSED*/
