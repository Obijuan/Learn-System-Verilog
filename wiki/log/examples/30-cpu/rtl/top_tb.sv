module top_tb;

//----------------------------------
//-- COLORES ANSI
//----------------------------------
/* verilator lint_off UNUSEDPARAM */
localparam RED = "\033[31m";
localparam GREEN = "\033[32m";
localparam YELLOW = "\033[33m";
localparam BLUE = "\033[34m";
localparam MAGENTA = "\033[35m";
localparam CYAN = "\033[36m";
localparam RESET = "\033[0m";
/* verilator lint_on UNUSEDPARAM */


//------- RELOJ -----------------------
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
import constants::CLKS_PER_BIT;


/* verilator lint_off UNUSEDSIGNAL */
//-- Leds
logic [7:0] leds;
logic TX;
/* verilator lint_on UNUSEDSIGNAL */
logic RX;

logic [1:0] buttons;
logic [7:0] switches;
assign switches = 8'hAA;
assign TX = 0;


mcu #(
    .CLK_FREQUENCY_MHZ(SYS_CLK_FREQ_MHZ),
    .UART_BAUD_RATE(UART_BAUD_RATE)
) u_mcu (
    //-- Main system clk
    .clk(clk),

    //-- Memory clock
    .clk_mem(~clk),

    //-- LEDs
    .leds(leds),

    //-- Buttons 
    .buttons_async(buttons),

    //-- Switches
    .aux_port(switches),

    //-- SERIAL PORT
    .TX(TX),
    .RX(RX)
);

//-- Valor de los pulsadores
logic sw1;
logic sw2;

//-- Asignar valor a los pulsadores
assign buttons = {sw1, sw2};



//-- Comprobar errores
always @(posedge clk) begin
    if (u_mcu.u_wishbone_leds.leds_stb) begin
        if (u_mcu.u_wishbone_leds.leds_reg < 8'h40) begin
            $display("%s* Error! Falla Test %2d%s", 
                      RED, u_mcu.u_wishbone_leds.leds_reg, RESET);
        end
        else begin
            $display("%sTodos los tests pasados", GREEN);
            $display("================================");
            $display("=========== EXITO! =============");
            $display("================================%s", RESET);
        end
        $finish();
    end
end


//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("\n");

    //-- Valor inicial de los pulsadores
    sw1 = 0;
    sw2 = 0;

    //-- Esperar a que finalice el reset
    repeat (32) @(posedge clk);

    //-- Comienzo de la transmisión de un dato por el puerto serie
    RX = 0; // Start bit

    //-- Esperar a que llegue el bit de START
    repeat (CLKS_PER_BIT) @(posedge clk);
    RX = 1; // Bit 0

    //-- Ciclos de simulacion
    repeat (10000) @(posedge clk);

    //-- Indicar fin simulacion
    $display("Fin: %6d ps", $time);
    $display("---------------------------------");
    $finish();
end

endmodule

