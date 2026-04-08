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

localparam bit [31:0] LEDS0_START = 32'h0008_0000;
localparam bit [31:0] LEDS1_START = 32'h0008_0001;
localparam bit [31:0] LEDS_SIZE  = 32'h0000_0001;

wishbone_interconnect2 #(
        .SLAVE0_ADDRESS(LEDS1_START),
        .SLAVE1_ADDRESS(LEDS0_START),
        .SLAVE_SIZE({
            LEDS_SIZE,
            LEDS_SIZE
        })
    ) peripheral_bus_interconnect (
        .clk(clk),
        .rst(rst),
        .master(mem_bus),
        .slaves0(mem_bus_slaves[0]),
        .slaves1(mem_bus_slaves[1])
    );

//-- Instanciar los perifericos de LEDs
logic [7:0] leds0;  //-- Puerto 0
logic [7:0] leds1;  //-- Puerto 1

//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(LEDS0_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds0 (
    .clk(clk),
    .rst(rst),

    .leds(leds0),

    .wishbone(mem_bus_slaves[0])
);

//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(LEDS1_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds1 (
    .clk(clk),
    .rst(rst),

    .leds(leds1),

    .wishbone(mem_bus_slaves[1])
);

//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    $dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    //-- Esperar 2 ciclos de reloj
    @(negedge clk);
    @(negedge clk);

    mem_bus.cyc = 1;
    mem_bus.adr = 32'h0008_0000;  
    mem_bus.we  = 1;
    mem_bus.sel = 4'b0001;
    mem_bus.dat_mosi = 32'h0000_00aa;
    mem_bus.stb = 1;
    @(negedge clk);

    mem_bus.adr = 32'h0008_0001;  
    mem_bus.dat_mosi = 32'h0000_00bb;
    @(negedge clk);

    mem_bus.adr = 32'h0000_0001; //-- Incorrect
    @(negedge clk);



    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    //$display("Valor de los LEDs: %b", led);
    $finish();
end

endmodule

