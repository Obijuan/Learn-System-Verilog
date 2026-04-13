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

//-- Reloj del sistema
logic  clk;
assign clk = CLK;


//-----------------------------------------------------------
//---------- COMUN SINTESIS - SIMULACION --------------------
//-----------------------------------------------------------

//-- Reloj para la memoria
logic clk_mem;
assign clk_mem = ~clk;

//-----------------------------------------------------------------------
//-- RESET: El reset se realiza tras 32 ciclos
//-- En las FPGAs ICE40 la memoria tarda 32 ciclos en inicializarse tras
//-- la carga del bitstream
//-----------------------------------------------------------------------
logic rst;
logic [6:0] rst_cnt = 7'b0;

assign rst = ~rst_cnt[5];

always_ff @( posedge(clk) ) begin
    if (rst_cnt[5]==0)
        rst_cnt <= rst_cnt + 1;
end

//-- Acceso a la memoria
wishbone_interface fetch_bus();
wishbone_interface mem_bus();

//------------------------------------------
//-- PERIFERICOS
//------------------------------------------
import constants::MEMORY_START;
import constants::MEMORY_SIZE;

wishbone_interface mem_bus_slaves[1]();
wishbone_interconnect #(
    .NUM_SLAVES(1),
    .SLAVE_ADDRESS({
        MEMORY_START
    }),
    .SLAVE_SIZE({
        MEMORY_SIZE
    })
) peripheral_bus_interconnect (
    .clk(clk),
    .rst(rst),
    .master(mem_bus),
    .slaves(mem_bus_slaves)
);

//-- MEMORIA RAM
wishbone_ram #(
        .ADDRESS(MEMORY_START),
        .SIZE(MEMORY_SIZE)
    ) ram (
        .clk(clk_mem),
        .rst(rst),
        .port_a(fetch_bus.slave),
        .port_b(mem_bus_slaves[0])
    );




//----------------------------
//-- TEST
//-----------------------------
//-- Valores para las pruebas
localparam bit [7:0] VALUE0 = 8'hAA;
localparam bit [7:0] VALUE1 = 8'hBB;

logic [7:0] leds0;
logic [7:0] leds1;

assign leds0 = VALUE0;
assign leds1 = VALUE1;

//-----------------------------------------------------
//--------------- SOLO SINTESIS -----------------------
//-----------------------------------------------------

//-- Mostrar el valor leido de la memoria en los LEDs
assign {D7, D6, D5, D4, D3, D2, D1, D0} = VALUE0;

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = VALUE1;



endmodule

