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

module ram_1w2r_1c #(
		parameter DATASIZE	= 18,
		parameter ADDRSIZE	= 8,
		parameter INIT_RAM	= 1'b0,
		parameter PIPELINED	= 0
	) (
		input wire					clk,

		//write port
		input wire 					wen,
		input wire [ADDRSIZE-1:0]	waddr,
		input wire [DATASIZE-1:0]	wdata,

		//first read port
		input wire					ren1,
  		input wire [ADDRSIZE-1:0]	raddr1,
		output wire [DATASIZE-1:0]	rdata1,

		//second read port
		input wire					ren2,
		input wire [ADDRSIZE-1:0]	raddr2,
		output wire [DATASIZE-1:0]	rdata2,

		output wire sec,
		output wire ded
	);

	wire [DATASIZE-1:0]	rdata_ram1;
	wire [DATASIZE-1:0]	rdata_ram2;

	assign sec = 1'b0;
	assign ded = 1'b0;

	generate
		if (PIPELINED == 0)
		begin
			assign rdata1	= rdata_ram1;
			assign rdata2	= rdata_ram2;
		end
		else
		begin
			(* HBLKNM="rdata_dly" *)
			reg [DATASIZE-1:0]	rdata_dly1;
			reg					ren_dly1;
			reg [DATASIZE-1:0]	rdata_dly2;
			reg					ren_dly2;

			assign rdata1	= rdata_dly1;
			assign rdata2	= rdata_dly2;

			always @(posedge clk)
			begin
				ren_dly1		<= ren1;
				ren_dly2		<= ren2;

				if (ren_dly1)
					rdata_dly1	<= rdata_ram1;

				if (ren_dly2)
					rdata_dly2	<= rdata_ram2;
			end
		end
	endgenerate

	reg [DATASIZE-1:0]	MEM [0:(2**ADDRSIZE)-1];
	reg [DATASIZE-1:0]	data_out1;
	reg [DATASIZE-1:0]	data_out2;

	assign rdata_ram1 = data_out1;
	assign rdata_ram2 = data_out2;

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
		if (ren1)
			data_out1	<= MEM[raddr1];
		if (ren2)
			data_out2	<= MEM[raddr2];
	end

endmodule

`default_nettype wire
