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

//`include "technology.h"
//`default_nettype none

module ram_2rw_1c #(
		parameter DATASIZE	= 18,	// Memory data word width
		parameter ADDRSIZE	= 8,	// Number of memory address bits
		parameter INIT_RAM	= 1'b0,	// Set this parameter to 1'b1 if a with 0 initialized ram is needed
		parameter PIPELINED	= 0
	) (
		input wire					clk,
		input wire					wen_a,
		input wire					ren_a,
		input wire [ADDRSIZE-1:0]	addr_a,
		input wire [DATASIZE-1:0]	wdata_a,
		output wire [DATASIZE-1:0]	rdata_a,

		input wire					wen_b,
		input wire					ren_b,
		input wire [ADDRSIZE-1:0]	addr_b,
		input wire [DATASIZE-1:0]	wdata_b,
		output wire [DATASIZE-1:0]	rdata_b
	);

	wire [DATASIZE-1:0]	rdata_ram_a;
	wire [DATASIZE-1:0]	rdata_ram_b;

	generate
		if (PIPELINED == 0)
		begin
			assign rdata_a	= rdata_ram_a;
			assign rdata_b	= rdata_ram_b;
		end
		else
		begin
			(* HBLKNM="rdata_dly_a" *)
			reg [DATASIZE-1:0]	rdata_dly_a;
			reg					ren_dly_a;
			(* HBLKNM="rdata_dly_b" *)
			reg [DATASIZE-1:0]	rdata_dly_b;
			reg					ren_dly_b;

			assign rdata_a	= rdata_dly_a;
			assign rdata_b	= rdata_dly_b;

			always @(posedge clk)
			begin
				ren_dly_a		<= ren_a;

				if (ren_dly_a)
					rdata_dly_a	<= rdata_ram_a;
			end

			always @(posedge clk)
			begin
				ren_dly_b		<= ren_b;

				if (ren_dly_b)
					rdata_dly_b	<= rdata_ram_b;
			end
		end
	endgenerate

	reg [DATASIZE-1:0]	MEM [0:(2**ADDRSIZE)-1];
	reg [DATASIZE-1:0]	data_out_a;
	reg [DATASIZE-1:0]	data_out_b;

	assign rdata_ram_a = data_out_a;
	assign rdata_ram_b = data_out_b;

	generate
	if (INIT_RAM)
	begin
		integer i;
		initial
		begin
			for (i=0; i<2**ADDRSIZE; i=i+1)
				MEM[i] = {DATASIZE {1'b0}};
		end
	end
	endgenerate

	// having a read- and a write enable is not supported by xilinx when using both ports as RW ports
	// PORT A RAM
	always @(posedge clk)
	begin
		if (wen_a)
			MEM[addr_a]	<= wdata_a;
//		if (ren_a)
			data_out_a	<= MEM[addr_a];
	end

	// PORT B RAM
	always @(posedge clk)
	begin
		if (wen_b)
			MEM[addr_b]	<= wdata_b;
//		if (ren_b)
			data_out_b	<= MEM[addr_b];
	end

endmodule

`default_nettype wire
