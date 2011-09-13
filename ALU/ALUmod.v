`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:51:41 08/31/2011 
// Design Name: 
// Module Name:    ALUmod 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ALUmod(
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [3:0] opcode,
    output reg [15:0] S,
    input wire [3:0] opext,
    output reg [4:0] CLFZN,
	 input wire carry	// used as a carry in bit, when needed.  To come from processor status
    );


//start always block and add all the different executions
always@(A,B,opcode,opext,carry)
	begin
	  casex({opcode, opext})
	    8'b0000_0101: // ADD
		 begin
		   S = A + B;
			CLFZN = 0;
			if( S == 0 ) CLFZN[1] = 1'b1;
			else         CLFZN[1] = 1'b0;
			CLFZN[2] = (~A[15]&~B[15]&S[15]) | (A[15]&B[15]&S[15]);
		 end
		 
		 8'b0101_xxxx: // ADDI
		 begin
		   S = A + B;
			CLFZN = 0;
			if( S == 0 ) CLFZN[1] = 1'b1;
			else         CLFZN[1] = 1'b0;
			CLFZN[2] = (~A[15]&~B[15]&S[15]) | (A[15]&B[15]&S[15]);
		 end
		 
		 8'b0000_0110: // ADDU
		 begin
			CLFZN = 0;		 
		   {CLFZN[4],S} = A + B;			// set carry bit and sum
			if( S == 0 ) CLFZN[1] = 1'b1; // set zero bit
			else         CLFZN[1] = 1'b0;
		 end
		 
		 8'b0110_xxxx: // ADDUI
		 begin
			CLFZN = 0;		 
		   {CLFZN[4],S} = A + B;			// set carry bit and sum
			if( S == 0 ) CLFZN[1] = 1'b1; // set zero bit
			else         CLFZN[1] = 1'b0;		 
		 end
		 
		 8'b0000_0111: // ADDC
		 begin
		   CLFZN = 0;
			{CLFZN[4], S} = A + B + carry;  // set the carry bit and sum
			if( S == 0 ) CLFZN[1] = 1'b1; // set Z bit
			else         CLFZN[1] = 1'b0;
			CLFZN[2] = (~A[15]&~B[15]&S[15]) | (A[15]&B[15]&S[15]); // set overflow (signed)
		 end
		 
		 8'b1110_xxxx: // ADDCi
		 begin
		   CLFZN = 0;
			{CLFZN[4], S} = A + B + carry;  // set the carry bit and sum
			if( S == 0 ) CLFZN[1] = 1'b1; // set Z bit
			else         CLFZN[1] = 1'b0;
			CLFZN[2] = (~A[15]&~B[15]&S[15]) | (A[15]&B[15]&S[15]); // set overflow (signed)
       end			
		
		default:
		begin
			CLFZN = 0;
			S = 0;
		end
	  endcase
	
	end


endmodule
