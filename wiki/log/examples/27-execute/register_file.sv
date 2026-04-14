/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: register_file.sv
 */



module register_file (
    input logic clk,
    input logic rst,

    // read ports
    input  logic [4:0]  read_address1,
    output logic [31:0] read_data1,
    input  logic [4:0]  read_address2,
    output logic [31:0] read_data2,

    // write port
    input  logic [4:0]  write_address,
    input  logic [31:0] write_data,
    input  logic        write_enable
);

    // TODO: Delete the following line and implement this module.
    //ref_register_file golden(.*);

    //-- Address width: space for 32 registers
    localparam ADDR_WIDTH = 5;

    //-- Data with
    localparam DATA_WIDTH = 32;

    //-- Size of the register file
    localparam SIZE = 1 << ADDR_WIDTH;

    //-- Register file itself
    logic [DATA_WIDTH-1:0] mem[0:SIZE-1];


    //-- Port 1: Combinational: rs1
    always_comb begin : u_rs1

        //-- Reading of x0
        if (read_address1 == 5'b0)
            read_data1 = 32'b0;

        //-- Reading the rest of registers
        else
            read_data1 = mem[read_address1];
    end

    //-- Port 2: Combinational: rs2
    always_comb begin : u_rs2

        //-- Reading of x0
        if (read_address2 == 5'b0)
            read_data2 = 32'b0;

        //-- Reading the rest of registers
        else
            read_data2 = mem[read_address2];
    end


    //-- Writing port: Synchronous
    always_ff @( posedge clk ) begin : u_rd

        if (rst) begin
            mem <= '{default: 32'h0};
        end
        else
            //-- Write! Any register but x0
            if (write_enable && write_address != 5'b0)
                mem[write_address] <= write_data;
    end

endmodule
