
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
* Author(s):     David Slogsnat, Heiner Litz, Benjamin Geib
*
* Create Date:   05/11/06
* Last Modified: 07/14/10
* Design Name:   CAG Building Blocks - Fast FIFO
* Module Name:   fifo_reg
* Description:   A shift register based FIFO
*
* Revision:      Revision 1.00
*
* ===========================================================*/

//`include "technology.h"
`default_nettype none

module fifo_reg #(
`ifdef CAG_ASSERTIONS
		parameter DISABLE_EMPTY_ASSERT		= 0,
		parameter DISABLE_FULL_ASSERT		= 0,
		parameter DISABLE_SHIFT_OUT_ASSERT	= 0,
		parameter DISABLE_XCHECK_ASSERT		= 0,
`endif
		parameter ALMOST_FULL_VAL			= 1,
		parameter ALMOST_EMTPY_VAL			= 1,
		parameter DSIZE						= 8,
		parameter ENTRIES					= 2
	) (
		input wire				clk,
		input wire				res_n,
		input  wire				clr,
		input wire				shiftin,
		input wire				shiftout,
		input wire [DSIZE-1:0]	din,

		output wire [DSIZE-1:0]	dout,
		output wire [DSIZE-1:0]	dout_nxt,
		output reg				full,
		output reg				empty,
		output reg				almost_full,
		output reg				almost_full_nxt,
		output reg				almost_empty
	);

	//the fifo_reg can currently only have up to 2047 entries
	localparam LG_ENTRIES =  (ENTRIES <= 2) ? 1 :
				(ENTRIES <= 4)    ?  2 :
				(ENTRIES <= 8)    ?  3 :
				(ENTRIES <= 16)   ?  4 :
				(ENTRIES <= 32)   ?  5 :
				(ENTRIES <= 64)   ?  6 :
				(ENTRIES <= 128)  ?  7 :
				(ENTRIES <= 256)  ?  8 :
				(ENTRIES <= 512)  ?  9 :
				(ENTRIES <= 1024) ? 10 : 11;

	reg [DSIZE-1:0]		entry [0:ENTRIES-1];
	reg [LG_ENTRIES:0]	wp;

	integer				i;

	wire				shiftout_clean, shiftin_clean;

	// first stage of fifo is output
	assign dout				= entry[0];
	assign dout_nxt			= entry[1];

	assign shiftout_clean	= shiftout && !empty;
	assign shiftin_clean	= shiftin  && !full;

	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			wp										<= {LG_ENTRIES+1 {1'b0}};
			full									<= 1'b0;
			empty									<= 1'b1;
			almost_empty							<= 1'b1;
			almost_full								<= 1'b0;
			almost_full_nxt							<= 1'b0;
`ifdef ASIC
			for (i=0; i<ENTRIES; i=i+1)
				entry[i]							<= {DSIZE {1'b0}};
`endif
		end
		else if (clr)
		begin
			wp										<= {LG_ENTRIES+1 {1'b0}};
			full									<= 1'b0;
			empty									<= 1'b1;
			almost_empty							<= 1'b1;
			almost_full								<= 1'b0;
			almost_full_nxt							<= 1'b0;
//`ifdef ASIC
//			for (i=0; i<ENTRIES; i=i+1)
//				entry[i]							<= {DSIZE {1'b0}};
//`endif
		end
		else
		begin
			case ({shiftin_clean, shiftout_clean})
				2'b01: // only shift-out, move entries, decrement WP if not already 0 and check status signals
				begin
					for (i=1; i<ENTRIES; i=i+1)
						entry[i-1]					<= entry[i];

					if (|wp)
						wp							<= wp - 1'b1;

					empty							<= (wp == {{LG_ENTRIES {1'b0}}, 1'b1});
					full							<= 1'b0;
					almost_full						<= (wp >= ENTRIES+1-ALMOST_FULL_VAL);
					almost_full_nxt					<= (wp >= ENTRIES+1-ALMOST_FULL_VAL-1);
					almost_empty					<= (wp < ALMOST_EMTPY_VAL + 2);
				end

				2'b10: // only shift-in, write at next free entry, increment WP and check status signals
				begin
					entry[wp[LG_ENTRIES-1:0]]		<= din;
					wp								<= wp + 1'b1;
					empty							<= 1'b0;
					full							<= (wp >= ENTRIES - 1);
					almost_full						<= (wp >= ENTRIES-1-ALMOST_FULL_VAL);
					almost_full_nxt					<= (wp >= ENTRIES-1-ALMOST_FULL_VAL-1);
					almost_empty					<= (wp < ALMOST_EMTPY_VAL);
				end

				2'b11: //simultaneous shift-in and -out, move entries through shift registers
				begin
					for (i=1; i<ENTRIES; i=i+1)
						entry[i-1]					<= entry[i];

					entry[wp[LG_ENTRIES-1:0]-1'b1]	<= din;
				end

//				default: ;
			endcase
		end
	end

`ifdef CAG_COVERAGE
	full_cov:				cover property (@(posedge clk) disable iff(!res_n || clr) (full == 1'b1));
	almost_full_cov:		cover property (@(posedge clk) disable iff(!res_n || clr) (almost_full == 1'b1));
	almost_full_nxt_cov:	cover property (@(posedge clk) disable iff(!res_n || clr) (almost_full_nxt == 1'b1));
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

	// when the FIFO signals empty, it must logically also be almost empty
	empty_means_aempty : assert property (@(posedge clk) disable iff(!res_n || clr) empty |-> almost_empty);

	wp_eq_0_means_empty_A : assert property (@(posedge clk) disable iff(!res_n || clr) (wp==0) |-> empty);
	wp_eq_0_means_empty_B : assert property (@(posedge clk) disable iff(!res_n || clr) empty |-> (wp==0));

	aempty_condition_A : assert property (@(posedge clk) disable iff(!res_n || clr) (wp>ALMOST_EMTPY_VAL) |-> !almost_empty);
	aempty_condition_B : assert property (@(posedge clk) disable iff(!res_n || clr) !almost_empty |-> (wp>ALMOST_EMTPY_VAL));

	shift_in_and_full:			assert property (@(posedge clk) disable iff(!res_n || clr) (shiftin |-> !full));

	if (DISABLE_SHIFT_OUT_ASSERT == 0)
		shift_out_and_empty:	assert property (@(posedge clk) disable iff(!res_n || clr) (shiftout |-> !empty));

      if (DISABLE_XCHECK_ASSERT == 0)
	dout_known:					assert property (@(posedge clk) disable iff(!res_n || clr) (!empty |-> !$isunknown(dout)));
      if (DISABLE_XCHECK_ASSERT == 0)
	dout_nxt_known:				assert property (@(posedge clk) disable iff(!res_n || clr) (!almost_empty |-> !$isunknown(dout_nxt)));

	property dout_dout_nxt_behaviour;
		logic [DSIZE-1:0]	prev_value;

		@(posedge clk) disable iff(!res_n || clr)
			(shiftout && (wp>1), prev_value = dout_nxt) |=> (dout === prev_value);
	endproperty
	assert_dout_dout_nxt_behaviour:			assert property(dout_dout_nxt_behaviour);

	property dout_dout_nxt_behaviour_wp1;
		logic [DSIZE-1:0]	prev_value;

		@(posedge clk) disable iff(!res_n || clr)
			(shiftout && (wp==1) && shiftin, prev_value = din) |=> (dout === prev_value);
	endproperty
	assert_dout_dout_nxt_behaviour_wp1:			assert property(dout_dout_nxt_behaviour_wp1);


	final
	begin
		if (DISABLE_FULL_ASSERT == 0)
		begin
			assert_full_set:				assert (!full);
			assert_almost_full_set:			assert (!almost_full);
			assert_almost_full_nxt_set:		assert (!almost_full_nxt);
		end

		if (DISABLE_EMPTY_ASSERT == 0)
		begin
			assert_write_pointer_not_zero:	assert (wp == 0);
			assert_almost_empty_not_set:	assert (almost_empty);
			assert_empty_not_set:			assert (empty);
		end
	end
`endif // CAG_ASSERTIONS

endmodule

`default_nettype wire
