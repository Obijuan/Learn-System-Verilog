
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
simple_bus mi_bus();

//-- Mostrar en los LEDs
assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = led[7:0];

//-- Interconectar el maestro y el esclavo a través del bus
master_mod u_maestro (
    .bus_if(mi_bus)
);

logic [7:0] led;
slave_mod  u_esclavo (
    .clk(CLK),
    .bus_if(mi_bus),
    .led(led)
);

endmodule




