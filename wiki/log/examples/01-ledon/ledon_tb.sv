//`timescale 1ms / 1us  // Unidad de tiempo: 1ms, Precisión: 1us
//-- ledon: Ejemplo hola mundo
//-- Encender el LED0
module ledon_tb;

    //-- Señal de conexion
    logic led;

    //-- Instanciar modulo
    ledon UUT (
        .led0(led)
    );

    //-- Proceso de simulacion
    initial begin
        //-- Generacion del volcado de ondas
        $dumpfile("ledon_sim.fst");
        $dumpvars;

        //-- Indicar comienzo simmulacion
        $display("Inicio: %t", $time);

        //-- Esperar 1 unidad de tiempo
        #1ms

        //-- Indicar fin simulacion
        $display("Fin: %t", $time);
        $display("Valor del LED: %b", led);
        $finish();
    end


endmodule


