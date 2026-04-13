module TB;


//-- Parametros del reloj
localparam real SYS_CLK_FREQ_MHZ = 12;
localparam real SYS_CLK_PERIOD_PS = (1 / SYS_CLK_FREQ_MHZ)*1000*1000;
localparam int  SIM_CLK_PERIOD = int'(SYS_CLK_PERIOD_PS);
localparam real CLK_FREQUENCY_MHZ = SYS_CLK_FREQ_MHZ;

//-- Parametros para la UART
localparam int UART_BAUD_RATE = 115200;
localparam int CLKS_PER_BIT =
    int'(CLK_FREQUENCY_MHZ*1_000_000.0/UART_BAUD_RATE);


//------- SOLO SIMULACION -----------------------

//-- Proceso de reloj
logic clk;
initial begin
    clk = 1;
    forever begin
        #(SIM_CLK_PERIOD / 2);
        clk = ~clk;
    end
end
//------------------------------------------------


//-----------------------------------------------------------
//---------- COMUN SINTESIS - SIMULACION --------------------
//-----------------------------------------------------------
import constants::VALUE0;
import constants::VALUE1;


//-- Reloj para la memoria
logic clk_mem;
assign clk_mem = ~clk;

//-- Pulsador de reset
logic rst;
logic [6:0] rst_cnt = 7'b0;

assign rst = ~rst_cnt[5];

always_ff @( posedge(clk) ) begin
    if (rst_cnt[5]==0)
        rst_cnt <= rst_cnt + 1;
end

//----- Señales para Test
logic [7:0] leds0;
logic [7:0] leds1;

assign leds0 = VALUE0;
assign leds1 = VALUE1;

//--------------------------------------
//--- MEMORIA ROM
//--------------------------------------






//---------------------------------------------------------
//----------------- SOLO SIMULACION -----------------------
//---------------------------------------------------------

//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    //-- Esperar a que finalice el reset
    repeat (32) @(posedge clk);

    @(posedge clk);

    //-- Ciclos de ejecucion
    repeat (10) @(posedge clk);


    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    $finish();
end

endmodule

