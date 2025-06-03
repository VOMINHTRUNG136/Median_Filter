`define ROW 256
`define COL 256
`define width 8
`define IN_FILE_NAME  "noisy_rgb.raw"
`define OUT_FILE_NAME "rgb_f.raw"

module tb_median_wrapper;

// -----------------------------------------------------------------------------
// Testbench Registers and Wires
// -----------------------------------------------------------------------------
reg     [0:23]              r24;       // Temporary register for pixel data
reg     [0:1572863]         data_in;   // Buffer for entire input image data
reg     [`ROW*`width*3-1:0] row_data_out;  // Output line from DUT
integer file_in, file_out, i, j, f;  // File pointers and loop indices

// Avalon Interface Signals
reg             clk;
reg             rst_n;
reg             ChipSelect;
reg             Write;
reg             Read;
reg    [1:0]    Address;
reg    [31:0]   WriteData;
wire   [31:0]   ReadData;

// -----------------------------------------------------------------------------
// Instantiate the DUT (dirtylena_wrapper)
// -----------------------------------------------------------------------------
wire [`ROW*`width*3-1:0] row_out;

median_wrapper DUT (
    .clk        (clk),
    .rst_n      (rst_n),
    .ChipSelect (ChipSelect),
    .Write      (Write),
    .Read       (Read),
    .Address    (Address),
    .WriteData  (WriteData),
    .ReadData   (ReadData)
);

// -----------------------------------------------------------------------------
// Clock Generator
// -----------------------------------------------------------------------------
always begin
    clk = 0; #5;
    clk = 1; #5;
end

// -----------------------------------------------------------------------------
// Simulation Initialization
// -----------------------------------------------------------------------------
initial begin
    // Open input and output files
    file_in  = $fopen(`IN_FILE_NAME, "rb");
    file_out = $fopen(`OUT_FILE_NAME, "wb");

    // Read input image data
    f = $fread(data_in, file_in);

    // Initialize signals
    rst_n = 0; 
    ChipSelect = 0; 
    Write = 0; 
    Read = 0; 
    Address = 2'bxx; 
    WriteData = 32'h0000;

    #5;
    rst_n = 1;

    // SET = 0
    #10;
    ChipSelect = 1;

    // first row: row_in = data_in[0:6143]
    Address = 2'b00;
    Write = 1;
    for (j = 0; j < 192; j = j + 1) begin
        WriteData = data_in[j * 32 +: 32]; 
        #10;
    end
    #10;

    // second row: row_in = data_in[6144:12287]
    for (j = 0; j < 192; j = j + 1) begin
        WriteData = data_in[6144 + j * 32 +: 32]; 
        #10;
    end
    #10;

    // all other rows
    for (i = 0; i < `ROW; i = i + 1) begin
        for (j = 0; j < 192; j = j + 1) begin
            WriteData = data_in[12288 + i * 6144 + j * 32 +: 32];
            #10;
        end

        row_data_out = DUT.CORE.row_out;

        // Write processed row to output file
        for (j=0 ; j<`COL ; j=j+1) 
		begin
			r24 = row_data_out[6120-24*j +:24];
			$fwrite(file_out, "%c%c%c" ,r24[0:7],r24[8:15],r24[16:23]);
		end
        #10;
    end
    #5 Write = 0;

    $fclose(file_in);
    $fclose(file_out);
    $stop;
end
endmodule 