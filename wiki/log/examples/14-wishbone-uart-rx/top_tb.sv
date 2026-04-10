module TB;

//-- Parametros del reloj
localparam real SYS_CLK_FREQ_MHZ = 12;
localparam real SYS_CLK_PERIOD_PS = (1 / SYS_CLK_FREQ_MHZ)*1000*1000;
localparam int  SIM_CLK_PERIOD = int'(SYS_CLK_PERIOD_PS);
localparam real CLK_FREQUENCY_MHZ = SYS_CLK_FREQ_MHZ;

//-- Parametros para la UART
localparam int BAUD_RATE = 115200;
localparam int CLKS_PER_BIT =int'(CLK_FREQUENCY_MHZ*1_000_000.0/BAUD_RATE);

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
wishbone_interface mem_bus_slaves[3]();

//-- Puerto de LEDs
localparam bit [31:0] LEDS_START = 32'h0008_0000;
localparam bit [31:0] LEDS_SIZE  = 32'h0000_0001;

//-- Puerto de pulsadores
localparam bit [31:0] BUTTONS_START = 32'h0008_1000;
localparam bit [31:0] BUTTONS_SIZE = 32'h0000_0001;

//-- Puerto de switches
localparam bit [31:0] SWITCHES_START = 32'h0008_2000;
localparam bit [31:0] SWITCHES_SIZE = 32'h0000_0001;

wishbone_interconnect #(
        .NUM_SLAVES(3),
        .SLAVE_ADDRESS({
            LEDS_START,
            BUTTONS_START,
            SWITCHES_START
        }),
        .SLAVE_SIZE({
            LEDS_SIZE,
            BUTTONS_SIZE,
            SWITCHES_SIZE
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


//------------ Instanciar el transmisor de la UART
logic tx_start;
logic [7:0] tx_byte;
logic tx_serial_out;
logic tx_done;
logic tx_active;

uart_tx #(
   .CLKS_PER_BIT(CLKS_PER_BIT)
) u_tx (
    .clk(clk),
    .rst(rst),

    // Input signals
    .tx_start_in(tx_start),
    .tx_byte_in(tx_byte),

    // Output signals
    .tx_serial_out(tx_serial_out),
    .tx_done_out(tx_done),
    .tx_active_out(tx_active)
);


//-- Pruebas de transmisión
assign tx_byte = 8'hAA;
assign tx_start = 1;


//------------- Instanciar el receptor de la UART
logic rx_serial_in;
logic [7:0] rx_byte;
logic rx_done;
logic rx_error;

uart_rx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) u_rx (
    .clk(clk),
    .rst(rst),

    // Serial input
    .rx_serial_in(rx_serial_in),

    // Output signals
    .rx_byte_out(rx_byte),
    .rx_done_out(rx_done),
    .rx_error_out(rx_error)
);


//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    buttons = 5'b00001;
    switches = 8'h1;
    rx_serial_in = 0;  //-- START BIT

    //-- Esperar al bit de START
    repeat (CLKS_PER_BIT) @(posedge clk);

    //-- BIT 0
    rx_serial_in = 1;

    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);
    repeat (CLKS_PER_BIT) @(posedge clk);

    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    //$display("Valor de los pulsadores: %b", buttons);
    $finish();
end

endmodule

