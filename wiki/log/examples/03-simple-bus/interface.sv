
interface simple_bus;
    logic [31:0] data;
    logic        valid;

    // El Maestro ENVÍA datos y señal de validez
    modport master (output data, valid);

    // El Esclavo RECIBE datos y señal de validez
    modport slave  (input  data, valid);
endinterface




