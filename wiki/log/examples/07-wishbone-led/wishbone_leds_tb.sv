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

//-- Instanciar interfaz
wishbone_interface wb_if();

logic [7:0] leds;

//-- Instanciar modulo de LEDs
wishbone_leds #(
    .ADDRESS(32'h0008_0000),
    .SIZE(1)
) u_wishbone_leds (
    .clk(clk),
    .rst(rst),

    .leds(leds),

    .wishbone(wb_if)
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

    wb_if.cyc = 1;
    wb_if.adr = 32'h0001_0000;  //-- Incorrect addr
    wb_if.we  = 1;
    wb_if.sel = 4'b0001;
    wb_if.dat_mosi = 32'h0000_00F3;
    wb_if.stb = 1;
    @(negedge clk);

    wb_if.adr = 32'h0008_0000;  //-- Correct addr
    @(negedge clk);

    
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

