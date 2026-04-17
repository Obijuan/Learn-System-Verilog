/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: writeback_stage.sv
 */


module writeback_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]   source_data_in,
    input logic [31:0]   rd_data_in,

    /* verilator lint_off UNUSEDSIGNAL */
    input instruction::t instruction_in,
    /* verilator lint_on UNUSEDSIGNAL */

    input logic [31:0]   program_counter_in,
    input logic [31:0]   next_program_counter_in,

    // Interrupt signals
    input logic external_interrupt_in,
    input logic timer_interrupt_in,

    // Outputs
    output forwarding::t forwarding_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    output logic [31:0] jump_address_backwards_out
);

    //-- Machine External Interrupt Enable
    localparam MEIE = 11;
    localparam MEIE_MASK = 1 << MEIE;

    //-- Machine Timer Interrupt Enable
    localparam MTIE = 7;
    localparam MTIE_MASK = 1 << MTIE;

    //-- Machine External Interrupt Pending
    localparam MEIP = 11;
    localparam MEIP_MASK = 1 << MEIP;

    //-- Machine Timer Interrupt Pending
    localparam MTIP = 7;
    localparam MTIP_MASK = 1 << MTIP;

    //-- Machine Previous Interrupt Enable
    localparam MPIE = 7;
    localparam MPIE_MASK = 1 << MPIE;

    //-- Global Machine Interrupt Enable
    localparam MIE = 3;
    localparam MIE_MASK = 1 << MIE;

    //--------------------------------------------
    //-- CSR REGISTER BANK
    //--------------------------------------------

    //-- MSTATUS REGISTER
    logic [31:0] mstatus;
    logic [31:0] mstatus_data_write;
    logic mstatus_wen;

    //-- MCAUSE REGISTER
    logic mcause_wen;
    logic [31:0] mcause_data_write;

    //-- MEPC REGISTER
    logic [31:0] mepc;
    logic [31:0] mepc_data_write;
    logic mepc_wen;

    //-- Other CSRs
    logic [31:0] mie;
    logic [31:0] mtvec;
    logic [31:0] mip;

    //------------------------------------
    //-- CHECK THE INSTRUCTION
    //------------------------------------
    //-- The current instruction is valid
    logic is_instruction_valid;
    assign is_instruction_valid = 
            status_forwards_in == pipeline_status::VALID;

    logic is_fetch_misaligned;
    assign is_fetch_misaligned = 
        (status_forwards_in == pipeline_status::FETCH_MISALIGNED);

    logic is_fetch_fault;
    assign is_fetch_fault =
        (status_forwards_in == pipeline_status::FETCH_FAULT);

    logic is_illegal_instruction;
    assign is_illegal_instruction = 
        (status_forwards_in == pipeline_status::ILLEGAL_INSTRUCTION);

    logic is_load_misaligned;
    assign is_load_misaligned =
        (status_forwards_in == pipeline_status::LOAD_MISALIGNED);

    logic is_load_fault = 
        (status_forwards_in == pipeline_status::LOAD_FAULT);

    logic is_store_misaligned = 
        (status_forwards_in == pipeline_status::STORE_MISALIGNED);

    logic is_store_fault =
        (status_forwards_in == pipeline_status::STORE_FAULT);

    logic is_ecall =
        (status_forwards_in == pipeline_status::ECALL);

    logic is_ebreak = 
        (status_forwards_in == pipeline_status::EBREAK);

    //-- The instruction generates an exception
    logic is_exception;
    assign is_exception = 
        is_fetch_misaligned || is_fetch_fault || is_illegal_instruction ||
        is_load_misaligned  || is_load_fault  || is_store_misaligned ||
        is_store_fault      || is_ecall       || is_ebreak;

    //-- CSR signals
    logic [11:0] csr_adr;
    logic [31:0] csr_data_read;
    logic [31:0] csr_data_write;
    logic csr_wen;

    //------------------------------------
    //-- AUXILIARY LOGIC
    //------------------------------------

    //-- Accessing MIE CSR
    logic is_csr_MIE;
    assign is_csr_MIE = (csr_adr==csr::MIE);

    //-- Accessing MSTATUS CSR
    logic is_csr_MSTATUS;
    assign is_csr_MSTATUS = (csr_adr==csr::MSTATUS);

    //-- Bit MIE.MEIE is being set
    logic mie_meie;
    assign mie_meie = (is_csr_MIE) && csr_wen &&
                ((csr_data_write & MEIE_MASK)!=0);

    //-- Bit MIE.MTIE is being set
    logic mie_mtie;
    assign mie_mtie = (is_csr_MIE) && csr_wen &&
                ((csr_data_write & MTIE_MASK)!=0);

    //-- Bit MSTATUS.MIE is being set
    logic mstatus_mie;
    assign mstatus_mie = (is_csr_MSTATUS) && csr_wen &&
                    ((csr_data_write & MIE_MASK)!=0);



    //----------------------------------------
    //-- CALCULATE THE EXCEPTION CODE
    //----------------------------------------
    logic [30:0] exception_code;

    always_comb begin : u_exception_code
        //-- FETCH MISALIGNED
        if (is_fetch_misaligned) 
            exception_code = 31'h0; //-- code=0;

        //-- FETCH FAULT
        else if (is_fetch_fault)
            exception_code = 31'h1; //-- code=1;

        //-- ILLEGAL INSTRUCTION
        else if (is_illegal_instruction)
            exception_code = 31'h2; //-- code=2;

        //-- LOAD MISALIGNED
        else if (is_load_misaligned)
            exception_code = 31'h4; //-- code=4;

        //-- LOAD FAULT
        else if (is_load_fault)
            exception_code = 31'h5; //-- code=5;

        //-- STORE MISALIGNED
        else if (is_store_misaligned)
            exception_code = 31'h6; //-- code=6;

        //-- STORE FAULT
        else if (is_store_fault)
            exception_code = 31'h7; //-- code=7;

        //-- ECALL
        else if (is_ecall)
            exception_code = 31'hB; //-- code=11;

        //-- EBREAK
        else if (is_ebreak)
            exception_code = 31'h3; //-- code=3;

        //-- UNKNOWN EXCEPTION
        else
            exception_code = 31'h0;
    end

    //-------------------------------------
    //-- Calculate when an interrupt ocurs
    //-------------------------------------

    //-- There is an external interrupt pending
    logic irq_pending;
    assign irq_pending = (mip & MEIP_MASK) != 0;

    //-- The external interrupt is enabled
    logic irq_enable;
    assign irq_enable = (mie & MEIE_MASK) != 0;

    //-- There is a timer interrupt pending
    logic timer_irq_pending;
    assign timer_irq_pending = (mip & MTIP_MASK) != 0;

    //-- The timer interrupt is enabled
    logic timer_irq_enable;
    assign timer_irq_enable = (mie & MTIE_MASK) != 0;

    //-- The global interrupts are enabled
    logic global_int_enable;
    assign global_int_enable = ((mstatus & MIE_MASK) != 0);

    //-- The external interrupt will be triggered in the next cycle
    logic is_external_int;
    assign is_external_int = 
        irq_pending && irq_enable && global_int_enable;

    //-- The timer interrupt will be triggered in the next cycle
    logic is_timer_int;
    assign is_timer_int = 
        timer_irq_pending && timer_irq_enable && global_int_enable;

    //-- The timer interrupt is caused by the current csr instruction
    //-- (in this cycle)
    logic is_timer_int_csr;
    assign is_timer_int_csr =
                //-- Activation due to the bit MIE.MTIE
                (timer_irq_pending && global_int_enable && mie_mtie) ||

                //-- Activation due to the bit MSTATUS.MIE
                (timer_irq_pending && timer_irq_enable && mstatus_mie);

    //-- The external interrupt is caused by the current
    //-- csr instruction in the current cycle
    logic is_external_int_csr;
    assign is_external_int_csr = 
                //-- Activation due to the bit MIE.MEIE
                (irq_pending && global_int_enable && mie_meie) ||

                //-- Activation due to the bit MSTATUS.MIE
                (irq_pending && irq_enable && mstatus_mie);

    //-- There is an interrupt in the next cycle (either external or timer)
    logic is_interrupt;
    assign is_interrupt = is_external_int || is_timer_int;

    //-- External interrupt within a trap
    logic is_external_int_trap;
    assign is_external_int_trap = 
             irq_pending && irq_enable && 
             (mstatus & MPIE_MASK)!=0;

    //-- Timer interrupt within a trap
    logic is_timer_int_trap;
    assign is_timer_int_trap =
             timer_irq_pending && timer_irq_enable &&
             (mstatus & MPIE_MASK)!=0;

    //-----------------------------------
    //-- Calculate the interrupt code
    //-----------------------------------
    logic [30:0] interrupt_code;
    always_comb begin
        //-- Calcular el codigo de interrupcion
        if (is_external_int || is_external_int_csr ||
            is_external_int_trap)

              interrupt_code = 31'(unsigned'(MEIE)); 

        else if (is_timer_int || is_timer_int_csr ||
                 is_timer_int_trap)
                    interrupt_code = 31'(unsigned'(MTIE)); 
        else
            interrupt_code = 31'b0;
    end

    
    //-----------------------------------
    //-- Multiplexer for the forwarding
    //-----------------------------------
    //--  | | | |
    //--  v v v v
    logic [31:0] rd_data;
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
            forwarding_out.data_valid = 1;
            forwarding_out.address = instruction_in.rd_address;
        end
     end

    

    //----------------------------------------------------
    //-- Writeback control unit
    //----------------------------------------------------
    
    logic [31:0] jump_addr;
    pipeline_status::backwards_t status_bw_wire;
    
    assign status_backwards_out = status_bw_wire;
    assign jump_address_backwards_out = jump_addr;

    //-- If the current instruction should be counted or not
    logic count_inst;
    assign count_inst = is_instruction_valid;

    //-- There is an interruption, except if it is an mret
    logic is_normal_int;

    //-- The mret instruction generates an interrupt
    logic is_mret_int;

    //-- The current instruction is mret
    logic is_mret;

    //-- The current instruction is FENCE.I
    logic is_fence_I;

    

    //--------------------------------------
    //-- PROCESS CSR INSTRUCTIONS
    //--------------------------------------
    always_comb begin : u_process_csr

        //-- Get the csr address
        csr_adr = instruction_in.csr;

        //-- Default values
        csr_wen = 0;
        csr_data_write = 32'b0;
        rd_data = rd_data_in;
        is_normal_int = 0;
        is_mret_int = 0;
        is_mret = 0;
        is_fence_I = 0;

        if (is_instruction_valid) begin

            case(instruction_in.op)
                op::CSRRW,
                op::CSRRWI: begin
                    csr_wen = 1;
                    csr_data_write = source_data_in;
                    rd_data = csr_data_read;
                    is_normal_int = is_interrupt ||  is_external_int_csr ||
                       is_timer_int_csr;
                end
                op::CSRRS,
                op::CSRRSI: begin
                    csr_wen = 1;
                    csr_data_write = csr_data_read | source_data_in; 
                    rd_data = csr_data_read;
                    is_normal_int = is_interrupt ||  is_external_int_csr ||
                       is_timer_int_csr;
                end
                op::CSRRC,
                op::CSRRCI: begin
                    csr_wen = 1;
                    csr_data_write = csr_data_read & ~source_data_in;
                    rd_data = csr_data_read;
                    is_normal_int = is_interrupt ||  is_external_int_csr ||
                       is_timer_int_csr;
                end
                op::MRET: begin
                    is_mret = 1;
                    is_mret_int = is_timer_int_trap || is_external_int_trap;
                end
                op::FENCE_I: begin
                    is_fence_I = 1;
                    is_normal_int = is_interrupt;
                end

                default: begin
                    is_normal_int = is_interrupt;
                end
            endcase
        end
    end

    //---------------------------------------------
    //-- JUMP MANAGMENT
    //-- Generate the control signals
    //---------------------------------------------
    always_comb begin : u_wb_ctrl

        //-------------- Default values
        status_bw_wire = pipeline_status::READY;
        jump_addr = 32'b0;

        //-- Writing to mcause
        mcause_wen = 0;
        mcause_data_write = 32'b0;

        //-- Writing to mstatus
        mstatus_wen = 0;
        mstatus_data_write = 32'b0;

        //-- Writing to mepc
        mepc_wen = 0;
        mepc_data_write = 32'b0;
        
        //-- Maximum priority: exceptions
        //-- AN EXCEPTION HAS OCURRED
        if (is_exception) begin

            status_bw_wire = pipeline_status::JUMP;
            jump_addr = mtvec;

            //-- Write mepc
            mepc_wen = 1;
            mepc_data_write = program_counter_in;

            //-- MPIE = MIE, MIE = 0
            mstatus_wen = 1;
            mstatus_data_write = (mstatus << 4) & MPIE_MASK;

            //-------- Write mcause
            mcause_wen = 1;
            mcause_data_write = {1'b0, exception_code};
        end

        //-- Next priority: Interrupt caused any instrution but mret
        else if (is_normal_int) begin
            //-- JUMP!
            status_bw_wire = pipeline_status::JUMP;
            jump_addr = mtvec;

            //-- Write mepc
            mepc_wen = 1;
            mepc_data_write = next_program_counter_in;

            //-- MPIE = MIE, MIE = 0
            mstatus_wen = 1;
            mstatus_data_write = (mstatus << 4) & MPIE_MASK;

            //-- Write mcause
            mcause_wen = 1;
            mcause_data_write = {1'b1, interrupt_code};   
        end 

        //-- Interrupt caused by mret instruction
        //-- It happens if there is a pending interrupt when executing mret 
        else if (is_mret_int) begin
                //-- JUMP!
                status_bw_wire = pipeline_status::JUMP;
                jump_addr = mtvec;

                //-- MPIE = 1, MIE = 0
                mstatus_wen = 1;
                mstatus_data_write = MPIE_MASK; 

                //-- Write mcause
                mcause_wen = 1;
                mcause_data_write = {1'b1, interrupt_code}; 
            end

        //-- EXECUTE MRET: it generates a jump
        else if (is_mret)begin
            //-- MIE = MPIE
            //-- MPIE = 1
            mstatus_wen = 1;
            mstatus_data_write = (mstatus >> 4) | MPIE_MASK;
            status_bw_wire = pipeline_status::JUMP;
            jump_addr = mepc;
        end

        //-- EXECUTE FENCE.I: it generates a jump to the next instruction
        else if (is_fence_I) begin
            //-- FENCE instruction
            status_bw_wire = pipeline_status::JUMP;
            jump_addr = next_program_counter_in;
        end
    end

    
    //------------------------------------------------
    //-- CSR FILE
    //------------------------------------------------
    csr_file u_csr (
        .clk(clk),
        .rst(rst),

        //----- COMMON PORT
        .csr_adr(csr_adr),
        .csr_data(csr_data_read),
        .csr_data_write(csr_data_write),
        .csr_wen(csr_wen),

        //------- MIP
        .mip(mip),

        //------- MIE
        .mie(mie),

        //------- MEPC
        .mepc_data_write(mepc_data_write),
        .mepc_wen(mepc_wen),
        .mepc(mepc),

        //------- MSTATUS
        .mstatus_data_write(mstatus_data_write),
        .mstatus_wen(mstatus_wen),
        .mstatus(mstatus),

        //------- MCAUSE
        .mcause_data_write(mcause_data_write),
        .mcause_wen(mcause_wen),

        //------- MTVEC
        .mtvec(mtvec),

        //------ CONTROL SIGNALS
        .count_inst(count_inst),
        .irq(external_interrupt_in),
        .irq_timer(timer_interrupt_in)
    );
    

endmodule
