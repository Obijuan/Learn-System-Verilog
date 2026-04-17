//-----------------------------------------------------------------
//-- CSR FILE
//-----------------------------------------------------------------


module csr_file (
    input logic clk,
    input logic rst,

    //----- Read port. All the csr registers can be read
    //----- from this port
    //-- CSR Address 
    input logic [11:0] csr_adr,
    output logic [31:0] csr_data,

    //----- Write port. All the csr can be written from this port
    //-- Data to write
    input logic [31:0] csr_data_write,
    input logic csr_wen,

    //-----------------------------------------------------
    //-- Ports for accesing individual CSRs, in paralell
    //-----------------------------------------------------
    //------- MIP
    output logic [31:0] mip,

    //------- MIE
    output logic [31:0] mie,

    //------- MEPC
    //-- Bits [1:0] are not used
    /* verilator lint_off UNUSEDSIGNAL */
    input logic [31:0] mepc_data_write,
    /* verilator lint_on UNUSEDSIGNAL */
    input logic mepc_wen,
    output logic [31:0] mepc,

    //------- MSTATUS
    input logic [31:0] mstatus_data_write,
    input logic mstatus_wen,
    output logic [31:0] mstatus,

    //------- MCAUSE
    input logic [31:0] mcause_data_write,
    input logic mcause_wen,

    //------- MTVEC
    output logic [31:0] mtvec,

    //------------------------
    //-- Control signals
    //------------------------
    input logic count_inst,
    input logic irq,
    input logic irq_timer
);


    //-- CSR registers
    logic [31:0] mstatus_reg;
    logic [31:0] mie_reg;
    logic [31:0] mtvec_reg;
    logic [31:0] mscratch_reg;
    logic [31:0] mepc_reg;
    logic [31:0] mcause_reg;
    logic [31:0] mip_reg;
    logic [63:0] mcycles;
    logic [63:0] minstrets;

    //------------------------------
    //-- PORT FOR READING CSRs
    //------------------------------
    always_comb begin : u_csr_read

        //-- Default values
        csr_data = 32'h0;

        case(csr_adr)

            csr::MSCRATCH: 
                csr_data = mscratch_reg;

            csr::MTVEC:
                csr_data = mtvec_reg;

            csr::MEPC:
                csr_data = mepc_reg;

            csr::MCAUSE:
                csr_data = mcause_reg;

            csr::MIE:
                csr_data = mie_reg;

            csr::MSTATUS:
                csr_data = mstatus_reg;

            csr::MIP:
                csr_data = mip_reg;

            csr::MCYCLE:
                csr_data = mcycles[31:0];

            csr::MCYCLEH:
                csr_data = mcycles[63:32];

            csr::MINSTRET:
                csr_data = minstrets[31:0];

            csr::MINSTRETH:
                csr_data = minstrets[63:32];

            default:
                csr_data = 32'h0;
        endcase
    end

    //---------------------------------
    //-- CSR DIRECT READ
    //---------------------------------
    assign mepc = mepc_reg;
    assign mip = mip_reg;
    assign mstatus = mstatus_reg;
    assign mtvec = mtvec_reg;
    assign mie = mie_reg;

    
    //--------------------------------------
    //-- MIE
    //--------------------------------------
    //-- Machine External Interrupt Enable
    localparam MEIE = 11;
    localparam MEIE_MASK = 1 << MEIE;

    //-- Machine Timer Interrupt Enable
    localparam MTIE = 7;
    localparam MTIE_MASK = 1 << MTIE;

    //-- MIE mask
    //-- Only MEIE and MTIE bits can be written...
    localparam MIE_MASK = (MEIE_MASK | MTIE_MASK);

    always_ff @(posedge clk) begin : u_mie_reg
        if (rst)
            mie_reg <= 32'b0;

        //-- Block access
        else if (csr_wen && (csr_adr == csr::MIE)) begin
            mie_reg <= csr_data_write & MIE_MASK; 
        end
    end


    //---------------------------------
    //-- MSCRATH
    //---------------------------------
    always_ff @(posedge clk) begin : u_mscratch_reg
        if (rst)
            mscratch_reg <= 32'b0;

        else if (csr_wen && (csr_adr == csr::MSCRATCH)) begin
            mscratch_reg <= csr_data_write; 
        end
    end


    //--------------------------------------
    //-- MTVEC
    //--------------------------------------
    always_ff @(posedge clk) begin : u_mtvec_reg
        if (rst)
            mtvec_reg <= 32'b0;

        else if (csr_wen && (csr_adr == csr::MTVEC)) begin
            //-- The two lsb are always 0
            mtvec_reg <= {csr_data_write[31:2], 2'b00}; 
        end
    end

    //--------------------------------------
    //-- MEPC
    //--------------------------------------
    always_ff @(posedge clk) begin : u_mepc_reg
        if (rst)
            mepc_reg <= 32'b0;

        else if (csr_wen && (csr_adr == csr::MEPC)) begin
            //-- The 2 lsb are 0
            mepc_reg <= {csr_data_write[31:2], 2'b00}; 
        end

        //-- Direct write
        else if (mepc_wen)
            //-- The 2 lsb are 0
            mepc_reg <= {mepc_data_write[31:2], 2'b00};
    end

    //--------------------------------------
    //-- MCAUSE
    //--------------------------------------
    always_ff @(posedge clk) begin : u_mcause_reg
        if (rst)
            mcause_reg <= 32'b0;

        //-- Block access
        else if (csr_wen && (csr_adr == csr::MCAUSE))
            mcause_reg <= csr_data_write; 

        //-- Direct write
        else if (mcause_wen)
            mcause_reg <= mcause_data_write;
    end

    //--------------------------------------
    //-- MSTATUS
    //--------------------------------------
    //-- Machine Previous Interrupt Enable
    localparam MPIE = 7;
    localparam MPIE_MASK = 1 << MPIE;

    //-- Global Machine Interrupt Enable
    localparam MIE = 3;
    localparam MIE_BIT_MASK = 1 << MIE;

    //-- MSTATUS mask
    //-- Only MIE and MPIE bits can be written...
    localparam MSTATUS_MASK = (MPIE_MASK | MIE_BIT_MASK);

    always_ff @(posedge clk) begin : u_mstatus_reg
        if (rst)
            mstatus_reg <= 32'b0;

        //-- Block access
        else if (csr_wen && (csr_adr == csr::MSTATUS))
            mstatus_reg <= csr_data_write & MSTATUS_MASK; 

        //-- Direct write
        else if (mstatus_wen)
            mstatus_reg <= mstatus_data_write & MSTATUS_MASK; 

    end


    //--------------------------------------------------------
    //-- MIP
    //--------------------------------------------------------
    //    11    10  9   8     7    6   5   4   3   2   1   0
    // +------+---+---+---+------+---+---+---+---+---+---+---+
    // | MEIP |   |   |   | MTIP |   |   |   |   |   |   |   |
    // +------+---+---+---+------+---+---+---+---+---+---+---+
    //-- Machine External Interrupt Pending
    localparam MEIP = 11;

    //-- Machine Timer Interrupt Pending
    localparam MTIP = 7;
    
    always_ff @(posedge clk) begin : u_mip_reg
        if (rst)
            mip_reg <= 32'b0;

        //-- Block access
        else if (csr_wen && (csr_adr == csr::MIP)) begin
            mip_reg <= csr_data_write;
        end

        //-- Update on every cycle
        else begin
            mip_reg <= 32'(unsigned'(irq)) << MEIP |
                       32'(unsigned'(irq_timer)) << MTIP;
        end
    end

    //-------------------------------------------
    //-- MCYCLE/MCYCLEH
    //-------------------------------------------
    always_ff @(posedge clk) begin : u_mcycles_reg
        if (rst) begin
            mcycles <= 64'b1;
        end
        else begin

            //-- Increment the counter
            mcycles <= mcycles + 1;

            //-- Write the counter
            //-- Block access
            if (csr_wen && (csr_adr == csr::MCYCLE))
                mcycles[31:0] <= csr_data_write;

            else if (csr_wen && (csr_adr == csr::MCYCLEH))
                mcycles[63:32] <= csr_data_write;

        end
    end


    //-------------------------------------------
    //-- MINSTRET/MINSTRETH
    //-------------------------------------------
    always_ff @(posedge clk) begin : u_minstret_reg
        if (rst) begin
            minstrets <= 64'b1;
        end
        else begin

            //-- If the instruction is valid, count it!
            if (count_inst)
                minstrets <= minstrets + 1;

            //-- Write the counter
            //-- Block access
            if (csr_wen && (csr_adr == csr::MINSTRET))
                minstrets[31:0] <= csr_data_write;

            else if (csr_wen && (csr_adr == csr::MINSTRETH))
                minstrets[63:32] <= csr_data_write;

        end
    end


endmodule
