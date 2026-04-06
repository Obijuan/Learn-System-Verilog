module TB;
    

    //-- Proceso de reloj
    logic clk;
    initial begin
        clk = 1;
        forever begin
            #1;
            clk = ~clk;
        end
    end

    //-- Instanciar el bus
    simple_bus mi_bus();

    //-- Interconectar el maestro y el esclavo a través del bus
    master_mod u_maestro (
        .bus_if(mi_bus)
    );


    logic [7:0] led;
    slave_mod  u_esclavo (
        .clk(clk),
        .bus_if(mi_bus),
        .led(led)
    );

    initial begin
        $dumpfile("sim.fst");
        $dumpvars;
        #20 $finish;
    end
endmodule



