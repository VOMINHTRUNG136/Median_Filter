`define ROW 256
`define COL 256
`define width 8
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module median_filter(
// -----------------------------------------------------------------------------
// --------------------------------input's--------------------------------------
input [`ROW*`width*3-1:0] row_in,       //input row each clock event. 6144 bit
input clk,
input en_in, 
input rst_n,
input [8:0] buffer_counter,
// -----------------------------------------------------------------------------
// --------------------------------output's-------------------------------------
output reg[`ROW*`width*3-1:0] row_out   //output row fixed each clock event.		
);
// -----------------------------------------------------------------------------
// -------------------------------register's------------------------------------
reg [`ROW*`width*3-1:0]	line_1;     //up.
reg [`ROW*`width*3-1:0]	line_2;     //middle.
reg [`ROW*`width*3-1:0]	line_3;     //down.
reg	[2:0] state, next;          //state mechine.
reg [`width-1:0] counter;           //counter
// -----------------------------------------------------------------------------
// -------------------------------parameter's-----------------------------------
parameter [2:0]  ROW1 = 3'b000,
                 ROW2 = 3'b001,
		 ROW3 = 3'b010,
                 ROUTINE = 3'b011,
                 ROW256 = 3'b100,
		 SLEEP = 3'b101;
// -----------------------------------------------------------------------------
// ------------------------------State Machine----------------------------------
// -----------------------------------------------------------------------------
always@(posedge clk or negedge en_in) begin
    if(en_in == 1'b0)				 // wait for en_in 
        state <= ROW1; 		                 
    else if (buffer_counter == 9'd192)
        state <= next;
end
// -----------------------------------------------------------------------------
always@(state or rst_n or row_in) begin
    case(state)
        ROW1:	
            begin
            counter = 8'b0000_0000;
            line_1 = row_in;
            next = ROW2;
            end
        ROW2:	
            begin
            line_2 = row_in;
            next = ROW3;
            end
        ROW3:
            begin
            row_out = median_3 ( line_1, line_1, line_2 );
            line_3 = row_in;
            counter = counter + 1'b1;
            next = ROUTINE;
            end
        ROUTINE:
            begin
            row_out = median_3 (line_1, line_2, line_3 );
            line_1 = line_2;
            line_2 = line_3;
            line_3 = row_in;
            counter = counter + 1'b1;
                if (counter == 8'b11111111)  
                    next = ROW256;
                else
                    next = ROUTINE;
            end
        ROW256:
            begin
            row_out = median_3 (line_2, line_3, line_3 );
            next = SLEEP;                
            end
        SLEEP:
            begin
                if(rst_n == 1'b0)       
                    next = ROW1;
                else
                    next = SLEEP; 
            end
        default: 
            begin
                next = state; 
                line_1 = line_1; 
                line_2 = line_2; 
                line_3 = line_3; 
                counter = counter; 
                row_out = row_out; 
            end
    endcase
end
// -------------------------------function's------------------------------------
// -----------------------------------------------------------------------------
// -------------------------------function 1------------------------------------
function [0:`width-1]median_1;     //3 Byte in, one median out 
input [0:`width-1]p_1;
input [0:`width-1]p_2;
input [0:`width-1]p_3;
begin
	     if(p_1>=p_3 && p_1<=p_2)  // 3 1 2
		median_1=p_1;
	else if(p_1>=p_2 && p_1<=p_3)  // 2 1 3 
		median_1=p_1;
	else if(p_2>=p_1 && p_2<=p_3)  // 1 2 3 
		median_1=p_2;
	else if(p_2>=p_3 && p_2<=p_1)  // 3 2 1 
		median_1=p_2;
	else if(p_3>=p_1 && p_3<=p_2)  // 1 3 2
		median_1=p_3;
	else if(p_3>=p_2 && p_3<=p_1)  // 2 3 1
		median_1=p_3;	
end
endfunction
// -----------------------------------------------------------------------------
// -------------------------------function 2------------------------------------
function  [0:`width-1] median_2;     //9 Byte in, one median out
input	 [0:`width-1] p11;  
input	 [0:`width-1] p12;
input	 [0:`width-1] p13;
input	 [0:`width-1] p21;
input	 [0:`width-1] p22;
input	 [0:`width-1] p23;
input	 [0:`width-1] p31;
input	 [0:`width-1] p32;
input	 [0:`width-1] p33;
reg   	[0:`width-1] L1;
reg     [0:`width-1] L2;
reg     [0:`width-1] L3;
begin
L1 = median_1(p11, p12, p13);
L2 = median_1(p21, p22, p23);
L3 = median_1(p31, p32, p33);
median_2 = median_1(L1, L2, L3);
end
endfunction
// -----------------------------------------------------------------------------
// -------------------------------function 3------------------------------------
function [0:`ROW*`width*3-1] median_3;  //2304 Byte in(tree row's), 768 fixed out(one row)
input [0:`ROW*`width*3-1] line1;
input [0:`ROW*`width*3-1] line2;
input [0:`ROW*`width*3-1] line3;
//with edge's 
reg [0:(`ROW+2)*`width*3-1] line1_e;
reg [0:(`ROW+2)*`width*3-1] line2_e;
reg [0:(`ROW+2)*`width*3-1] line3_e;
integer i;
begin
line1_e = {line1[0:`width*3-1], line1, line1[(`ROW-1)*`width*3:`ROW*`width*3-1]};
line2_e = {line2[0:`width*3-1], line2, line2[(`ROW-1)*`width*3:`ROW*`width*3-1]};
line3_e = {line3[0:`width*3-1], line3, line3[(`ROW-1)*`width*3:`ROW*`width*3-1]};
	for (i=0; i<`COL ; i=i+1) begin
		//RED
		median_3[24*i   +: 8] = median_2( line1_e[24*i   +: 8], line1_e[24*i+24 +:8] , line1_e[24*i+48 +:8], line2_e[24*i   +: 8], line2_e[24*i+24 +:8] , line2_e[24*i+48 +:8] , line3_e[24*i   +: 8], line3_e[24*i+24 +:8] , line3_e[24*i+48 +:8]);
		//GREEN
		median_3[24*i+8 +: 8] = median_2( line1_e[24*i+8 +: 8], line1_e[24*1+32 +:8] , line1_e[24*i+56 +:8], line2_e[24*i+8 +: 8], line2_e[24*1+32 +:8] , line2_e[24*i+56 +:8] , line3_e[24*i+8 +: 8], line3_e[24*1+32 +:8] , line3_e[24*i+56 +:8]);
		//BLUE
 		median_3[24*i+16+: 8] = median_2( line1_e[24*i+16+: 8], line1_e[24*i+40 +:8] , line1_e[24*i+64 +:8], line2_e[24*i+16+: 8], line2_e[24*i+40 +:8] , line2_e[24*i+64 +:8] , line3_e[24*i+16+: 8], line3_e[24*i+40 +:8] , line3_e[24*i+64 +:8]);
	end
end
endfunction
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
endmodule 