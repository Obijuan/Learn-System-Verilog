module top(
    input logic CLK,

    //-- LEDs
    output logic LED7,
    output logic LED6,
    output logic LED5,
    output logic LED4,
    output logic LED3,
    output logic LED2,
    output logic LED1,
    output logic LED0,


    //-- AUX
    output logic D7,
    output logic D6,
    output logic D5,
    output logic D4,
    output logic D3,
    output logic D2,
    output logic D1,
    output logic D0

);

//-- Parametros del reloj
localparam real SYS_CLK_FREQ_MHZ = 12;
localparam real SYS_CLK_PERIOD_PS = (1 / SYS_CLK_FREQ_MHZ)*1000*1000;
localparam int  SIM_CLK_PERIOD = int'(SYS_CLK_PERIOD_PS);
localparam real CLK_FREQUENCY_MHZ = SYS_CLK_FREQ_MHZ;

//-- Parametros para la UART
localparam int UART_BAUD_RATE = 115200;
localparam int CLKS_PER_BIT =
    int'(CLK_FREQUENCY_MHZ*1_000_000.0/UART_BAUD_RATE);

//-- Reloj del sistema
logic clk;


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

assign leds0 = 8'hAA;
assign leds1 = 8'hBB;

//-----------------------------------------------------
//--------------- SOLO SINTESIS -----------------------
//-----------------------------------------------------
assign clk = CLK;

//-- Mostrar el valor leido de la memoria en los LEDs
assign {D7, D6, D5, D4, D3, D2, D1, D0} = VALUE0;

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = VALUE1;



endmodule

