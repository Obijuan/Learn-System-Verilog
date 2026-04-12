module TB;

//-- Parametros del reloj
localparam real SYS_CLK_FREQ_MHZ = 12;
localparam real SYS_CLK_PERIOD_PS = (1 / SYS_CLK_FREQ_MHZ)*1000*1000;
localparam int  SIM_CLK_PERIOD = int'(SYS_CLK_PERIOD_PS);
localparam real CLK_FREQUENCY_MHZ = SYS_CLK_FREQ_MHZ;

//-- Parametros para la UART
localparam int UART_BAUD_RATE = 115200;
localparam int CLKS_PER_BIT =
    int'(CLK_FREQUENCY_MHZ*1_000_000.0/UART_BAUD_RATE);


//------- SOLO SIMULACION -----------------------

//-- Proceso de reloj
logic clk;
initial begin
    clk = 1;
    forever begin
        #(SIM_CLK_PERIOD / 2);
        clk = ~clk;
    end
end
//------------------------------------------------


//-----------------------------------------------------------
//---------- COMUN SINTESIS - SIMULACION --------------------
//-----------------------------------------------------------

//-- Cables para los perifericos
logic [7:0] leds;
logic [4:0] buttons;
logic [7:0] switches;

//-- PINES
logic sw1;
logic sw2;
logic d13;
logic d12;
logic rx;
logic tx;

logic sw1_sync;
logic sw2_sync;
logic d13_sync;
logic d12_sync;
logic rx_sync;

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

logic rx_full;
logic tx_empty;
logic uart_interrupt;


//----------- Conexion de perifericos a traves del wishbone

//-- Bus de acceso a perifericos
wishbone_interface fetch_bus();
wishbone_interface mem_bus();

//------------- PERIFERICOS

//-- Buses para los esclavos
wishbone_interface mem_bus_slaves[5]();

//-- Memoria RAM
localparam bit [31:0] MEMORY_START = 32'h0001_0000;
localparam bit [31:0] MEMORY_SIZE  = 32'h0000_2000;

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


//-- Instanciar los sincronizadores
synchronizer u_sync1 (
    .clk(clk),
    .async_in(sw1),
    .sync_out(buttons[0])
);

synchronizer u_sync2 (
    .clk(clk),
    .async_in(sw2),
    .sync_out(buttons[1])
);

synchronizer u_sync3 (
    .clk(clk),
    .async_in(d13),
    .sync_out(switches[0])
);

synchronizer u_sync4 (
    .clk(clk),
    .async_in(d12),
    .sync_out(switches[1])
);

synchronizer u_sync5 (
    .clk(clk),
    .async_in(rx),
    .sync_out(rx_sync)
);



wishbone_interconnect #(
        .NUM_SLAVES(5),
        .SLAVE_ADDRESS({
            LEDS_START,
            BUTTONS_START,
            SWITCHES_START,
            UART_START,
            MEMORY_START
        }),
        .SLAVE_SIZE({
            LEDS_SIZE,
            BUTTONS_SIZE,
            SWITCHES_SIZE,
            UART_SIZE,
            MEMORY_SIZE
        })
    ) peripheral_bus_interconnect (
        .clk(clk),
        .rst(rst),
        .master(mem_bus),
        .slaves(mem_bus_slaves)
);


//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(LEDS_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds (
    .clk(clk),
    .rst(rst),
    .leds(leds),
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

//-- Modulo de la UART
wishbone_uart #(
    .ADDRESS(UART_START),
    .SIZE(UART_SIZE),
    .BAUD_RATE(UART_BAUD_RATE),
    .CLK_FREQUENCY_MHZ(CLK_FREQUENCY_MHZ)
) wb_uart (
    .clk(clk),
    .rst(rst),
    .rx_serial_in(rx_sync),
    .tx_serial_out(tx),
    .interrupt(uart_interrupt),
    .wishbone(mem_bus_slaves[3])
);

//-- MEMORIA RAM
wishbone_ram #(
    .ADDRESS(MEMORY_START),
    .SIZE(MEMORY_SIZE)
) u_whisbone_ram (
    .clk(clk_mem),
    .rst(rst),
    .port_a(fetch_bus.slave),
    .port_b(mem_bus_slaves[4])
);



//----------------------------------------------
//-- AUTOMATA DE CONTROL
//----------------------------------------------
logic E0 = 1;  //-- READ RX_STATUS
logic E1 = 0;  //-- Check RX_FULL (¿Caracter recibido?)
logic E2 = 0;  //-- Write leds
logic E3 = 0;  //-- Transmit
logic E4 = 0;  //-- READ TX_STATUS
logic E5 = 0;  //-- Check Tx_EMPTY
logic E6 = 0;  //-- Read buttons
logic E7 = 0;  //-- Read switches
logic E8 = 0;  //-- Leer memoria
logic E9 = 0;  //-- Escritura en memoria


logic next;

logic E10; //-- cable del estado 1 al 0
logic E12; //-- cable del estado 1 al 2
logic E56; //-- Cable del estado 5 al 6
logic E54; //-- Cable del estado 5 al 4

//-- Evolucion del Estado del automata
always_ff @( posedge(clk) ) begin
    if (rst) begin
        E0 <= 1;
        E1 <= 0;
        E2 <= 0;
        E3 <= 0;
        E4 <= 0;
        E5 <= 0;
        E6 <= 0;
        E7 <= 0;
        E8 <= 0;
        E9 <= 0;
    end
    else if (next) begin
        E0 <= E10  || E9;
        E1 <= E0;
        E2 <= E12; 
        E3 <= E2;
        E4 <= E3 || E54;
        E5 <= E4;
        E6 <= E56;
        E7 <= E6;
        E8 <= E7;
        E9 <= E8;
    end
end

//-- Transiciones
logic T01;
assign T01 = E0 && mem_bus.ack;

logic T10;
assign T10 = E1 && (rx_full==0); 

logic T12;
assign T12 = E1 && (rx_full);

logic T23;
assign T23 = E2 && mem_bus.ack;

logic T34;
assign T34 = E3 && mem_bus.ack;

logic T45;
assign T45 = E4 && mem_bus.ack;

logic T54;
assign T54 = E5 && (tx_empty==0);

logic T56;
assign T56 = E5 && (tx_empty);

logic T67;
assign T67 = E6 && mem_bus.ack;

logic T78;
assign T78 = E7 && mem_bus.ack;

logic T89;
assign T89 = E8 && mem_bus.ack;

logic T90;
assign T90 = E9 && mem_bus.ack;

//-- Pasar al siguiente estado
assign next = T01 || T10 || T12 || T23  || T34 || T45 ||
              T54 || T56 || T67 || T78 || T89 || T90;

//-- Leer el registro de stado del receptor
logic [7:0] rx_byte;
always_ff @( posedge(clk) ) begin
    if (T01) begin
        rx_full <= mem_bus.dat_miso[18];

        //-- Este valor solo es valido cuando rx_full==1
        rx_byte <= mem_bus.dat_miso[7:0];
    end
end

//-- Leer registro de estado del transmisor
always_ff @( posedge(clk) ) begin
    if (T45) begin
        tx_empty <= mem_bus.dat_miso[26];
    end
end

//-- Leer los pulsadores
logic [4:0] read_buttons;
always_ff @( posedge(clk) ) begin
    if (T67)
        read_buttons <= mem_bus.dat_miso[4:0];
end

//-- Leer los switches
logic [7:0] read_switches;
always_ff @( posedge(clk) ) begin
    if (T78)
        read_switches <= mem_bus.dat_miso[7:0];
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

//-- Demultiplexor de salida del estado E4
always_comb begin
    if (tx_empty) begin
        E56 = E5;
        E54 = 0;
    end 
    else begin
        E56 = 0;
        E54 = E5;
    end
end

//-- Capturar la lectura de memoria
logic [31:0] read_mem;
always_ff @( posedge(clk) ) begin
    if (T89) begin
        read_mem <= mem_bus.dat_miso;
        //read_mem <= fetch_bus.dat_miso;
    end
end

//-- Contador de direcciones
logic [31:0] adr_cnt;
always_ff @( posedge(clk) ) begin
    if (rst)
        adr_cnt <= (MEMORY_START);
    else if (T90)
        adr_cnt <= adr_cnt + 1;
end

//-- Contador de valores
logic [7:0] mem_value;
always_ff @( posedge(clk) ) begin
    if (rst)
        mem_value <= 8'hA0;
    else if (T90)
        mem_value <= mem_value + 1;
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

    //-- Check RX_FULL
    else if (E1) begin
        //-- rx_full esta disponible

    end

    //-- Write Leds
    else if (E2) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 1;
        mem_bus.adr = LEDS_START;
        mem_bus.dat_mosi = {24'b0, rx_byte};
    end

    //-- Transmit! (eco)
    else if (E3) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 1;
        mem_bus.adr = UART_START;
        mem_bus.dat_mosi = {24'b0, rx_byte};
    end

    //-- Lectura de TX_EMPTY para saber cuando se ha completado
    //-- la transmision
    else if (E4) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 0;
        mem_bus.adr = UART_START;
    end
    else if (E5) begin
        //-- tx_empy esta disponible
    end

    //-- Lectura de los pulsadores
    else if (E6) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 0;
        mem_bus.adr = BUTTONS_START;
    end

    //-- Lectura de los switches
    else if (E7) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 0;
        mem_bus.adr = SWITCHES_START;
    end

    //-- Lectura de memoria
    else if (E8) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 0;
        mem_bus.sel = 4'b1111;
        mem_bus.adr = adr_cnt;
    end

    //-- Escritura en memoria
    else if (E9) begin
        mem_bus.cyc = 1;
        mem_bus.stb = 1;
        mem_bus.we = 1;
        mem_bus.sel = 4'b1111;
        mem_bus.adr = adr_cnt + 2;
        mem_bus.dat_mosi = {24'h0, mem_value};
    end
end

//------- Lectura de la memoria a traves del puerto de fetch
always_comb begin
    fetch_bus.cyc = 1;
    fetch_bus.stb = 1;
    fetch_bus.we = 0;
    fetch_bus.sel = 4'b1111;
    fetch_bus.adr = adr_cnt;
end

logic [31:0] read_mem_fetch;
assign read_mem_fetch = fetch_bus.dat_miso;


//---------------------------------------------------------
//----------------- SOLO SIMULACION -----------------------
//---------------------------------------------------------

//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    repeat (3) begin
        sw1 = 1;
        sw2 = 0;
        d13 = 1;
        d12 = 0;

        rx = 0;  //-- START BIT
        
        //-- Esperar al bit de START
        repeat (CLKS_PER_BIT) @(posedge clk);

        //-- BIT 0
        rx = 1;

        repeat (CLKS_PER_BIT*9) @(posedge clk);

        repeat (20) @(posedge clk);
    end

    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    //$display("Valor de los pulsadores: %b", buttons);
    $finish();
end

endmodule

