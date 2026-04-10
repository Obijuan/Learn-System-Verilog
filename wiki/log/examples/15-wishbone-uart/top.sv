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

    //-- Switches
    input logic D13,
    input logic D12,

    //-- SERIAL PORT
    //output logic TX,
    input  logic RX,

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


logic [7:0] leds;

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = leds;

logic [4:0] buttons;

//-- 4-2: empty bottons. Not available in Alhambra-II
assign buttons[4:2] = 3'b0;

//-- 7-2: Empty switches. Not used
logic [7:0] switches;
assign switches[7:2] = 6'b0;

//-- Cable de recepcion serie
logic rx_serial_in;

//-- Reloj del sistema
logic clk;
assign clk = CLK;

//-- Pulsador de reset
logic rst;
assign rst = 0;

//----------- Conexion de perifericos a traves del wishbone

//-- Bus de acceso a perifericos
wishbone_interface mem_bus();

//------------- PERIFERICOS

//-- Buses para los esclavos
wishbone_interface mem_bus_slaves[4]();

//-- Puerto de LEDs
localparam bit [31:0] LEDS_START = 32'h0008_0000;
localparam bit [31:0] LEDS_SIZE  = 32'h0000_0001;

//-- Puerto de pulsadores
localparam bit [31:0] BUTTONS_START = 32'h0008_1000;
localparam bit [31:0] BUTTONS_SIZE = 32'h0000_0001;

//-- Puerto de switches
localparam bit [31:0] SWITCHES_START = 32'h0008_2000;
localparam bit [31:0] SWITCHES_SIZE = 32'h0000_0001;

//-- UART
localparam bit [31:0] UART_START = 32'h0008_4000;
localparam bit [31:0] UART_SIZE  = 32'h0000_0001;


wishbone_interconnect #(
        .NUM_SLAVES(4),
        .SLAVE_ADDRESS({
            LEDS_START,
            BUTTONS_START,
            SWITCHES_START,
            UART_START
        }),
        .SLAVE_SIZE({
            LEDS_SIZE,
            BUTTONS_SIZE,
            SWITCHES_SIZE,
            UART_SIZE
        })
    ) peripheral_bus_interconnect (
        .clk(clk),
        .rst(rst),
        .master(mem_bus),
        .slaves(mem_bus_slaves)
);


//----------------------- Instanciar los perifericos de LEDs

//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(LEDS_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds (
    .clk(clk),
    .rst(rst),

    .leds(), //-- TODO: LEDS disconnected!

    .wishbone(mem_bus_slaves[0])
);

//-- Instanciar modulo de pulsadores
wishbone_buttons #(
    .ADDRESS(BUTTONS_START),
    .SIZE(BUTTONS_SIZE)
) u_wishbone_buttons (
    .clk(clk),
    .rst(rst),

    .buttons(buttons),

    .wishbone(mem_bus_slaves[1])
);

//-- Instanciar modulo de switches
wishbone_switches #(
    .ADDRESS(SWITCHES_START),
    .SIZE(SWITCHES_SIZE)
) u_wishbone_switches (
    .clk(clk),
    .rst(rst),

    .switches(switches),

    .wishbone(mem_bus_slaves[2])
);

//-- Pines de la UART
logic uart_tx;
logic uart_interrupt;


wishbone_uart #(
    .ADDRESS(UART_START),
    .SIZE(UART_SIZE),
    .BAUD_RATE(UART_BAUD_RATE),
    .CLK_FREQUENCY_MHZ(CLK_FREQUENCY_MHZ)
) wb_uart (
    .clk(clk),
    .rst(rst),
    .rx_serial_in(rx_serial_in),
    .tx_serial_out(uart_tx),
    .interrupt(uart_interrupt),
    .wishbone(mem_bus_slaves[3])
);





//-- Instanciar los sincronizadores
synchronizer u_sync1 (
    .clk(clk),
    .async_in(SW1),
    .sync_out(buttons[0])
);

synchronizer u_sync2 (
    .clk(clk),
    .async_in(SW2),
    .sync_out(buttons[1])
);

synchronizer u_sync3 (
    .clk(clk),
    .async_in(D13),
    .sync_out(switches[0])
);

synchronizer u_sync4 (
    .clk(clk),
    .async_in(D12),
    .sync_out(switches[1])
);

synchronizer u_sync5 (
    .clk(clk),
    .async_in(RX),
    .sync_out(rx_serial_in)
);






//----------------------------------------------
//-- AUTOMATA DE CONTROL
//----------------------------------------------
logic E0 = 1;  //-- READ RX_STATUS
logic E1 = 0;  //-- Check RX_FULL (¿Caracter recibido?)
logic E2 = 0;  //-- Write leds


logic next;

logic E10; //-- cable del estado 1 al 0
logic E12; //-- cable del estado 1 al 2

//-- Evolucion del Estado del automata
always_ff @( posedge(clk) ) begin
    if (next) begin
        E0 <= E10 || E2;
        E1 <= E0;
        E2 <= E12; 
    end
end

logic rx_full;

//-- Transiciones
logic T01;
assign T01 = E0 && mem_bus.ack;

logic T10;
assign T10 = E1 && (rx_full==0); 

logic T12;
assign T12 = E1 && (rx_full);

logic T20;
assign T20 = E2;

//-- Pasar al siguiente estado
assign next = T01 || T10 || T12 || T20;

//-- Leer el registro de stado del receptor

logic [7:0] rx_byte;
always_ff @( posedge(clk) ) begin
    if (T01) begin
        rx_full <= mem_bus.dat_miso[18];

        //-- Este valor solo es valido cuando rx_full==1
        rx_byte <= mem_bus.dat_miso[7:0];
    end
end

//-- Mostrar en los leds
always_ff @( posedge(clk) ) begin
    if (T12)
        leds <= rx_byte;
end

//-- Demultiplexor de salida del estado E1
always_comb begin
    if (rx_full) begin
        E12 = E1;
        E10 = 0;
    end
    else begin
        E12 = 0;
        E10 = E1;
    end
end

//--- Generar las señales del estado actual
always_comb begin

    //-- Señales por defecto
    mem_bus.cyc = 0;
    mem_bus.stb = 0;
    mem_bus.adr = 32'h0;
    mem_bus.we = 0;
    mem_bus.sel = 4'b1111;
    mem_bus.dat_mosi = 32'h0;

    //-- Lectura del registro de estado RX de la uart
    if (E0) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 0;
        mem_bus.adr = UART_START;
    end
    else if (E1) begin
        //-- rx_full esta disponible

    end
    else if (E2) begin
        
    end
end

//-- Mostrar el dato capturado en los leds
//assign {D7, D6, D5, D4, D3, D2, D1, D0} = rx_byte;
assign {D7, D6, D5} = {E0, E1, E2};


endmodule

