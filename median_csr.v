`define ROW 256
`define COL 256
`define width 8

module median_csr (
    // Inputs
    clk, rst_n,
    ChipSelect, Write, Read,
    Address,
    WriteData,
    row_out,

    // Outputs
    ReadData,
    en_in, buffer_counter,
    row_in
);

//------------------------------------------------------------------------------
// Inputs and Outputs
//------------------------------------------------------------------------------
input clk;
input rst_n;

// Avalon interface
input ChipSelect;
input [1:0] Address;
input Write;
input Read;
input [31:0] WriteData;
output [31:0] ReadData;

// Median filter inputs and outputs
input [`ROW*`width*3-1:0] row_out;
output reg en_in;
output reg [8:0] buffer_counter;
output reg [`ROW*`width*3-1:0] row_in;

//------------------------------------------------------------------------------
// Internal Registers
//------------------------------------------------------------------------------
reg [6143:0] Buffer_Reg;    // Buffer to collect one row of pixels (6144 bits
reg [31:0] Data_Reg;

//------------------------------------------------------------------------------
// Assignments
//------------------------------------------------------------------------------
assign ReadData[31:0] = Data_Reg[31:0];

//------------------------------------------------------------------------------
// Write Logic
//------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Buffer_Reg <= 6144'b0;
        buffer_counter <= 9'b0;
        en_in <= 1'b0;
    end else if (ChipSelect & Write) begin
        case (Address)
            2'b00: begin
                Buffer_Reg <= {Buffer_Reg[6144-32-1:0], WriteData};
                buffer_counter <= buffer_counter + 1;
                // If one row (192 blocks of 32 bits) is complete
                if (buffer_counter == 9'd192) begin
                    row_in <= Buffer_Reg;   // Assign the full row to row_in
                    en_in <= 1'b1;
                    buffer_counter <= 9'b0;
                    Buffer_Reg <= 6144'b0;
                end 
            end
        endcase
    end else begin
        en_in <= en_in;
        Buffer_Reg <= Buffer_Reg;
        buffer_counter <= buffer_counter;
    end
end

//------------------------------------------------------------------------------
// Read Logic
//------------------------------------------------------------------------------
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Data_Reg <= 32'b0;
    end else if (ChipSelect & Read) begin
        case (Address)
            2'b01: Data_Reg <= row_out[31:0];
            2'b10: Data_Reg <= {31'h0, en_in};
        endcase
    end else begin
        Data_Reg <= Data_Reg;
    end
end

endmodule
