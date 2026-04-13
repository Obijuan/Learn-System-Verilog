/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_ram.sv
 */



// ----------------------------------------------------------------------------------------------
// |                                          WARNING                                           |
// |                                                                                            |
// | This ram module uses an inverted clk signal to achieve single cycle performance.           |
// | This should *not* be replicated in any other module. Inverted clocks are discouraged.      |
// | If you're looking for examples on how to implement a Wishbone slave, look elsewhere.       |
// ----------------------------------------------------------------------------------------------

module wishbone_ram #(
    parameter bit [31:0] ADDRESS,
    parameter bit [31:0] SIZE
)(
    input logic clk,
    input logic rst,

    wishbone_interface.slave port_a,
    wishbone_interface.slave port_b
);

    // --------------------------------------------------------------------------------------------
    // |                                          Memory                                          |
    // --------------------------------------------------------------------------------------------

    //-- Instanciar la memoria
    logic [31:0] porta_adr;
    assign porta_adr = port_a.adr - ADDRESS;


    logic [31:0] portb_adr;
    logic [31:0] porta_data;
    logic [31:0] portb_data_in;
    logic [31:0] portb_data_out;
    logic [3:0] portb_sel;
    logic portb_wen;
    logic porta_read_ok;
    logic portb_access;

    memory u_mem (
        .clk(clk),

        //-- Puerto A
        .porta_adr(porta_adr[11:0]),
        .porta_data_out(porta_data),

        //-- Puerto B
        .portb_adr(portb_adr[11:0]),
        .portb_data_in(portb_data_in),
        .portb_wen(portb_wen),
        .portb_sel(portb_sel),
        .portb_data_out(portb_data_out)
    );

    assign port_a.dat_miso = porta_read_ok ? porta_data : 32'h0;

    //-- Conexion al puerto B
    assign portb_wen = port_b.we & portb_access;
    assign port_b.dat_miso = portb_data_out;
    assign portb_data_in = port_b.dat_mosi;
    assign portb_adr = port_b.adr;
    assign portb_sel = port_b.sel;

    // --------------------------------------------------------------------------------------------
    // |                                          Port A                                          |
    // --------------------------------------------------------------------------------------------
    

    always_ff @(posedge clk) begin
        if (rst) begin
            port_a.ack      <= 0;
            port_a.err      <= 0;
            porta_read_ok <= 0;
        end
        else begin
            // default output
            port_a.ack      <= 0;
            port_a.err      <= 0;
            porta_read_ok <= 0;
            // wishbone access
            if (port_a.cyc && port_a.stb) begin
                // check address space
                if (port_a.adr >= ADDRESS && port_a.adr < ADDRESS + SIZE) begin
                    port_a.ack <= 1;
                    port_a.err <= 0;
                    porta_read_ok <= 1;
                end
                else begin
                    port_a.ack <= 0;
                    port_a.err <= 1;
                end
            end
        end
    end

    // --------------------------------------------------------------------------------------------
    // |                                          Port B                                          |
    // --------------------------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            port_b.ack      <= 0;
            port_b.err      <= 0;
            portb_access <= 0;
        end
        else begin
            // default output
            port_b.ack      <= 0;
            port_b.err      <= 0;
            portb_access <= 0;
            // wishbone access
            if (port_b.cyc && port_b.stb) begin
                // check address space
                if (port_b.adr >= ADDRESS && port_b.adr < ADDRESS + SIZE) begin
                    port_b.ack <= 1;
                    port_b.err <= 0;
                    portb_access <= 1;
                end
                else begin
                    port_b.ack <= 0;
                    port_b.err <= 1;
                end
            end
        end
    end

endmodule

// --------------------------------------------------------------------------------------------
    // |                                          Port B                                          |
    // --------------------------------------------------------------------------------------------
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         port_b.ack      <= 0;
    //         port_b.err      <= 0;
    //         port_b.dat_miso <= 0;
    //     end
    //     else begin
    //         // default output
    //         port_b.ack      <= 0;
    //         port_b.err      <= 0;
    //         port_b.dat_miso <= 0;
    //         // wishbone access
    //         if (port_b.cyc && port_b.stb) begin
    //             // check address space
    //             if (port_b.adr >= ADDRESS && port_b.adr < ADDRESS + SIZE) begin
    //                 port_b.ack <= 1;
    //                 port_b.err <= 0;
    //                 if (port_b.we == 0) begin
    //                     // read
    //                     port_b.dat_miso <= memory[port_b.adr - ADDRESS];
    //                 end
    //                 else begin
    //                     // write
    //                     if (port_b.sel[0] == 1) begin memory[port_b.adr - ADDRESS][ 7: 0] <= port_b.dat_mosi[ 7: 0]; end
    //                     if (port_b.sel[1] == 1) begin memory[port_b.adr - ADDRESS][15: 8] <= port_b.dat_mosi[15: 8]; end
    //                     if (port_b.sel[2] == 1) begin memory[port_b.adr - ADDRESS][23:16] <= port_b.dat_mosi[23:16]; end
    //                     if (port_b.sel[3] == 1) begin memory[port_b.adr - ADDRESS][31:24] <= port_b.dat_mosi[31:24]; end
    //                 end
    //             end
    //             else begin
    //                 port_b.ack <= 0;
    //                 port_b.err <= 1;
    //             end
    //         end
    //     end
    // end