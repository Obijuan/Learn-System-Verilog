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

logic [7:0] data;
logic [7:0] led;
logic wen;

//-- Instanciar el modulo a probar
leds_port UUT(
    .clk(clk),
    .rst(rst),

    .data_in(data),
    .wen(wen),

    .led(led)
);




//-- Proceso de simulacion
initial begin
    //-- Generacion del volcado de ondas
    //$_dumpfile("sim.fst");
    $dumpvars;

    //-- Indicar comienzo simmulacion
    $display("Inicio: %t", $time);

    //-- Esperar 2 ciclos de reloj
    @(negedge clk);
    @(negedge clk);

    data = 8'h1;
    wen = 1;
    @(negedge clk);

    data = 8'hAA;
    @(negedge clk);

    data = 8'h55;
    @(negedge clk);



    @(posedge clk);
    @(posedge clk);
    @(posedge clk);

    //-- Indicar fin simulacion
    $display("Fin: %t", $time);
    $display("Valor de los LEDs: %b", led);
    $finish();
end

endmodule

