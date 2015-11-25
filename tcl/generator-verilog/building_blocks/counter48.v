/* ============================================================
* RFG Register File Generator
* Copyright (C) 2014  University of Heidelberg - Computer Architecture Group
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* ===========================================================*/

`timescale 1ns/10ps
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
