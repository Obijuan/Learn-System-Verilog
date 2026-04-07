module top(
    input logic CLK,
    input logic SW1,
    input logic SW2,

    output logic LED7,
    output logic LED6,
    output logic LED5,
    output logic LED4,
    output logic LED3,
    output logic LED2,
    output logic LED1,
    output logic LED0
);

logic [7:0] led;

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = led[7:0];

//-- Instanciar interfaz
wishbone_interface wb_if();

//-- Instanciar los LEDs
wishbone_leds #(
    .ADDRESS(32'h0008_0000),
    .SIZE(1)
) u_wishbone_leds (
    .clk(CLK),
    .rst(SW1), 
    .leds(led),
    .wishbone(wb_if)
);

//-- Escribir un valor en los LEDs
assign wb_if.adr = 32'h0008_0000;
assign wb_if.cyc = 1;
assign wb_if.we  = 1;
assign wb_if.sel = 4'b0001;
//assign wb_if.dat_mosi = 32'h0000_00F3;
assign wb_if.stb = 1;

always_comb begin : blockName
    if (SW2)
        wb_if.dat_mosi = 32'h0000_00AA;
    else 
        wb_if.dat_mosi = 32'h0000_0055;
end

endmodule

