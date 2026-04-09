module TB;

//-- Parametros del reloj
localparam real SYS_CLK_FREQ_MHZ = 12;
localparam real SYS_CLK_PERIOD_PS = (1 / SYS_CLK_FREQ_MHZ)*1000*1000;
localparam int  SIM_CLK_PERIOD = int'(SYS_CLK_PERIOD_PS);

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

//-- Dos puertos de leds de 8 bits
wishbone_interface mem_bus_slaves[2]();

//-- Puerto de LEDs
localparam bit [31:0] LEDS_START = 32'h0008_0000;
localparam bit [31:0] LEDS_SIZE  = 32'h0000_0001;

//-- Puerto de pulsadores
localparam bit [31:0] BUTTONS_START = 32'h0008_1000;
localparam bit [31:0] BUTTONS_SIZE = 32'h0000_0001;

wishbone_interconnect #(
        .NUM_SLAVES(2),
        .SLAVE_ADDRESS({
            LEDS_START,
            BUTTONS_START
        }),
        .SLAVE_SIZE({
            LEDS_SIZE,
            BUTTONS_SIZE
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
assign buttons = 5'b00011;

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


//-- Registro que captura los pulsadores
logic [4:0] read_buttons;
logic capture;
always_ff @( posedge clk ) begin
    if (capture && mem_bus.ack)
        read_buttons <= mem_bus.dat_miso[4:0];
end

//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    //-- Inicialmente no capturamos nada
    capture = 0;

    //-- Esperar 2 ciclos de reloj
    @(posedge clk);
    @(posedge clk);

    @(negedge clk);
    //-- Lectura de los pulsadores
    mem_bus.cyc = 1;
    mem_bus.adr = BUTTONS_START;  
    mem_bus.sel = 4'b0001;
    mem_bus.stb = 1;
    mem_bus.we = 0;  //-- lectura

    @(posedge clk);

    //-- Capturar los pulsadores
    capture = 1;

    @(posedge clk);

    @(negedge clk);
    capture = 0;

    //-- Escribir valor en los leds
    mem_bus.adr = LEDS_START;
    mem_bus.we = 1;
    mem_bus.dat_mosi = {27'b0, read_buttons};

    @(posedge clk);

    @(posedge clk);

    if (mem_bus.ack == 1) begin
        mem_bus.we = 0;
        mem_bus.cyc = 0;
    end

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);


    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    $display("Valor de los pulsadores: %b", buttons);
    $finish();
end

endmodule

