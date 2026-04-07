
interface simple_bus;
    logic [7:0] data;
    logic       valid;

    // El Maestro ENVÍA datos y señal de validez
    modport master (
        output data, 
        output valid);

    // El Esclavo RECIBE datos y señal de validez
    modport slave  (
        input data, 
        input valid);
endinterface


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

slave_mod  u_esclavo (
    .clk(CLK),
    .bus_if(mi_bus),
    .led(led)
);


endmodule

// Módulo Maestro: Pone un valor en el bus
module master_mod (
    simple_bus.master bus_if
);
    assign bus_if.data = 8'hF1;
    assign bus_if.valid = 1'b1;
endmodule


// Módulo Esclavo: Saca lo que llega por los LEDs
module slave_mod (
    input logic clk,
    simple_bus.slave bus_if,
    output logic [7:0] led

);
    always_ff @( posedge clk ) begin 
        if (bus_if.valid)
            led <= bus_if.data;
    end
        
endmodule


