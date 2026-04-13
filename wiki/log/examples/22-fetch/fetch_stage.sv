/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: fetch_stage.sv
 */

//-----------------------------------------------------------
//-- Persephone score: 8.00 / 8
//-----------------------------------------------------------
//-- TODO: Refactor code. Unify all the sequential logic
//-- into one or two blocks
//-----------------------------------------------------------

module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    //  Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in
);

    import constants::RESET_ADDRESS;

    //-- Program counter
    logic [31:0] pc;

    //------- Signals for accessing the fetch wishbone
    //-- It is always reading from memory
    assign wb.cyc = 1;
    assign wb.stb = 1;
    assign wb.we = 0;

    //-- Read the address given by the pc
    //-- Translate it to word address
    assign wb.adr = {2'b00, pc[31:2]};

    //-- Always read a complete word
    assign wb.sel = 4'b1111;

    //-- As we are reading, it does not matter the content
    //-- of wb.dat_mosi
    assign wb.dat_mosi = 32'h0000_0000;

    //-------------- PROGRAM COUNTER (internal)
    always_ff @(posedge clk ) begin : U_pc
        if (rst) begin
            //-- Reset the PC
            pc <= RESET_ADDRESS;
        end
        else begin
            //-- Update the pc only if the next stage is not STALLED
            if (status_backwards_in != pipeline_status::STALL) begin

                //-- Update the PC
                if (status_backwards_in == pipeline_status::JUMP) begin
                    //-- Update with the new address provided by the jump
                    pc <= jump_address_backwards_in;
                end

                else begin
                    //-- Increment the PC to point to the next
                    //-- Instruction..
                    if (wb.ack == 1)
                        pc <= pc + 4;
                end
            end
        end
    end

    //-------------- PROGRAM COUNTER (external)
    //-- Propagated to the next stage
    always_ff @(posedge clk) begin: U_pc_reg
        if (rst) begin
            //-- Reset the PC_reg
            program_counter_reg_out <= 32'h0000_0000;
        end
        else begin
            //-- Update the register if the next stage is NOT STALLED
            if (status_backwards_in != pipeline_status::STALL) begin
                program_counter_reg_out <= pc;
            end
        end
    end

    //------------ Instruction register (IR)
    always_ff @(posedge clk) begin: U_ir
        if (rst) begin
            //-- Reset the IR
            instruction_reg_out <= 32'h0000_0000;
        end
        else begin
            //-- Update the IR
            if (status_backwards_in != pipeline_status::STALL) begin
                instruction_reg_out <= wb.dat_miso;
            end
        end
    end

    //------------ Pipeline control: status forward
    always_ff @(posedge clk) begin: u_status_fw

        //-- STALL has the highest priority. When STALL is issued by the
        //-- next stage, the current state is kept. No changes at all
        if (status_backwards_in != pipeline_status::STALL) begin

            //-- Then check JUMP. In case of JUMP, the forward status is BUBBLE
            if (status_backwards_in == pipeline_status::JUMP) begin
                status_forwards_out <= pipeline_status::BUBBLE;
            end

            //-- The next stage is READY
            else if (status_backwards_in == pipeline_status::READY) begin

                //-- Check the wishbone error. In case of error
                //-- the status is FETCH_FAULT
                if (wb.err == 1) begin
                    status_forwards_out <= pipeline_status::FETCH_FAULT;
                end

                //-- Instruction is read ok
                else if (wb.ack == 1) begin
                    status_forwards_out <= pipeline_status::VALID;
                end

                //-- Waiting for the memory to read the instruction
                //-- Output signal from this stage are not valid yet
                //-- so it is marked as a BUBBLE
                else begin
                    status_forwards_out <= pipeline_status::BUBBLE;
                end
            end
        end
    end

endmodule
