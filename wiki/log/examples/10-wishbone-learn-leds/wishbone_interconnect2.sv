/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: wishbone_interconnect.sv
 */



module wishbone_interconnect2 #(
    parameter bit [31:0] SLAVE0_ADDRESS,
    parameter bit [31:0] SLAVE1_ADDRESS,
    parameter bit [63:0] SLAVE_ADDRESS,
    parameter bit [63:0] SLAVE_SIZE
) (
    input logic clk,
    input logic rst,

    wishbone_interface.slave master,
    wishbone_interface.master slaves0,
    wishbone_interface.master slaves1
);
    // Signals to master
    logic [31:0] dat_miso;
    logic ack, err;

    //--------------- Address decoding
    //-- Esclavo actual esta seleccionado
    //logic [1:0] select;
    logic select1;
    logic select0;
    logic invalid_address;

    //-- slave = 1
    assign select1 = master.cyc &&
                       master.adr >= SLAVE0_ADDRESS &&
                       master.adr < SLAVE0_ADDRESS + SLAVE_SIZE[31:0];

    //-- slave = 0
    assign select0 = master.cyc &&
                       master.adr >= SLAVE1_ADDRESS &&
                       master.adr <  SLAVE1_ADDRESS + SLAVE_SIZE[63:32];

    assign invalid_address = master.cyc && master.stb && 
                            (select1 == 0) && (select0 == 0);

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
    //logic [1:0] masked_ack, masked_err;
    logic [31:0] masked_dat_miso0;
    logic [31:0] masked_dat_miso1;
    logic masked_ack0;
    logic masked_ack1;
    logic masked_err0;
    logic masked_err1;


    //-- slave = 0
    assign masked_dat_miso0 = 
                 select0 ? slaves0.dat_miso : 0;
    assign masked_ack0 = select0 && slaves0.ack;
    assign masked_err0 = select0 && slaves0.err;


    //-- slave = 1
    assign masked_dat_miso1 = 
                 select1 ? slaves1.dat_miso : 0;
    assign masked_ack1 = select1 && slaves1.ack;
    assign masked_err1 = select1 && slaves1.err;




    //------------ Signals to master
    assign dat_miso = masked_dat_miso0 | masked_dat_miso1;

    assign ack = masked_ack0 | masked_ack1;
    assign err = (masked_err0 | masked_err1) || invalid_address || timeout;

    assign master.dat_miso = dat_miso;
    assign master.ack = ack;
    assign master.err = err;





    //------- Signals from master to slave
    //-- Puerto 0
    assign slaves0.cyc = master.cyc;
    assign slaves0.stb = master.stb && select0;
    assign slaves0.adr = master.adr;
    assign slaves0.sel = master.sel;
    assign slaves0.we = master.we;
    assign slaves0.dat_mosi = master.dat_mosi;

    //-- Puerto 1
    assign slaves1.cyc = master.cyc;
    assign slaves1.stb = master.stb && select1;
    assign slaves1.adr = master.adr;
    assign slaves1.sel = master.sel;
    assign slaves1.we = master.we;
    assign slaves1.dat_mosi = master.dat_mosi;


endmodule
