module top(
    input logic CLK,
    input logic SW1,

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

leds_port u1(
    .clk(CLK),
    .rst(SW1),

    .data_in(8'b10101010),
    .wen(1'b1),

    .led(led)
);


endmodule

