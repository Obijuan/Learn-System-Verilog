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

    //-- Pulsadores
    input logic SW1,
    input logic SW2,

    //-- Puerto auxiliar
    input logic D7,
    input logic D6,
    input logic D5,
    input logic D4,
    input logic D3,
    input logic D2,
    input logic D1,
    input logic D0,

    //-- SERIAL PORT
    output logic TX,
    input  logic RX
);


//--------------------------------
//-- MICROCONTROLADOR
//--------------------------------
import constants::SYS_CLK_FREQ_MHZ;
import constants::UART_BAUD_RATE;

//-- Leds
logic [15:0] leds;
logic [7:0] leds0;
logic [7:0] leds1;
logic [1:0] buttons;
logic [7:0] aux_port;

assign leds0 = leds[7:0];
assign leds1 = leds[15:8];

mcu #(
    .CLK_FREQUENCY_MHZ(SYS_CLK_FREQ_MHZ),
    .UART_BAUD_RATE(UART_BAUD_RATE)
) u_mcu (
    //-- Main system clk
    .clk(CLK),

    //-- Memory clock
    .clk_mem(~CLK),

    //-- LEDs
    .leds(leds),

    //-- Buttons 
    .buttons_async(buttons),

    //-- Switches
    .aux_port(aux_port),

    //-- SERIAL PORT
    .TX(TX),
    .RX(RX)
);


//-----------------------------------------------------
//--------------- SOLO SINTESIS -----------------------
//-----------------------------------------------------

//-- Lectura de los switches
assign aux_port = {D7, D6, D5, D4, D3, D2, D1, D0};

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = leds0;

//-- Conectar los pulsadores
assign buttons = {SW1, SW2};


endmodule

