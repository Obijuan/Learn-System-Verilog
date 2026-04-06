module TB;
    // 1. Instanciamos la interfaz "física"
    simple_bus mi_bus();

    // 2. Conectamos Maestro y Esclavo al mismo bus
    master_mod u_maestro (.bus_if(mi_bus));
    slave_mod  u_esclavo (.bus_if(mi_bus));

    initial begin
        $dumpfile("sim.fst");
        $dumpvars;
        #20 $finish;
    end
endmodule



