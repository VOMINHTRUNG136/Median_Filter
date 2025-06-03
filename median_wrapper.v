`define ROW 256
`define COL 256
`define width 8

module median_wrapper (
    input clk,
    input rst_n,
    input ChipSelect,
    input Write,
    input Read,
    input [1:0] Address,
    input [31:0] WriteData,
    output [31:0] ReadData
);

wire [8:0] buffer_counter;
wire en_in;
wire [`ROW*`width*3-1:0] row_in;
wire [`ROW*`width*3-1:0] row_out;

median_csr CSR (
    .clk (clk),
    .rst_n (rst_n),
    .ChipSelect (ChipSelect),
    .Write (Write),
    .Read (Read),
    .Address (Address),
    .WriteData (WriteData),
    .ReadData (ReadData),
    .en_in (en_in),
    .buffer_counter (buffer_counter),
    .row_in (row_in),
    .row_out (row_out)
);

median_filter CORE (
    .row_in (row_in),
    .rst_n (rst_n),
    .clk (clk),
    .en_in (en_in),
    .buffer_counter (buffer_counter),
    .row_out(row_out)
);

endmodule