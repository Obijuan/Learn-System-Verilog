module TB;

//------- SOLO SIMULACION -----------------------
import constants::SIM_CLK_PERIOD;

//-- Proceso de reloj
logic clk;
initial begin
    clk = 1;
    forever begin
        #(SIM_CLK_PERIOD / 2);
        clk = ~clk;
    end
end

//--------------------------------
//-- MICROCONTROLADOR
//--------------------------------
import constants::SYS_CLK_FREQ_MHZ;
import constants::UART_BAUD_RATE;
import constants::DEBOUNCER_SIZE_SIM;

//-- Leds
logic [15:0] leds;
logic [7:0] leds0;
logic [7:0] leds1;
logic [4:0] buttons;

assign leds0 = leds[7:0];
assign leds1 = leds[15:8];

mcu #(
    .CLK_FREQUENCY_MHZ(SYS_CLK_FREQ_MHZ),
    .UART_BAUD_RATE(UART_BAUD_RATE),
    .DEBOUNCER_SIZE(DEBOUNCER_SIZE_SIM)
) u_mcu (
    //-- Main system clk
    .clk(clk),

    //-- Memory clock
    .clk_mem(~clk),

    //-- LEDs
    .leds(leds),

    //-- Buttons 
    .buttons_async(buttons)
);

//-- Valor de los pulsadores
logic sw1;
logic sw2;

//-- Asignar valor a los pulsadores
assign buttons = {3'b0, sw1, sw2};


//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    //-- Valor inicial de los pulsadores
    sw1 = 0;
    sw2 = 0;

    //-- Esperar a que finalice el reset
    repeat (32) @(posedge clk);

    @(posedge clk);

    sw1 = 1;

    repeat (7) @(posedge clk);

    sw1 = 0;

    repeat (7) @(posedge clk);

    sw1 = 1;

    repeat (7) @(posedge clk);

    sw1 = 0;

    //-- Ciclos de ejecucion
    repeat (10) @(posedge clk);


    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    $finish();
end

endmodule

