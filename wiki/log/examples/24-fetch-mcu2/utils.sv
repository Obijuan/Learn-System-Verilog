//--------------------------------------
//-- Cajon de sastre
//--------------------------------------

//-- Detector de flancos
module edge_detector(
    input logic clk,

    //-- Valor de entrad
    input logic value,

    //-- Flanco detectado
    output logic edges
);

//-- Valor en el siguiente ciclo
logic value_r;
always_ff @( posedge clk ) begin
    value_r <= value;
end

assign edges = value ^ value_r;

endmodule
