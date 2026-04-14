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
    .wb(fetch_bus), // ✅

    //-- Output data
    .instruction_reg_out(fetch_instruction_reg), // ✅
    .program_counter_reg_out(fetch_program_counter_reg), // ✅

    //-- Pipeline control
    .status_forwards_out(fetch_status_forwards), // ✅
    .status_backwards_in(decode_status_backwards), // ✅
    .jump_address_backwards_in(decode_jump_address_backwards) // ✅
);

//-----------------------------------------------
//-- DECODE STAGE
//-----------------------------------------------

//-- Forwarding
forwarding::t wb_forwarding;
forwarding::t mem_forwarding;
forwarding::t exe_forwarding;

//-- Output signals
instruction::t decode_instruction_reg;
logic [31:0] decode_program_counter_reg;
logic [31:0] rs1_data_reg;
logic [31:0] rs2_data_reg;

//-- Pipeline control
pipeline_status::forwards_t decode_status_forwards;
pipeline_status::backwards_t exe_status_backwards;
logic [31:0] exe_jump_address_backwards;


decode_stage u_decode(
    .clk(clk),
    .rst(rst),

    //--- Inputs
    .instruction_in(fetch_instruction_reg),  // ✅
    .program_counter_in(fetch_program_counter_reg), // ✅

    //-- Forwarding
    .wb_forwarding_in(wb_forwarding),  // ❌
    .mem_forwarding_in(mem_forwarding), // ❌
    .exe_forwarding_in(exe_forwarding), // ❌
    
    //-- Output Registers
    .instruction_reg_out(decode_instruction_reg), // ❌
    .program_counter_reg_out(decode_program_counter_reg), // ❌
    .rs1_data_reg_out(rs1_data_reg), // ❌
    .rs2_data_reg_out(rs2_data_reg), // ❌

    //-- Pipeline control
    .status_forwards_in(fetch_status_forwards), // ✅ 
    .status_forwards_out(decode_status_forwards), // ❌
    .status_backwards_in(exe_status_backwards), // ❌
    .status_backwards_out(decode_status_backwards), // ✅
    .jump_address_backwards_in(exe_jump_address_backwards), // ❌
    .jump_address_backwards_out(decode_jump_address_backwards) // ✅
);

//---------------------------------------------
//-- Conexiones para probar la etapa decode
//---------------------------------------------
assign exe_forwarding.data_valid = 0;
assign exe_forwarding.data = 32'h0;
assign exe_forwarding.address = 5'h0;

assign mem_forwarding.data_valid = 0;
assign mem_forwarding.data = 32'h0;
assign mem_forwarding.address = 5'h0;

assign wb_forwarding.data_valid = 0;
assign wb_forwarding.data = 32'h0;
assign wb_forwarding.address = 5'h0;


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

//-- No hay salto en las etapas posteriores
assign exe_jump_address_backwards = 32'h0;

//-- Señal de comienzo. El micro ya NO está en reset
logic start;
assign start = rst_cnt[5];

//-- Debug: Decod. Para la depuracion de la fase de decodificacion
//-- se usa la señal start2 que arranca en cuanto la etapa
//-- de decodificacion sale de la burbuja
logic start2;
assign start2 = start && (fetch_status_forwards==pipeline_status::VALID);

logic [7:0] leds0;
logic [7:0] leds1;

assign leds0 = decode_program_counter_reg[7:0];
assign leds1 = {2'b00, decode_instruction_reg.op[5:0]};
assign leds = {leds1, leds0};


//---------------------------
//-- Pruebas de pulsadores
//---------------------------

//-- Detector de flanco de subida en sw1
logic sw1_click;
posedge_detector u_sw1_click (
    .clk(clk),
    .value(sw1_rdy),
    .pos_edge(sw1_click)
);


//---------------------------------------
//-- AUTOMATA DE PRUEBA para Fetch
//---------------------------------------
logic INIT = 1; //-- INIT: esperar señal start para arrancar
logic E0 = 0;  //-- E0: STALL
logic E1 = 0;  //-- E1: READY

//-- Estado
logic next;
always_ff @( posedge clk ) begin
    if (rst) begin
        INIT <= 1;
        E0 <= 0;
        E1 <= 0;
    end
    else if (next) begin
        INIT <= 0;
        E0 <= E1 || INIT;
        E1 <= E0;
    end
end

//-- Transiciones
logic T_INIT;
assign T_INIT = INIT && start2;

logic T01;
assign T01 = E0 && sw1_click;

logic T10;
assign T10 = E1;

assign next = T_INIT || T01 || T10;

//-- Salidas del automata
always_comb begin

    //-- Salidas por defecto
    exe_status_backwards = pipeline_status::READY;

    if (INIT) begin
        exe_status_backwards = pipeline_status::READY;
    end
    else if (E0) begin
        exe_status_backwards = pipeline_status::STALL;
    end
    else if (E1) begin
        exe_status_backwards = pipeline_status::READY;
    end
end

endmodule
