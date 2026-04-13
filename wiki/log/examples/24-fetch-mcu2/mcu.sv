module mcu #(
    parameter real CLK_FREQUENCY_MHZ,
    parameter int  UART_BAUD_RATE,
    parameter int DEBOUNCER_SIZE
) (
    //-- Main system clk
    input logic clk,

    //-- Memory clock
    input logic clk_mem,

    //-- LEDs
    output logic [15:0] leds,

    //-- Buttons (order: 4 - drluc- 0)
    input  logic [4:0] buttons_async
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


//--------------------------------------------------
//-- ANTIRREBOTES
//--------------------------------------------------

//-- Antirrebotes para sw1
logic sw1_rdy;
debounce #(
    .SIZE(DEBOUNCER_SIZE)
) u_debouncer1 (
    .clk(clk),

    .value_in(sw1_sync),
    .value_out(sw1_rdy)
);


//------------------------------------------
//-- PERIFERICOS
//------------------------------------------
import constants::MEMORY_START;
import constants::MEMORY_SIZE;

//-- Acceso a la memoria
wishbone_interface fetch_bus();
wishbone_interface mem_bus();

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


//------------------------------------
//-- FETCH STAGE
//------------------------------------

//-- Output signals
logic [31:0] fetch_instruction_reg;
logic [31:0] fetch_program_counter_reg;

//-- Pipeline control signal
pipeline_status::forwards_t fetch_status_forwards;
pipeline_status::backwards_t decode_status_backwards;
logic [31:0] decode_jump_address_backwards;

fetch_stage u_fetch (
    .clk(clk), 
    .rst(rst),

    //-- Memory interface
    .wb(fetch_bus),

    //-- Output data
    .instruction_reg_out(fetch_instruction_reg),
    .program_counter_reg_out(fetch_program_counter_reg),

    //-- Pipeline control
    .status_forwards_out(fetch_status_forwards),
    .status_backwards_in(decode_status_backwards),
    .jump_address_backwards_in(decode_jump_address_backwards)
);

//---------------------------------------
//-- Conexiones para eliminar warnings
//---------------------------------------
assign mem_bus.cyc = 0;
assign mem_bus.stb = 0;
assign mem_bus.sel = 4'b1111;
assign mem_bus.we = 0;
assign mem_bus.adr = 32'h0;

//----------------------------
//-- TEST
//-----------------------------

//-- La etapa de decodificación está lista
assign decode_status_backwards = pipeline_status::READY;

//-- No hay salto en las etapas posteriores
assign decode_jump_address_backwards = 32'h0;

//-- Señal de comienzo
logic start;
assign start = rst_cnt[5];

//-- Contador unario
logic [7:0] unary_cnt;
always_ff @(posedge clk) begin
    if (rst)
        unary_cnt <= 0;
    else begin
        unary_cnt <= {start, unary_cnt[7:1]};
    end
end

logic capture;
assign capture = ~unary_cnt[5];

logic [7:0] inst;
logic [7:0] pc;
always_ff @( posedge clk ) begin
    if (capture) begin
        pc <= fetch_program_counter_reg[7:0];
        inst <= fetch_instruction_reg[7:0];
    end
end

logic [7:0] leds0;
logic [7:0] leds1;

assign leds0 = {sw1_sync, sw2_sync, 1'b0, 1'b0, pc[3:0]};
assign leds1 = inst;
assign leds = {leds1, leds0};


//---------------------------
//-- Pruebas de pulsadores
//---------------------------


endmodule
