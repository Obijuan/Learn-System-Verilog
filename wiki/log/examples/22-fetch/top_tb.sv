module TB;

//------- SOLO SIMULACION -----------------------
import constants::SIM_CLK_PERIOD;

//-- Proceso de reloj
logic clk;
initial begin
    clk = 1;
    forever begin
        #(SIM_CLK_PERIOD / 2);
        clk = ~clk;
    end
end



//-----------------------------------------------------------
//---------- COMUN SINTESIS - SIMULACION --------------------
//-----------------------------------------------------------

//-- Reloj para la memoria
logic clk_mem;
assign clk_mem = ~clk;

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

//-- Acceso a la memoria
wishbone_interface fetch_bus();
wishbone_interface mem_bus();

//------------------------------------------
//-- PERIFERICOS
//------------------------------------------
import constants::MEMORY_START;
import constants::MEMORY_SIZE;

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




//----------------------------
//-- TEST
//-----------------------------
//-- Valores para las pruebas
localparam bit [7:0] VALUE0 = 8'hAA;
localparam bit [7:0] VALUE1 = 8'hBB;

logic [7:0] leds0;
logic [7:0] leds1;

assign leds0 = VALUE0;
assign leds1 = VALUE1;



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

    //-- Esperar a que finalice el reset
    repeat (32) @(posedge clk);

    @(posedge clk);

    //-- Ciclos de ejecucion
    repeat (10) @(posedge clk);


    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    $finish();
end

endmodule

