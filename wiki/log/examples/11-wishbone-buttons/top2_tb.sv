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

//-- AUTOMATA para leer pulsadores y mostrar su valor en los LEDs
logic E0 = 1;  //-- Estado inicial: Lectura botones
logic E1 = 0;  //-- Lectura completada!
logic E2 = 0;  //-- Inicio escritura en leds
logic E3 = 0;  //-- Escritura compeltada!
logic next;

logic T01;
assign T01 = E0 && mem_bus.ack;

logic T12;
assign T12 = E1;

logic T23;
assign T23 = E2 && mem_bus.ack;

logic T31;
assign T31 = E3;

//-- Registro intermedio con el valor de los botones
logic [4:0] btn_reg;
logic capture;
always_ff @( posedge clk ) begin 
    if (T01)
        btn_reg <= mem_bus.dat_miso[4:0];
end



always_ff @( posedge clk ) begin 
    if (next) begin
        E0 <= E3;
        E1 <= E0;
        E2 <= E1;
        E3 <= E2;
    end
end



//-- Calculo del siguiente estado
always_comb begin
    if (T01 || T12 || T23 || T31) begin
        next = 1;
    end
    else
        next = 0;
    
end


//-- Valor de las señales en el estado actual
always_comb begin

    //-- Valor por defecto de las señales
    mem_bus.cyc = 0;
    mem_bus.sel = 4'b0;
    mem_bus.stb = 0;
    mem_bus.adr = 32'h0;
    mem_bus.dat_mosi = 32'h0;
    mem_bus.we = 0;

    //-- E0: Inicio lectura de botones
    if (E0) begin
        mem_bus.cyc = 1;
        mem_bus.sel = 4'b0001;
        mem_bus.stb = 1;
        mem_bus.adr = BUTTONS_START;
        mem_bus.we = 0;
    end
    else if (E1) begin
        //-- wait...
    end
    else if (E2) begin
        //-- E2: Escritura en los leds
        mem_bus.cyc = 1;
        mem_bus.sel = 4'b0001;
        mem_bus.stb = 1;
        mem_bus.adr = LEDS_START;
        mem_bus.we = 1;
        mem_bus.dat_mosi = {27'b0, btn_reg};
    end
    else if (E3) begin
       //-- wait...
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

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    //-- Valor para los pulsadores;
    buttons = 5'b00010;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    buttons = 5'b00011;

    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);


    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    $display("Valor de los pulsadores: %b", buttons);
    $finish();
end

endmodule

