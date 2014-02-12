/* ============================================================
*
* Copyright (c) 2010 Computer Architecture Group, University of Heidelberg
*
* All rights reserved.
*
* University of Heidelberg
* Computer Architecture Group
* B6 26
* 68131 Mannheim
* Germany
* http://ra.ziti.uni-heidelberg.de/
*
* Author     :  Mondrian Nuessle
* Create Date:  07/07/10
* Design Name:  counter48
* Module Name:  counter48
* Description:  An loadable up-counter with a maximum width of 48 bit.
*                Supports DSP Slices on Xilinx.
*
* Facts for a 32 bit implementation, using the counter_eval.v as top-module, ISE11.3, constrained to 250 MHz on Virtex4-11
*
*  DSP Implementation:
*  68 IOB FFs
*  1 FF
*  1 LUT
*  1 Slice
*  1 DSP48
*  244 MHz
*
*  Fabric Implementation:
*   66 IOB FFs
*   65 FF
*   96 LUT
*   75 Slice
*   0 DSP48
*   216 MHz

*
* Revision:     Revision 1.0.0
*
* ===========================================================*/
//`timescale 1ns/10ps
//`include "technology.h"

module counter48 #(
		parameter DATASIZE	= 16,	// width of the counter, must be <=48 bits!
	    parameter LOADABLE	= 1		// whether the counter can be loaded at runtime
	) (
		input wire					clk,
	    input wire					res_n,
		input wire					increment,
		input wire	[DATASIZE-1:0]	load,
		input wire					load_enable,
		output wire [DATASIZE-1:0]	value
);

	reg [DATASIZE-1:0]	value_reg;
	reg [DATASIZE-1:0]	load_reg;
	reg					load_enable_reg;
//	reg					increment_reg;

	assign value	= value_reg;

	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			value_reg				<= {DATASIZE{1'b0}};
			load_enable_reg			<= 1'b0;
//			increment_reg			<= 1'b0;
			load_reg				<= {DATASIZE{1'b0}};
//			value_reg				<= {DATASIZE{1'b0}};
		end
		else
		begin
			load_reg				<= load;
			load_enable_reg			<= load_enable;
//			increment_reg			<= increment;
//			value					<=value_reg;
			case ({load_enable_reg,increment})
					2'b00:
						value_reg	<= value_reg;
					2'b01:
						value_reg	<= (value_reg + 1'b1);
					2'b10:
						value_reg	<= load_reg;
					2'b11:
						value_reg	<= load_reg + 1'b1; //arguable if we need to do this
			endcase
		end
	end

endmodule
