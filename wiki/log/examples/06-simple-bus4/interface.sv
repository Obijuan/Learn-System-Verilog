
interface simple_bus;
    logic [7:0] data;
    logic       valid;

    // El Maestro ENVÍA datos y señal de validez
    modport master (
        output data, 
        output valid);

    // El Esclavo RECIBE datos y señal de validez
    modport slave  (
        input data, 
        input valid);
endinterface



