
/* ============================================================
*
* Copyright (c) 2011 Computer Architecture Group, University of Heidelberg & EXTOLL GmbH
*
* This file is confidential and may not be distributed.
*
* All rights reserved.
*
* University of Heidelberg
* Computer Architecture Group
* B6 26
* 68131 Mannheim
* Germany
* http://www.ra.ziti.uni-heidelberg.de
*
*
* Author(s):     Benjamin Geib
*
* Create Date:   07/08/10
* Last Modified: 07/08/10
* Design Name:   CAG Building Blocks
* Module Name:   ram_2rw_1c
* Description:   A wrapper for a RAM with two read/write ports, sharing a common clock
*
* Revision:      Revision 1.0
*
* ===========================================================*/

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
