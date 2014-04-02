

/* auto generated by RFG */
/* address map
tsc: base: 0x0 size: 8

*/
/* instantiation template
counter_RF counter_RF_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
	.tsc_cnt_next(),
	.tsc_cnt(),
	.tsc_cnt_wen(),
	.tsc_cnt_countup()
 );
*/
module counter_RF
(
	///\defgroup sys
	///@{ 
	input wire res_n,
	input wire clk,
	///}@ 
	///\defgroup rw_if
	///@{ 
	input wire[3:3] address,
	output reg[63:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[63:0] write_data,
	///}@ 
 	input wire[47:0] tsc_cnt_next,
	output wire[47:0] tsc_cnt,
	input wire tsc_cnt_wen,
	input wire tsc_cnt_countup

);

	reg tsc_cnt_load_enable;
	reg[47:0] tsc_cnt_load_value;

	counter48 #(
		.DATASIZE(48)
	) tsc_I (
		.clk(clk),
		.res_n(res_n),
		.increment(tsc_cnt_countup),
		.load(tsc_cnt_load_value),
		.load_enable(tsc_cnt_load_enable),
		.value(tsc_cnt)
	);


	/* register tsc */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			tsc_cnt_load_enable <= 1'b0;
		end
		else
		begin

			if((address[3:3]== 0) && write_en)
			begin
				tsc_cnt_load_enable <= 1'b1;
				tsc_cnt_load_value <= write_data[47:0];
			end
			else if(tsc_cnt_wen)
			begin
				tsc_cnt_load_value <= tsc_cnt_next;
				tsc_cnt_load_enable <= 1'b1;
			end
			else
			begin
				tsc_cnt_load_enable <= 1'b0;
			end
		end
	end


	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			invalid_address <= 1'b0;
			access_complete <= 1'b0;
			`ifdef ASIC
			read_data   <= 64'b0;
			`endif

		end
		else
		begin

			casex(address[3:3])
				1'h0:
				begin
					read_data[47:0] <= tsc_cnt;
					read_data[63:48] <= 16'b0;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				default:
				begin
					invalid_address <= read_en || write_en;
					access_complete <= read_en || write_en;
				end		
			endcase
		end
	end
endmodule