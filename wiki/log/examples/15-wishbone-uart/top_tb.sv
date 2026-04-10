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



//-- Proceso de reloj
logic clk;
initial begin
    clk = 1;
    forever begin
        #(SIM_CLK_PERIOD / 2);
        clk = ~clk;
    end
end

//-- Proceso de reset
logic rst;
initial begin
    rst = 1;
    @(posedge clk);
    #(SIM_CLK_PERIOD/8);
    rst = 0;
end


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

//-- Instanciar los perifericos de LEDs
logic [7:0] leds;
logic [4:0] buttons;
logic [7:0] switches;


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

//-- Pines de la UART
logic uart_rx;
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
    .rx_serial_in(uart_rx),
    .tx_serial_out(uart_tx),
    .interrupt(uart_interrupt),
    .wishbone(mem_bus_slaves[3])
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


logic next;

logic E10; //-- cable del estado 1 al 0
logic E12; //-- cable del estado 1 al 2

//-- Evolucion del Estado del automata
always_ff @( posedge(clk) ) begin
    if (next) begin
        E0 <= E10;
        E1 <= E0;
        E2 <= E12; 
    end
end

//-- Transiciones
logic T01;
assign T01 = E0 && mem_bus.ack;

logic T10;
assign T10 = E1 && (rx_full==0); 

logic T12;
assign T12 = E1 && (rx_full);

//-- Pasar al siguiente estado
assign next = T01 || T10 || T12;

//-- Leer el registro de stado del receptor
logic rx_full;
logic [7:0] rx_byte;
always_ff @( posedge(clk) ) begin
    if (T01) begin
        rx_full <= mem_bus.dat_miso[18];

        //-- Este valor solo es valido cuando rx_full==1
        rx_byte <= mem_bus.dat_miso[7:0];
    end
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


//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    buttons = 5'b00001;
    switches = 8'h1;
    uart_rx = 0;  //-- START BIT
    
    //-- Esperar al bit de START
    repeat (CLKS_PER_BIT) @(posedge clk);

    //-- BIT 0
    uart_rx = 1;

    repeat (CLKS_PER_BIT*9) @(posedge clk);

    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    //$display("Valor de los pulsadores: %b", buttons);
    $finish();
end

endmodule

