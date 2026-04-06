// Módulo Maestro: Pone un valor en el bus
module master_mod (simple_bus.master bus_if);
    initial begin
        #10;
        bus_if.data  = 32'hDEADBEEF;
        bus_if.valid = 1'b1;
    end
endmodule

// Módulo Esclavo: Solo mira lo que llega
module slave_mod (simple_bus.slave bus_if);
    always_comb begin
        if (bus_if.valid)
            $display("Esclavo recibió: %h", bus_if.data);
    end
endmodule



