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

`include "technology.h"
`default_nettype none

module ram_1w1r_1c #(
		parameter DATASIZE	= 78,	// Memory data word width
		parameter ADDRSIZE	= 9,	// Number of memory address bits
		parameter INIT_RAM	= 1'b0,	// Set this parameter to 1'b1 if a with 0 initialized ram is needed
		parameter PIPELINED	= 0,
		parameter REG_LIMIT	= 1280  // set this to a low value if don't want the reg based RAM
	) (
		input wire					clk,
		input wire					wen,
		input wire [DATASIZE-1:0]	wdata,
		input wire [ADDRSIZE-1:0]	waddr,
		input wire					ren,
		input wire [ADDRSIZE-1:0]	raddr,
		output wire [DATASIZE-1:0]	rdata,
		output wire							sec,
		output wire							ded
	);

	assign sec = 1'b0;
	assign ded = 1'b0;

	wire [DATASIZE-1:0]	rdata_ram;

	generate
		if (PIPELINED == 0)
		begin
			assign rdata	= rdata_ram;
		end
		else
		begin
			(* HBLKNM="rdata_dly" *)
			reg [DATASIZE-1:0]	rdata_dly;
			reg					ren_dly;

			assign rdata	= rdata_dly;

			always @(posedge clk)
			begin
				ren_dly			<= ren;

				if (ren_dly)
					rdata_dly	<= rdata_ram;
			end
		end
	endgenerate

	reg [DATASIZE-1:0]	MEM [0:(2**ADDRSIZE)-1];
	reg [DATASIZE-1:0]	data_out;

	assign rdata_ram = data_out;

	generate
	if (INIT_RAM)
	begin
		integer i;

		initial
		begin
			for (i=0; i<2**ADDRSIZE; i=i+1)
				MEM[i]	= {DATASIZE {1'b0}};
		end
	end
	endgenerate

	always @(posedge clk)
	begin
		if (wen)
			MEM[waddr]	<= wdata;
	end

	always @(posedge clk)
	begin
		if (ren)
			data_out	<= MEM[raddr];
	end

endmodule

`default_nettype wire
