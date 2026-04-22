/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_segments.sv
 */



module wishbone_segments #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE = 1
) (
    input logic clk,
    input logic rst,

    output logic [6:0] segments,
    output logic segments_select,

    wishbone_interface.slave wishbone
);

    // -----------------------------------------------------------
    // |         Registers                                        |
    // -----------------------------------------------------------
    logic [3:0]  wb_write_sel;
    logic [15:0] wb_dat_mosi;

    //-- Espacio para 2 displays de 7 segmentos
    //-- Un byte para cada display
    logic [15:0] segments_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            segments_reg <= 0;
        end
        else begin
            
            //-- Display 0
            if (wb_write_sel[0] == 1) begin 
                segments_reg[ 7: 0] <= wb_dat_mosi[7:0]; 
            end

            //-- Display 1
            if (wb_write_sel[1] == 1) begin 
                segments_reg[15: 8] <= wb_dat_mosi[15:8]; 
            end

            if (wb_write_sel[2] == 1) begin
                
            end

            if (wb_write_sel[3] == 1) begin
                
            end
        end
    end

    // -----------------------------------------------------------------
    // |               Wishbone                                         |
    // -----------------------------------------------------------------
    

    /*verilator lint_off UNUSED*/
    assign       wb_dat_mosi = wishbone.dat_mosi[15:0];

    logic wb_access;
    assign wb_access = (wishbone.cyc && wishbone.stb && wishbone.ack == 0 
                        && wishbone.err == 0) && // wb cycle
                       (wishbone.adr >= ADDRESS && 
                       wishbone.adr < ADDRESS + SIZE); // wb address valid

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
            if (wishbone.cyc && wishbone.stb && 
                wishbone.ack == 0 && wishbone.err == 0) begin
                // check address space
                if (wishbone.adr >= ADDRESS && 
                    wishbone.adr < ADDRESS + SIZE) begin
                    wishbone.ack <= 1;
                    wishbone.err <= 0;
                    if (wishbone.we == 0) begin
                        // read
                        wishbone.dat_miso <= {16'b0, segments_reg};
                    end
                end
                else begin
                    wishbone.ack <= 0;
                    wishbone.err <= 1;
                end
            end
        end
    end

    // ----------------------------------------------------------------------
    // |                        Output                                       |
    // ----------------------------------------------------------------------

    logic segments_select_reg;
    logic [31:0] timer;
    always_ff @(posedge clk) begin
        if (rst) begin
            segments_select_reg <= 1'b0;
            timer               <= 100;
        end
        else begin
            if (timer == 0) begin
                segments_select_reg <= ~segments_select;
                timer <= 100;
            end
            else begin
                timer <= timer - 1;
            end
        end
    end

    assign segments_select = segments_select_reg;
    always_comb begin
        case (segments_select_reg)
            1'b1 : segments = ~segments_reg[6: 0]; //-- Display derecho
            1'b0 : segments = ~segments_reg[14: 8]; //-- Display izquierdo
            default : segments = 7'b111_1111;
        endcase
    end

endmodule
