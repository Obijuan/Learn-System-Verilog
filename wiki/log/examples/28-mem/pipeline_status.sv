/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: pipeline_status.sv
 */



/*verilator lint_off UNUSED*/

package pipeline_status;
    typedef enum logic [3:0] {
        VALID,               // 0
        BUBBLE,              // 1
        FETCH_MISALIGNED,    // 2
        FETCH_FAULT,         // 3
        ILLEGAL_INSTRUCTION, // 4
        LOAD_MISALIGNED,     // 5
        LOAD_FAULT,          // 6
        STORE_MISALIGNED,    // 7
        STORE_FAULT,         // 8
        ECALL,               // 9
        EBREAK              // 10
    } forwards_t;

    typedef enum logic [1:0] {
        READY,  // 0
        STALL,  // 1
        JUMP    // 2
    } backwards_t;
endpackage

/*verilator lint_on UNUSED*/
