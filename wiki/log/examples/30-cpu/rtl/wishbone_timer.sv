/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_timer.sv
 */


module wishbone_timer #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 5,
    parameter bit [31:0] CLK_FREQUENCY_MHZ
) (
    input logic clk,
    input logic rst,

    output logic interrupt,

    wishbone_interface.slave wishbone
);


    // --------------------------------------------------------------------------------------------
    // |                                         Registers                                        |
    // --------------------------------------------------------------------------------------------

    // ADDRESS+0: machine time control and status
    // ADDRESS+1: mtime
    // ADDRESS+2: mtimeh
    // ADDRESS+3: mtimecmp
    // ADDRESS+4: mtimecmph
    localparam ADDRESS_MTIMESTATUS = (ADDRESS+0);
    localparam ADDRESS_MTIME       = (ADDRESS+1);
    localparam ADDRESS_MTIMEH      = (ADDRESS+2);
    localparam ADDRESS_MTIMECMP    = (ADDRESS+3);
    localparam ADDRESS_MTIMECMPH   = (ADDRESS+4);

    // --------------------------------- TIMER CONTROL AND STATUS ---------------------------------
    /*
    <------------------------------------> <- NS_PER_CYCLE ->
    | 31....24 ||| 23....16 ||| 15.....8 |||     8....0     |
    | 31----24 ||| 23----16 ||| 15-----8 |||  8----------0  |
    | xxxxxxxx ||| xxxxxxxx ||| xxxxxxxx |||  NS_PER_CYCLE  |
    */
    logic [31:0] mtime_status;
    assign mtime_status = {24'b0, 8'(1000/CLK_FREQUENCY_MHZ)};

    logic [3:0]  wb_write_sel;
    logic [31:0] wb_dat_mosi;

    // ------------------------------------------- MTIME ------------------------------------------
    logic [63:0] mtime;
    always_ff @(posedge clk) begin
        if (rst) begin
            mtime <= 0;
        end
        else begin
            // default: increment timer
            mtime <= mtime + 1;
            // handle write access to register
            if (wishbone.adr == ADDRESS_MTIME) begin
                if (wb_write_sel[0] == 1) begin mtime[ 7: 0] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtime[15: 8] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtime[23:16] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtime[31:24] <= wb_dat_mosi[31:24]; end
            end
            else if (wishbone.adr == ADDRESS_MTIMEH) begin
                if (wb_write_sel[0] == 1) begin mtime[39:32] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtime[47:40] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtime[55:48] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtime[63:56] <= wb_dat_mosi[31:24]; end
            end
        end
    end

    // ----------------------------------------- MTIMECMP -----------------------------------------
    logic [63:0] mtimecmp;
    always_ff @(posedge clk) begin
        if (rst) begin
            mtimecmp <= 0;
        end
        else begin
            // handle write access to register
            if (wishbone.adr == ADDRESS_MTIMECMP) begin
                if (wb_write_sel[0] == 1) begin mtimecmp[ 7: 0] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtimecmp[15: 8] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtimecmp[23:16] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtimecmp[31:24] <= wb_dat_mosi[31:24]; end
            end
            else if (wishbone.adr == ADDRESS_MTIMECMPH) begin
                if (wb_write_sel[0] == 1) begin mtimecmp[39:32] <= wb_dat_mosi[ 7: 0]; end
                if (wb_write_sel[1] == 1) begin mtimecmp[47:40] <= wb_dat_mosi[15: 8]; end
                if (wb_write_sel[2] == 1) begin mtimecmp[55:48] <= wb_dat_mosi[23:16]; end
                if (wb_write_sel[3] == 1) begin mtimecmp[63:56] <= wb_dat_mosi[31:24]; end
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                         Wishbone                                         |
    // --------------------------------------------------------------------------------------------

    /*verilator lint_off UNUSED*/
    assign       wb_dat_mosi = wishbone.dat_mosi;

    logic wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) && // wb cycle
                       (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE); // wb address valid

    assign wb_write_sel = (wb_access && wishbone.we) ? wishbone.sel : 0;
    /*verilator lint_on UNUSED*/

    always_ff @(posedge clk) begin
        if (rst) begin
            wishbone.ack      <= 0;
            wishbone.err      <= 0;
            wishbone.dat_miso <= 0;
        end
        else begin
            // default output
            wishbone.ack      <= 0;
            wishbone.err      <= 0;
            wishbone.dat_miso <= 0;
            // wishbone access
            if (wishbone.cyc && wishbone.stb && wishbone.ack == 0 && wishbone.err == 0) begin
                // check address space
                if (wishbone.adr >= ADDRESS && wishbone.adr < ADDRESS + SIZE) begin
                    wishbone.ack <= 1;
                    wishbone.err <= 0;
                    if (wishbone.we == 0) begin
                        // read
                        if      (wishbone.adr == ADDRESS_MTIMESTATUS) begin wishbone.dat_miso <= mtime_status; end
                        else if (wishbone.adr == ADDRESS_MTIME)       begin wishbone.dat_miso <= mtime[31: 0]; end
                        else if (wishbone.adr == ADDRESS_MTIMEH)      begin wishbone.dat_miso <= mtime[63:32]; end
                        else if (wishbone.adr == ADDRESS_MTIMECMP)    begin wishbone.dat_miso <= mtimecmp[31: 0]; end
                        else if (wishbone.adr == ADDRESS_MTIMECMPH)   begin wishbone.dat_miso <= mtimecmp[63:32]; end
                        else                                          begin wishbone.dat_miso <= 0; end // can not happen because of previous address check
                    end
                end
                else begin
                    wishbone.ack <= 0;
                    wishbone.err <= 1;
                end
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                          Output                                          |
    // --------------------------------------------------------------------------------------------

    assign interrupt = (mtime >= mtimecmp);

endmodule
