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


//-- Instanciar el interfaz
led_interface led_if();

leds_port u1(
    .clk(CLK),
    .rst(SW1),

    .led_if(led_if),
    .led(led)
);

//-- Mostrar en los LEDs
assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = led[7:0];


//-- Enviar datos a traves de la interfaz
assign led_if.data = 8'hF3;
assign led_if.valid = 1'b1;

endmodule


