
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
* Author(s):     Richard Leys, Benjamin Geib
*
* Create Date:   07/09/07
* Last Modified: 07/14/10
* Design Name:   CAG Building Blocks
* Module Name:   srl_fifo_wrapper
* Description:   Switches between Xilinx designed srl_fifo, and register based fifo.
*                - almost_full threshold can be adjusted with AFULL_THRES and gives the distance to full.
*                - almost_empty threshold can be adjusted with AEMPTY_THRES and gives the distance to empty.
*                - data width can be adjusted with WIDTH parameter
*                - A 16 stage deep FIFO will be instantiated if DEPTH is smaller than 17
*                - A 32 stage deep FIFO will be instantiated if DEPTH is larger than 16
*                - Setting REGISTERED to 1 adds a register behind the srl fifo to improve timing
*                - Setting USE_BYPASS to 1 adds a multiplexer that can bypass srl fifo if it is empty
*                  and nothing is stored in the output register as well, this is to avoid a cycle latency but uses more resources
*                - Set REGISTERED to 2 to get dout_nxt working, otherwise it will not be valid!
*
* Revision:     Revision 1.3
*
* ===========================================================*/

//`include "technology.h"
`default_nettype none

module srl_fifo_wrapper #(
`ifdef CAG_ASSERTIONS
		parameter DISABLE_EMPTY_ASSERT		= 0,
		parameter DISABLE_FULL_ASSERT		= 0,
		parameter DISABLE_SHIFT_OUT_ASSERT	= 0,
		parameter DISABLE_XCHECK_ASSERT		= 0,
`endif
		parameter WIDTH						= 8,
		parameter DEPTH						= 16,
		parameter AEMPTY_THRES				= 1,
		parameter AFULL_THRES				= 1,
		parameter REGISTERED				= 0,
		parameter USE_BYPASS				= 0
	) (
		input wire				clk,
		input wire				res_n,
		input wire				clr,
		input wire [WIDTH-1:0]	din,
		input wire				shiftin,
		input wire				shiftout,
		output wire [WIDTH-1:0]	dout,
		output wire [WIDTH-1:0]	dout_nxt,
		output wire				full,
		output wire				empty,
		output wire				almost_full,
		output wire				almost_full_nxt,
		output wire				almost_empty
	);

`ifdef CAG_XILINX
	// Avoid an underflow of the almost empty threshold for cases where it isn't even used.
	localparam AEMPTY_THRES_MOD = (REGISTERED > AEMPTY_THRES)
	                               ? 0
	                               : (AEMPTY_THRES - REGISTERED);

	wire [WIDTH-1:0]	dout_w;
	wire [WIDTH-1:0]	dout_nxt_w;
	wire				empty_w;
	wire				shiftout_w;
	wire				shiftin_w;
	wire				almost_empty_w;

	generate
		if (REGISTERED == 2)
		begin: reg_2_gen
			// Currently always USE_BYPASS == 1 for REGISTERED == 2
			reg [WIDTH-1:0]	dout_r [0:1];
			reg [1:0]		empty_r;

			assign shiftout_w		= shiftout;
			assign shiftin_w		= (shiftin && !empty_w) || (shiftin && !shiftout && !empty_r[1]);

			assign dout				= dout_r[0];
			assign dout_nxt			= dout_r[1];
			assign empty			= empty_r[0];

			if (AEMPTY_THRES==0)
				assign almost_empty	= empty_r[0];
			else if (AEMPTY_THRES==1)
				assign almost_empty	= empty_r[1];
			else
				assign almost_empty	= almost_empty_w; // empty_w;

			`ifdef ASYNC_RES
			always @(posedge clk or negedge res_n) `else
			always @(posedge clk ) `endif
			begin
				if (!res_n)
				begin
					empty_r[0]		<= 1'b1;
					dout_r[0]		<= {WIDTH {1'b0}};
				end
				else if (clr)
				begin
					empty_r[0]		<= 1'b1;
//					dout_r[0]		<= {WIDTH {1'b0}};
				end
				else
				begin
					if ( (shiftin && empty_r[0]) ||
					     (shiftin && shiftout && empty_r[1]) )
					begin
						dout_r[0]	<= din;
						empty_r[0]	<= 1'b0;
					end
					else if (shiftout && empty_r[1] && empty_w)
					begin
//						dout_r[0]	<= {WIDTH{1'b0}};
						empty_r[0]	<= 1'b1;
					end
					else if (shiftout && !empty_r[1])
					begin
						dout_r[0]	<= dout_r[1];
						empty_r[0]	<= 1'b0;
					end
					else if (shiftout && empty_r[1] && !empty_w) // impossible?
					begin
						dout_r[0]	<= dout_w;
						empty_r[0]	<= 1'b0;
					end
				end
			end

			`ifdef ASYNC_RES
			always @(posedge clk or negedge res_n) `else
			always @(posedge clk ) `endif
			begin
				if (!res_n)
				begin
					empty_r[1]		<= 1'b1;
					dout_r[1]		<= {WIDTH {1'b0}};
				end
				else if (clr)
				begin
					empty_r[1]		<= 1'b1;
//					dout_r[1]		<= {WIDTH {1'b0}};
				end
				else
				begin
					if ( (shiftin && !shiftout && empty_r[1] && !empty_r[0]) ||
					     (shiftin && shiftout && !empty_r[1] && empty_w) )
					begin
						dout_r[1]	<= din;
						empty_r[1]	<= 1'b0;
					end
					else if (shiftout && empty_w)
					begin
//						dout_r[1]	<= {WIDTH{1'b0}};
						empty_r[1]	<= 1'b1;
					end
					else if (shiftout && !empty_w && !empty_r[1])
					begin
						dout_r[1]	<= dout_w;
						empty_r[1]	<= 1'b0;
					end
				end
			end

		end // of (REGISTERED==2)
		else if (REGISTERED == 1)
		begin: reg_1_gen
			reg [WIDTH-1:0] dout_r;
			reg				empty_r;

			if (USE_BYPASS == 1)
			begin
				assign shiftout_w	= shiftout;
				assign shiftin_w	= (shiftin && !empty_w) || (shiftin && !shiftout && !empty_r);

				`ifdef ASYNC_RES
				always @(posedge clk or negedge res_n) `else
				always @(posedge clk ) `endif
				begin
					if (!res_n)
					begin
						empty_r		<= 1'b1;
						dout_r		<= {WIDTH {1'b0}};
					end
					else if (clr)
					begin
						empty_r		<= 1'b1;
						//dout_r		<= {WIDTH {1'b0}};
					end
					else
					begin
						if ((shiftin && empty_r) || (shiftin && shiftout && empty_w))
						begin
							dout_r	<= din;
							empty_r	<= 1'b0;
						end
						else if (shiftout && empty_w)
						begin
//							dout_r	<= {WIDTH{1'b0}};
							empty_r	<= 1'b1;
						end
						else if (shiftout && !empty_w)
						begin
							dout_r	<= dout_w;
							empty_r	<= 1'b0;
						end
					end
				end
			end
			else
			begin
				assign shiftout_w	= !empty_w && (empty_r || shiftout);
				assign shiftin_w	= shiftin;

				`ifdef ASYNC_RES
				always @(posedge clk or negedge res_n) `else
				always @(posedge clk ) `endif
				begin
					if (!res_n)
					begin
						empty_r		<= 1'b1;
						dout_r		<= {WIDTH {1'b0}};
					end
					else if (clr)
					begin
						empty_r		<= 1'b1;
//						dout_r		<= {WIDTH {1'b0}};
					end
					else
					begin
						if (!empty_w && (empty_r || shiftout))
						begin
							dout_r	<= dout_w;
							empty_r	<= 1'b0;
						end
						else if (shiftout)
							empty_r	<= 1'b1;
					end
				end
			end

			assign dout				= dout_r;
			assign dout_nxt			= dout_w;
			assign empty			= empty_r;
			assign almost_empty		= almost_empty_w;
		end
		else
		begin: reg_0_gen
			assign dout				= dout_w;
			assign dout_nxt			= dout_nxt_w;
			assign empty			= empty_w;
			assign almost_empty		= almost_empty_w;
			assign shiftout_w		= shiftout;
			assign shiftin_w		= shiftin;
		end
	endgenerate

	generate
		if (DEPTH < 17)
		begin: srl_instance_16
			srl_fifo_16e #(
`ifdef CAG_ASSERTIONS
				.DISABLE_EMPTY_ASSERT(DISABLE_EMPTY_ASSERT),
				.DISABLE_FULL_ASSERT(DISABLE_FULL_ASSERT),
`endif
				.WIDTH(WIDTH),
				.AFULL_THRES(AFULL_THRES),
				.AEMPTY_THRES(AEMPTY_THRES_MOD)
			) srl_fifo_I (
				.clk(clk),
				.res_n(res_n),
				.clr(clr),
				.din(din),
				.dout(dout_w),
				.shiftout(shiftout_w),
				.shiftin(shiftin_w),
				.full(full),
				.almost_full(almost_full),
				.almost_full_nxt(almost_full_nxt),
				.empty(empty_w),
				.almost_empty(almost_empty_w)
			);

			assign dout_nxt_w	= {WIDTH {1'b0}};
		end
		else
		begin: srl_instance_32
			srl_fifo_c32e #(
`ifdef CAG_ASSERTIONS
				.DISABLE_EMPTY_ASSERT(DISABLE_EMPTY_ASSERT),
				.DISABLE_FULL_ASSERT(DISABLE_FULL_ASSERT),
`endif
				.WIDTH(WIDTH),
				.AFULL_THRES(AFULL_THRES),
				.AEMPTY_THRES(AEMPTY_THRES_MOD)
			) srl_fifo_I (
				.clk(clk),
				.res_n(res_n),
				.clr(clr),
				.din(din),
				.dout(dout_w),
				.shiftout(shiftout_w),
				.shiftin(shiftin_w),
				.full(full),
				.almost_full(almost_full),
				.almost_full_nxt(almost_full_nxt),
				.empty(empty_w),
				.almost_empty(almost_empty_w)
			);

			assign dout_nxt_w	= {WIDTH {1'b0}};
		end
	endgenerate

//behavioral model - ASIC/VERILATOR/...
`else // CAG_XILINX

	fifo_reg #(
`ifdef CAG_ASSERTIONS
		.DISABLE_EMPTY_ASSERT(DISABLE_EMPTY_ASSERT),
		.DISABLE_SHIFT_OUT_ASSERT(DISABLE_SHIFT_OUT_ASSERT),
		.DISABLE_FULL_ASSERT(DISABLE_FULL_ASSERT),
`endif
		.DSIZE(WIDTH),
		.ENTRIES(DEPTH),
		.ALMOST_EMTPY_VAL(AEMPTY_THRES),
		.ALMOST_FULL_VAL(AFULL_THRES)
	) reg_fifo_I (
		.clk(clk),
		.res_n(res_n),
		.clr(clr),
		.din(din),
		.shiftin(shiftin),
		.shiftout(shiftout),
		.dout(dout),
		.dout_nxt(dout_nxt),
		.full(full),
		.almost_full(almost_full),
		.almost_full_nxt(almost_full_nxt),
		.almost_empty(almost_empty),
		.empty(empty)
	);

`endif // else CAG_XILINX

`ifdef CAG_COVERAGE
	full_cov:				cover property (@(posedge clk) disable iff(!res_n || clr) (full == 1'b1));
	almost_full_cov:		cover property (@(posedge clk) disable iff(!res_n || clr) (almost_full == 1'b1));
	empty_cov:				cover property (@(posedge clk) disable iff(!res_n || clr) (empty == 1'b1));
	almost_empty_cov:		cover property (@(posedge clk) disable iff(!res_n || clr) (almost_empty == 1'b1));

	covergroup shift_in_and_out @(posedge clk);
		shift_in_and_out_cp: coverpoint ({shiftin, shiftout}) iff (shiftin || shiftout)
		{
			bins count[] = {[1:3]};
		}
	endgroup
	shift_in_and_out shift_in_and_out_I;
	initial begin
		shift_in_and_out_I = new();
		shift_in_and_out_I.set_inst_name("shift_in_and_out_I");
	end
`endif // CAG_COVERAGE

`ifdef CAG_ASSERTIONS
	shift_in_and_full:				assert property (@(posedge clk) disable iff(!res_n || clr) (shiftin |-> !full));

	if (DISABLE_SHIFT_OUT_ASSERT == 0)
		shift_out_and_empty:		assert property (@(posedge clk) disable iff(!res_n || clr) (shiftout |-> !empty));

	if (DISABLE_XCHECK_ASSERT == 0)
	  dout_known:					assert property (@(posedge clk) disable iff(!res_n || clr) (!empty |-> !$isunknown(dout)));
	if (DISABLE_XCHECK_ASSERT == 0)
	 dout_nxt_known:				assert property (@(posedge clk) disable iff(!res_n || clr) (!almost_empty |-> !$isunknown(dout_nxt)));

	final
	begin
		if (DISABLE_FULL_ASSERT == 0)
		begin
			assert_full_set:				assert (!full);
			assert_almost_full_set:			assert (!almost_full);
		end

		if (DISABLE_EMPTY_ASSERT == 0)
		begin
			assert_almost_empty_not_set:	assert (almost_empty);
			assert_empty_not_set:			assert (empty);
		end
	end
`endif // CAG_ASSERTIONS

endmodule

`default_nettype wire
