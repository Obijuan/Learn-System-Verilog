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


//--------------------------------
//-- MICROCONTROLADOR
//--------------------------------
import constants::SYS_CLK_FREQ_MHZ;
import constants::UART_BAUD_RATE;
import constants::DEBOUNCER_SIZE;

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
    .DEBOUNCER_SIZE(DEBOUNCER_SIZE)
) u_mcu (
    //-- Main system clk
    .clk(CLK),

    //-- Memory clock
    .clk_mem(~CLK),

    //-- LEDs
    .leds(leds),

    //-- Buttons 
    .buttons_async(buttons)
);


//-----------------------------------------------------
//--------------- SOLO SINTESIS -----------------------
//-----------------------------------------------------

//-- Mostrar el valor leido de la memoria en los LEDs
assign {D7, D6, D5, D4, D3, D2, D1, D0} = leds1;

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = leds0;

//-- Conectar los pulsadores
assign buttons = {3'b000, SW1, SW2};


endmodule

