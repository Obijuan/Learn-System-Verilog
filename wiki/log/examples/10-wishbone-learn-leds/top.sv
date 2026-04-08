module top(
    input logic CLK,
    input logic SW1,
    input logic SW2,

    //-- Puerto 0 de leds
    output logic LED7,
    output logic LED6,
    output logic LED5,
    output logic LED4,
    output logic LED3,
    output logic LED2,
    output logic LED1,
    output logic LED0,

    //-- Puerto 1 de leds
    output logic D7,
    output logic D6,
    output logic D5,
    output logic D4,
    output logic D3,
    output logic D2,
    output logic D1,
    output logic D0
);

logic [7:0] led0;
logic [7:0] led1;

assign {LED7, LED6, LED5, LED4, 
        LED3, LED2, LED1, LED0} = led0[7:0];

assign {D7, D6, D5, D4,
        D3, D2, D1, D0} = led1[7:0];

//-- Reloj del sistema
logic clk;
assign clk = CLK;

//-- Pulsador de reset
logic rst;
assign rst = SW1;

//----------- Conexion de perifericos a traves del wishbone

//-- Bus de acceso a perifericos
wishbone_interface mem_bus();

//------------- PERIFERICOS

//-- Dos puertos de leds de 8 bits
wishbone_interface mem_bus_slaves[2]();

localparam bit [31:0] LEDS0_START = 32'h0008_0000;
localparam bit [31:0] LEDS1_START = 32'h0008_0001;
localparam bit [31:0] LEDS_SIZE  = 32'h0000_0001;

wishbone_interconnect #(
        .NUM_SLAVES(2),
        .SLAVE_ADDRESS({
            LEDS0_START,
            LEDS1_START
        }),
        .SLAVE_SIZE({
            LEDS_SIZE,
            LEDS_SIZE
        })
    ) peripheral_bus_interconnect (
        .clk(clk),
        .rst(0),
        .master(mem_bus),
        .slaves(mem_bus_slaves)
    );

//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(LEDS0_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds0 (
    .clk(clk),
    .rst(0),

    .leds(led0),

    .wishbone(mem_bus_slaves[0])
);

//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(LEDS1_START),
    .SIZE(LEDS_SIZE)
) u_wishbone_leds1 (
    .clk(clk),
    .rst(0),

    .leds(led1),

    .wishbone(mem_bus_slaves[1])
);


//-- Escribir un valor en el puerto 0 de leds
assign mem_bus.cyc = 1;
assign mem_bus.we  = 1;
assign mem_bus.sel = 4'b0001;
assign mem_bus.stb = 1;


//assign mem_bus.adr = 32'h0008_0001;  

always @(posedge clk) begin
    if (SW1) begin
        //-- Escribir en puerto 1
        mem_bus.adr = 32'h0008_0001;
        if (SW2)
            mem_bus.dat_mosi = 32'h0000_00AA;
        else
            mem_bus.dat_mosi = 32'h0000_0055;
    end
    else begin
        //-- Escribir en puerto 0
        mem_bus.adr = 32'h0008_0000;
        if (SW2)
            mem_bus.dat_mosi = 32'h0000_00F0;
        else
            mem_bus.dat_mosi = 32'h0000_000F;
    end
end



endmodule

