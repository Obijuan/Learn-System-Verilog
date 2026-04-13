package constants;


//-- Parametros del reloj
localparam real SYS_CLK_FREQ_MHZ = 12;
localparam real SYS_CLK_PERIOD_PS = (1 / SYS_CLK_FREQ_MHZ)*1000*1000;
localparam int  SIM_CLK_PERIOD = int'(SYS_CLK_PERIOD_PS);
localparam real CLK_FREQUENCY_MHZ = SYS_CLK_FREQ_MHZ;

//-- Parametros para la UART
localparam int UART_BAUD_RATE = 115200;
localparam int CLKS_PER_BIT =
    int'(CLK_FREQUENCY_MHZ*1_000_000.0/UART_BAUD_RATE);

//-- Memoria RAM. Direcciones de palabra
localparam bit [31:0] MEMORY_START = 32'h0001_0000;
localparam bit [31:0] MEMORY_SIZE  = 32'h0000_2000;

//-- Direccion de ARRANQUE tras el RESET. Direccion de bytes
//-- Valor por defecto: 0x0004_0000
localparam bit [31:0] RESET_ADDRESS = MEMORY_START << 2;

//-- ANTIRREBOTES
//-- Tamaño del antirrebotes para sintesis
localparam int DEBOUNCER_SIZE = 17;

//-- Tamñao antirrebotes para la simulacion
localparam int DEBOUNCER_SIZE_SIM = 4;

endpackage
