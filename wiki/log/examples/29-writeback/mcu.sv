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
import constants::LEDS_START;
import constants::LEDS_SIZE;

//-- Acceso a la memoria
wishbone_interface fetch_bus();
wishbone_interface mem_bus();

wishbone_interface mem_bus_slaves[2]();
wishbone_interconnect #(
    .NUM_SLAVES(2),
    .SLAVE_ADDRESS({
        MEMORY_START,
        LEDS_START
    }),
    .SLAVE_SIZE({
        MEMORY_SIZE,
        LEDS_SIZE
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


//--- Interrupciones
logic external_interrupt_in;
logic timer_interrupt_in;

assign external_interrupt_in = 0;
assign timer_interrupt_in = 0;



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
    .wb_forwarding_in(wb_forwarding),  // ✅
    .mem_forwarding_in(mem_forwarding), // ✅
    .exe_forwarding_in(exe_forwarding), // ✅
    
    //-- Output Registers
    .instruction_reg_out(decode_instruction_reg), // ✅
    .program_counter_reg_out(decode_program_counter_reg), // ✅
    .rs1_data_reg_out(rs1_data_reg), // ✅
    .rs2_data_reg_out(rs2_data_reg), // ✅

    //-- Pipeline control
    .status_forwards_in(fetch_status_forwards), // ✅ 
    .status_forwards_out(decode_status_forwards), // ✅
    .status_backwards_in(exe_status_backwards), // ✅
    .status_backwards_out(decode_status_backwards), // ✅
    .jump_address_backwards_in(exe_jump_address_backwards), // ✅
    .jump_address_backwards_out(decode_jump_address_backwards) // ✅
);

//---------------------------------------------
//-- Conexiones para probar la etapa decode
//---------------------------------------------

// assign mem_forwarding.data_valid = 0;
// assign mem_forwarding.data = 32'h0;
// assign mem_forwarding.address = 5'h0;

// assign wb_forwarding.data_valid = 0;
// assign wb_forwarding.data = 32'h0;
// assign wb_forwarding.address = 5'h0;

//-----------------------------------------------
//-- EXECUTE STAGE
//-----------------------------------------------

//-- Output signals
instruction::t exe_instruction_reg;
logic [31:0] exe_program_counter_reg;
logic [31:0] exe_next_program_counter_reg;
logic [31:0] exe_rd_data_reg;
logic [31:0] exe_source_data_reg;

//-- Pipeline control
pipeline_status::forwards_t exe_status_forwards;
pipeline_status::backwards_t mem_status_backwards;
logic [31:0] memory_jump_address_backwards;

execute_stage u_execute (
    .clk(clk),
    .rst(rst),

    // Inputs
    .rs1_data_in(rs1_data_reg), // ✅ 
    .rs2_data_in(rs2_data_reg), // ✅ 
    .instruction_in(decode_instruction_reg), // ✅ 
    .program_counter_in(decode_program_counter_reg), // ✅ 

    // Outputs
    .forwarding_out(exe_forwarding), // ✅
    .instruction_reg_out(exe_instruction_reg), // ✅
    .program_counter_reg_out(exe_program_counter_reg), // ✅
    .next_program_counter_reg_out(exe_next_program_counter_reg), // ✅
    .rd_data_reg_out(exe_rd_data_reg), // ✅
    .source_data_reg_out(exe_source_data_reg), // ✅
    
    // Pipeline control
    .status_forwards_in(decode_status_forwards), // ✅
    .status_forwards_out(exe_status_forwards), // ✅
    .status_backwards_in(mem_status_backwards), // ✅
    .status_backwards_out(exe_status_backwards), // ✅
    .jump_address_backwards_in(memory_jump_address_backwards), // ✅
    .jump_address_backwards_out(exe_jump_address_backwards)  // ✅
);


//--------------------------------------------------------
//-- MEMORY STAGE
//--------------------------------------------------------

//-- Output signals
instruction::t mem_instruction_reg;
logic [31:0] mem_program_counter_reg;
logic [31:0] mem_next_program_counter_reg;
logic [31:0] mem_source_data_reg;
logic [31:0] mem_rd_data_reg;

//-- Pipeline control signals
pipeline_status::forwards_t mem_status_forwards;
pipeline_status::backwards_t wb_status_backwards;
logic [31:0] wb_jump_address_backwards;

memory_stage u_memory (
    .clk(clk),
    .rst(rst),

    // Memory interface
    .wb(mem_bus),

    // Inputs
    .source_data_in(exe_source_data_reg), // ✅
    .program_counter_in(exe_program_counter_reg), // ✅
    .next_program_counter_in(exe_next_program_counter_reg), // ✅
    .rd_data_in(exe_rd_data_reg), // ✅
    .instruction_in(exe_instruction_reg), // ✅
    
    // Outputs
    .forwarding_out(mem_forwarding),  // ✅
    .instruction_reg_out(mem_instruction_reg), // ✅
    .program_counter_reg_out(mem_program_counter_reg), // ✅
    .next_program_counter_reg_out(mem_next_program_counter_reg), // ✅
    .source_data_reg_out(mem_source_data_reg), // ✅
    .rd_data_reg_out(mem_rd_data_reg), // ✅
    
    // Pipeline control
    .status_forwards_in(exe_status_forwards), // ✅
    .status_forwards_out(mem_status_forwards), // ✅
    .status_backwards_in(wb_status_backwards), // ✅
    .status_backwards_out(mem_status_backwards), // ✅
    .jump_address_backwards_in(wb_jump_address_backwards), // ✅
    .jump_address_backwards_out(memory_jump_address_backwards) // ✅
);

//--------------------------------------------------------
//-- WRITEBACK STAGE
//--------------------------------------------------------
writeback_stage u_writeback(
    .clk(clk),
    .rst(rst),

    // Inputs
    .source_data_in(mem_source_data_reg), // ✅
    .rd_data_in(mem_rd_data_reg), // ✅
    .instruction_in(mem_instruction_reg), // ✅
    .program_counter_in(mem_program_counter_reg), // ✅
    .next_program_counter_in(mem_next_program_counter_reg), // ✅

    // Interrupt signals
    .external_interrupt_in(external_interrupt_in), // ✅
    .timer_interrupt_in(timer_interrupt_in), // ✅

    // Outputs
    .forwarding_out(wb_forwarding), // ✅

    // Pipeline control
    .status_forwards_in(mem_status_forwards), // ✅
    .status_backwards_out(wb_status_backwards), // ✅
    .jump_address_backwards_out(wb_jump_address_backwards) // ✅
);

endmodule
