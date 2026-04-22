/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_leds.sv
 */



module wishbone_leds #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 1
) (
    input logic clk,
    input logic rst,

    output logic [7:0] leds,

    wishbone_interface.slave wishbone
);

    // --------------------------------------------------------------------------------------------
    // |                                        Registers                                         |
    // --------------------------------------------------------------------------------------------

    /*verilator lint_off UNUSED*/
    logic [31:0] wb_dat_mosi;
    assign       wb_dat_mosi = wishbone.dat_mosi;

    logic wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && wishbone.ack == 0 &&
                        wishbone.err == 0) && // wb cycle
                       (wishbone.adr >= ADDRESS && 
                        wishbone.adr < ADDRESS + SIZE); // wb address valid

    logic [3:0]  wb_write_sel;
    assign wb_write_sel = (wb_access && wishbone.we) ? wishbone.sel : 0;
    /*verilator lint_on UNUSED*/

    logic [7:0] leds_reg;
    logic leds_stb;

    always_ff @(posedge clk) begin
        if (rst) begin

            //-- Valor inicial de los leds
            leds_reg <= 8'h00;
        end
        else begin
            if (wb_write_sel[0] == 1) begin 
                leds_reg[7:0] <= wb_dat_mosi[7:0];
                leds_stb <= 1; 
            end
            else begin
                leds_stb <= 0;
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                         Wishbone                                         |
    // --------------------------------------------------------------------------------------------

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
                        wishbone.dat_miso <= {24'b0, leds_reg};
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

    assign leds = leds_reg;

endmodule
