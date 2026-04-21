module mcu #(
    parameter real CLK_FREQUENCY_MHZ,
    parameter int  UART_BAUD_RATE
) (
    //-- Main system clk
    input logic clk,

    //-- Memory clock
    input logic clk_mem,

    //-- LEDs
    output logic [15:0] leds,

    //-- Buttons 
    input  logic [1:0] buttons_async,

    //-- SERIAL PORT
    output logic TX,
    input  logic RX
);

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

//---------------------------------------------
//-- SINCRONIZACION DE SEÑALES EXTERNAS
//---------------------------------------------
logic sw1_sync;
synchronizer u_sw1 (
    .clk(clk),
    .async_in(buttons_async[1]),
    .sync_out(sw1_sync)
);

logic sw2_sync;
synchronizer u_sw2 (
    .clk(clk),
    .async_in(buttons_async[0]),
    .sync_out(sw2_sync)
);

logic rx_serial_in;
synchronizer u_sync5 (
    .clk(clk),
    .async_in(RX),
    .sync_out(rx_serial_in)
);


//------------------------------------------
//-- PERIFERICOS
//------------------------------------------
import constants::MEMORY_START;
import constants::MEMORY_SIZE;
import constants::LEDS_START;
import constants::LEDS_SIZE;
import constants::UART_START;
import constants::UART_SIZE;


//-- Acceso a la memoria
wishbone_interface fetch_bus();
wishbone_interface mem_bus();

logic uart_interrupt;

wishbone_interface mem_bus_slaves[3]();
wishbone_interconnect #(
    .NUM_SLAVES(3),
    .SLAVE_ADDRESS({
        MEMORY_START,
        LEDS_START,
        UART_START
    }),
    .SLAVE_SIZE({
        MEMORY_SIZE,
        LEDS_SIZE,
        UART_SIZE
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

//-- PUERTO DE SALIDA CON LEDS
wishbone_leds #(
    .ADDRESS(LEDS_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds (
    .clk(clk),
    .rst(rst),
    .leds(leds[7:0]),
    .wishbone(mem_bus_slaves[1])
);

//-- PUERTO SERIE (UART)
wishbone_uart #(
    .ADDRESS(UART_START),
    .SIZE(UART_SIZE),
    .BAUD_RATE(UART_BAUD_RATE),
    .CLK_FREQUENCY_MHZ(CLK_FREQUENCY_MHZ)
) wb_uart (
    .clk(clk),
    .rst(rst),
    .rx_serial_in(rx_serial_in),
    .tx_serial_out(TX),
    .interrupt(uart_interrupt),
    .wishbone(mem_bus_slaves[2])
);


//--- Interrupciones
logic external_interrupt;
logic timer_interrupt;


// Instantiate CPU
cpu cpu(
    .clk(clk),
    .rst(rst),
    .memory_fetch_port(fetch_bus.master),
    .memory_mem_port(mem_bus.master),
    .external_interrupt_in(external_interrupt),
    .timer_interrupt_in(timer_interrupt)
);


//-- TEST
assign external_interrupt = sw1_sync | uart_interrupt;
assign timer_interrupt = sw2_sync;
assign leds[15:8] = 8'h01;

endmodule
