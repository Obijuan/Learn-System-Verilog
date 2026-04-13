


module memory(
    input logic clk,

    //-- Puerto a: Lectura
    input logic [11:0] porta_adr,
    output logic [31:0] porta_data_out,

    //-- Puerto b: Lectura/escritura
    input logic [11:0] portb_adr,
    input logic [31:0] portb_data_in,
    input logic portb_wen,
    input logic [3:0] portb_sel,
    output logic [31:0] portb_data_out
);

//-- Address with
localparam ADDR_WIDTH = 12;

//-- Size of the memory
localparam SIZE = 1 << ADDR_WIDTH;

//-- Memory itself
logic [31:0] mem[0:SIZE-1];


//------ PUERTO A: Lectura
always_ff @(posedge clk)
begin
  porta_data_out <= mem[porta_adr];
end

//------ PUERTO B: Lectura
always_ff @(posedge clk)
begin
    if (portb_wen == 0)
        portb_data_out <= mem[portb_adr];
    else
        portb_data_out <= 32'h0;
end

//------ PUERTO B: Escritura
always_ff @(posedge clk)
begin
    if (portb_wen) begin
        if (portb_sel[0] == 1) begin 
            mem[portb_adr][7:0] <= portb_data_in[7:0]; 
        end

        if (portb_sel[1] == 1) begin 
            mem[portb_adr][15:8] <= portb_data_in[15:8]; 
        end

        if (portb_sel[2] == 1) begin 
            mem[portb_adr][23:16] <= portb_data_in[23:16]; 
        end

        if (portb_sel[3] == 1) begin 
            mem[portb_adr][31:24] <= portb_data_in[31:24]; 
        end
    end
end


    

//-- Init the memory
initial begin
    $readmemh("init.mem", mem, 0, SIZE-1);
end

endmodule

