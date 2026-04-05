//-- Modulo leds_port.sv
//-- Puerto de salida de 8 leds

module leds_port(
    input logic clk,
    input logic rst,

    input logic [7:0] data_in,
    input logic wen,

    output logic [7:0] led
);

    //-- Registro para almacenar el valor de los leds
    always_ff @(posedge clk) begin
        if (rst) begin
            led <= 8'b0;
        end else if (wen) begin
            led <= data_in;
        end
    end

endmodule
