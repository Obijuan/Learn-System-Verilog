//-- Ejemplo de interfaz
//-- El maestro envia datos al esclavo para encender los LEDs
interface led_interface;

    //-- Señales de la interfaz
    logic [7:0] data; //-- Valor a sacar por los LEDs
    logic valid; //-- Señal de validación de datos
    logic ack; //-- Señal de reconocimiento del esclavo

    //-- Direccion de las señales para el maestro
    modport master (
        output data,
        output valid,
        input ack
    );

    //-- Direccion de las señales para el esclavo
    modport slave (
        input data,
        input valid,
        output ack
    );

endinterface

