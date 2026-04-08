/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_interconnect.sv
 */



module wishbone_interconnect #(
    parameter bit [63:0] SLAVE_ADDRESS,
    parameter bit [63:0] SLAVE_SIZE
) (
    input logic clk,
    input logic rst,

    wishbone_interface.slave master,
    wishbone_interface.master slaves [2]
);
    // Signals to master
    logic [31:0] dat_miso;
    logic ack, err;

    //--------------- Address decoding
    //-- Esclavo actual esta seleccionado
    logic [1:0] select;
    logic invalid_address;

    //-- slave = 1
    assign select[1] = master.cyc &&
                       master.adr >= SLAVE_ADDRESS[31:0] &&
                       master.adr < SLAVE_ADDRESS[31:0] + SLAVE_SIZE[31:0];

    //-- slave = 0
    assign select[0] = master.cyc &&
                       master.adr >= SLAVE_ADDRESS[63:32] &&
                       master.adr <  SLAVE_ADDRESS[63:32] + SLAVE_SIZE[63:32];

    assign invalid_address = master.cyc && master.stb && select == 0;

    // Bus monitor (timeout)
    logic [7:0] count;
    logic timeout;
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
        end
        else begin
            if (ack || err) begin 
                count <= 0;        
            end
            else if (master.cyc && master.stb && count < 255) begin 
                count <= count + 1; 
            end
            else begin 
                count <= 0;         
            end
        end
    end

    assign timeout = (count == 255);
    



    //------------- Signals from slave
    logic [1:0] masked_ack, masked_err;
    logic [1:0] [31:0] masked_dat_miso;


    //-- slave = 0
    assign masked_dat_miso[0] = 
                 select[0] ? slaves[0].dat_miso : 0;
    assign masked_ack[0] = select[0] && slaves[0].ack;
    assign masked_err[0] = select[0] && slaves[0].err;


    //-- slave = 1
    assign masked_dat_miso[1] = 
                 select[1] ? slaves[1].dat_miso : 0;
    assign masked_ack[1] = select[1] && slaves[1].ack;
    assign masked_err[1] = select[1] && slaves[1].err;




    //------------ Signals to master
    assign dat_miso = masked_dat_miso[0] | masked_dat_miso[1];

    assign ack = |masked_ack;
    assign err = |masked_err || invalid_address || timeout;

    assign master.dat_miso = dat_miso;
    assign master.ack = ack;
    assign master.err = err;





    //------- Signals from master to slave
    //-- Puerto 0
    assign slaves[0].cyc = master.cyc;
    assign slaves[0].stb = master.stb && select[0];
    assign slaves[0].adr = master.adr;
    assign slaves[0].sel = master.sel;
    assign slaves[0].we = master.we;
    assign slaves[0].dat_mosi = master.dat_mosi;

    //-- Puerto 1
    assign slaves[1].cyc = master.cyc;
    assign slaves[1].stb = master.stb && select[1];
    assign slaves[1].adr = master.adr;
    assign slaves[1].sel = master.sel;
    assign slaves[1].we = master.we;
    assign slaves[1].dat_mosi = master.dat_mosi;


endmodule
