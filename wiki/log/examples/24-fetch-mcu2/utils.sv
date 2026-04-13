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


//------------------------------------------------
//-- Antirrebotes
//------------------------------------------------
module debounce #(
    //-- Tamaño en bits del antirrebotes
    //-- Simulacion: usar SIZE=3
    //-- Sintesis: SIZE=17
    parameter int SIZE
)(
    input logic clk,

    input logic value_in,
    output logic value_out
);


always_ff @( posedge clk ) begin
    if (timeout)
        value_out <= value_in;
end

logic [SIZE-1:0] bounce_cnt;
logic timeout;
always_ff @( posedge clk ) begin
    if (bounce_cnt_state==0)
        bounce_cnt <= 0;
    else bounce_cnt <= bounce_cnt + 1;
end

assign timeout = bounce_cnt[SIZE-1];

logic bounce_cnt_state;
logic start_cnt;
logic stop_cnt;
always_ff @( posedge clk ) begin
    if (start_cnt)
        bounce_cnt_state = 1;
    else if (stop_cnt)
        bounce_cnt_state = 0;
end
assign stop_cnt = timeout;
assign start_cnt = edges;

logic edges;
edge_detector u_sw1_edges (
    .clk(clk),
    .value(value_in),
    .edges(edges)
);

endmodule
