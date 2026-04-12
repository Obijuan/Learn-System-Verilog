


module memory(
    input logic clk,
    input logic [12:0] adr,
    output logic [31:0] data_o
);

//-- Address with
localparam ADDR_WIDTH = 13;

//-- Size of the memory
localparam SIZE = 1 << ADDR_WIDTH;

//-- Memory itself
logic [31:0] mem[0:SIZE-1];


//-- Reading port: Synchronous
always @(posedge clk)
begin
  data_o <= mem[adr];
end


//-- Init the memory
initial begin
    // for (int i = 0; i < 128; i++) begin
    //     mem[i] = 'hF0 + i;
    // end
    $readmemh("init.mem", mem, 0, SIZE-1);
end

endmodule

