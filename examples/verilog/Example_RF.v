

/* auto generated by RFG */
/* address map
GPR_0: base: 0x0 size: 8
GPR_1: base: 0x8 size: 8
GPR_2: base: 0x10 size: 8
GPR_3: base: 0x18 size: 8
GPR_4: base: 0x20 size: 8
GPR_5: base: 0x28 size: 8
GPR_6: base: 0x30 size: 8
GPR_7: base: 0x38 size: 8
GPR_8: base: 0x40 size: 8
GPR_9: base: 0x48 size: 8
GPR_10: base: 0x50 size: 8
GPR_11: base: 0x58 size: 8
GPR_12: base: 0x60 size: 8
GPR_13: base: 0x68 size: 8
GPR_14: base: 0x70 size: 8
GPR_15: base: 0x78 size: 8
RAM: base: 0x800 size: 2048

*/
/* instantiation template
Example_RF Example_RF_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
	.GPR_0_GPF_next(),
	.GPR_0_GPF(),
	.GPR_0_GPF_wen(),
	.GPR_0_GPF_written(),
	.GPR_1_GPF_next(),
	.GPR_1_GPF(),
	.GPR_1_GPF_wen(),
	.GPR_1_GPF_written(),
	.GPR_2_GPF_next(),
	.GPR_2_GPF(),
	.GPR_2_GPF_wen(),
	.GPR_2_GPF_written(),
	.GPR_3_GPF_next(),
	.GPR_3_GPF(),
	.GPR_3_GPF_wen(),
	.GPR_3_GPF_written(),
	.GPR_4_GPF_next(),
	.GPR_4_GPF(),
	.GPR_4_GPF_wen(),
	.GPR_4_GPF_written(),
	.GPR_5_GPF_next(),
	.GPR_5_GPF(),
	.GPR_5_GPF_wen(),
	.GPR_5_GPF_written(),
	.GPR_6_GPF_next(),
	.GPR_6_GPF(),
	.GPR_6_GPF_wen(),
	.GPR_6_GPF_written(),
	.GPR_7_GPF_next(),
	.GPR_7_GPF(),
	.GPR_7_GPF_wen(),
	.GPR_7_GPF_written(),
	.GPR_8_GPF_next(),
	.GPR_8_GPF(),
	.GPR_8_GPF_wen(),
	.GPR_8_GPF_written(),
	.GPR_9_GPF_next(),
	.GPR_9_GPF(),
	.GPR_9_GPF_wen(),
	.GPR_9_GPF_written(),
	.GPR_10_GPF_next(),
	.GPR_10_GPF(),
	.GPR_10_GPF_wen(),
	.GPR_10_GPF_written(),
	.GPR_11_GPF_next(),
	.GPR_11_GPF(),
	.GPR_11_GPF_wen(),
	.GPR_11_GPF_written(),
	.GPR_12_GPF_next(),
	.GPR_12_GPF(),
	.GPR_12_GPF_wen(),
	.GPR_12_GPF_written(),
	.GPR_13_GPF_next(),
	.GPR_13_GPF(),
	.GPR_13_GPF_wen(),
	.GPR_13_GPF_written(),
	.GPR_14_GPF_next(),
	.GPR_14_GPF(),
	.GPR_14_GPF_wen(),
	.GPR_14_GPF_written(),
	.GPR_15_GPF_next(),
	.GPR_15_GPF(),
	.GPR_15_GPF_wen(),
	.GPR_15_GPF_written(),
	.RAM_addr(),
	.RAM_ren(),
	.RAM_rdata(),
	.RAM_wen(),
	.RAM_wdata()
);
*/
module Example_RF
(
	///\defgroup sys
	///@{ 
	input wire res_n,
	input wire clk,
	///}@ 
	///\defgroup rw_if
	///@{ 
	input wire[11:3] address,
	output reg[31:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[31:0] write_data,
	///}@ 
	input wire[31:0] GPR_0_GPF_next,
	output reg[31:0] GPR_0_GPF,
	input wire GPR_0_GPF_wen,
	output reg GPR_0_GPF_written,
	input wire[31:0] GPR_1_GPF_next,
	output reg[31:0] GPR_1_GPF,
	input wire GPR_1_GPF_wen,
	output reg GPR_1_GPF_written,
	input wire[31:0] GPR_2_GPF_next,
	output reg[31:0] GPR_2_GPF,
	input wire GPR_2_GPF_wen,
	output reg GPR_2_GPF_written,
	input wire[31:0] GPR_3_GPF_next,
	output reg[31:0] GPR_3_GPF,
	input wire GPR_3_GPF_wen,
	output reg GPR_3_GPF_written,
	input wire[31:0] GPR_4_GPF_next,
	output reg[31:0] GPR_4_GPF,
	input wire GPR_4_GPF_wen,
	output reg GPR_4_GPF_written,
	input wire[31:0] GPR_5_GPF_next,
	output reg[31:0] GPR_5_GPF,
	input wire GPR_5_GPF_wen,
	output reg GPR_5_GPF_written,
	input wire[31:0] GPR_6_GPF_next,
	output reg[31:0] GPR_6_GPF,
	input wire GPR_6_GPF_wen,
	output reg GPR_6_GPF_written,
	input wire[31:0] GPR_7_GPF_next,
	output reg[31:0] GPR_7_GPF,
	input wire GPR_7_GPF_wen,
	output reg GPR_7_GPF_written,
	input wire[31:0] GPR_8_GPF_next,
	output reg[31:0] GPR_8_GPF,
	input wire GPR_8_GPF_wen,
	output reg GPR_8_GPF_written,
	input wire[31:0] GPR_9_GPF_next,
	output reg[31:0] GPR_9_GPF,
	input wire GPR_9_GPF_wen,
	output reg GPR_9_GPF_written,
	input wire[31:0] GPR_10_GPF_next,
	output reg[31:0] GPR_10_GPF,
	input wire GPR_10_GPF_wen,
	output reg GPR_10_GPF_written,
	input wire[31:0] GPR_11_GPF_next,
	output reg[31:0] GPR_11_GPF,
	input wire GPR_11_GPF_wen,
	output reg GPR_11_GPF_written,
	input wire[31:0] GPR_12_GPF_next,
	output reg[31:0] GPR_12_GPF,
	input wire GPR_12_GPF_wen,
	output reg GPR_12_GPF_written,
	input wire[31:0] GPR_13_GPF_next,
	output reg[31:0] GPR_13_GPF,
	input wire GPR_13_GPF_wen,
	output reg GPR_13_GPF_written,
	input wire[31:0] GPR_14_GPF_next,
	output reg[31:0] GPR_14_GPF,
	input wire GPR_14_GPF_wen,
	output reg GPR_14_GPF_written,
	input wire[31:0] GPR_15_GPF_next,
	output reg[31:0] GPR_15_GPF,
	input wire GPR_15_GPF_wen,
	output reg GPR_15_GPF_written,
	input wire[7:0] RAM_addr,
	input wire RAM_ren,
	output wire[15:0] RAM_rdata,
	input wire RAM_wen,
	input wire[15:0] RAM_wdata

);

	reg[7:0] RAM_rf_addr;
	reg RAM_rf_ren;
	wire[15:0] RAM_rf_rdata;
	reg RAM_rf_wen;
	reg[15:0] RAM_rf_wdata;
	reg read_en_dly0;
	reg read_en_dly1;
	reg read_en_dly2;

	ram_2rw_1c #(
		.DATASIZE(16),
		.ADDRSIZE(8),
		.PIPELINED(0)
	) RAM (
		.clk(clk),
		.wen_a(RAM_rf_wen),
		.ren_a(RAM_rf_ren),
		.addr_a(RAM_rf_addr),
		.wdata_a(RAM_rf_wdata),
		.rdata_a(RAM_rf_rdata),
		.wen_b(RAM_wen),
		.ren_b(RAM_ren),
		.addr_b(RAM_addr),
		.wdata_b(RAM_wdata),
		.rdata_b(RAM_rdata)
	);


	/* register GPR_0 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_0_GPF <= 32'h0;
			GPR_0_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 0) && write_en)
			begin
				GPR_0_GPF <= write_data[31:0];
			end
			else if(GPR_0_GPF_wen)
			begin
				GPR_0_GPF <= GPR_0_GPF_next;
			end
			if((address[11:3]== 0) && write_en)
			begin
				GPR_0_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_0_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_1 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_1_GPF <= 32'h0;
			GPR_1_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 1) && write_en)
			begin
				GPR_1_GPF <= write_data[31:0];
			end
			else if(GPR_1_GPF_wen)
			begin
				GPR_1_GPF <= GPR_1_GPF_next;
			end
			if((address[11:3]== 1) && write_en)
			begin
				GPR_1_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_1_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_2 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_2_GPF <= 32'h0;
			GPR_2_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 2) && write_en)
			begin
				GPR_2_GPF <= write_data[31:0];
			end
			else if(GPR_2_GPF_wen)
			begin
				GPR_2_GPF <= GPR_2_GPF_next;
			end
			if((address[11:3]== 2) && write_en)
			begin
				GPR_2_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_2_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_3 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_3_GPF <= 32'h0;
			GPR_3_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 3) && write_en)
			begin
				GPR_3_GPF <= write_data[31:0];
			end
			else if(GPR_3_GPF_wen)
			begin
				GPR_3_GPF <= GPR_3_GPF_next;
			end
			if((address[11:3]== 3) && write_en)
			begin
				GPR_3_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_3_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_4 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_4_GPF <= 32'h0;
			GPR_4_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 4) && write_en)
			begin
				GPR_4_GPF <= write_data[31:0];
			end
			else if(GPR_4_GPF_wen)
			begin
				GPR_4_GPF <= GPR_4_GPF_next;
			end
			if((address[11:3]== 4) && write_en)
			begin
				GPR_4_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_4_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_5 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_5_GPF <= 32'h0;
			GPR_5_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 5) && write_en)
			begin
				GPR_5_GPF <= write_data[31:0];
			end
			else if(GPR_5_GPF_wen)
			begin
				GPR_5_GPF <= GPR_5_GPF_next;
			end
			if((address[11:3]== 5) && write_en)
			begin
				GPR_5_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_5_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_6 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_6_GPF <= 32'h0;
			GPR_6_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 6) && write_en)
			begin
				GPR_6_GPF <= write_data[31:0];
			end
			else if(GPR_6_GPF_wen)
			begin
				GPR_6_GPF <= GPR_6_GPF_next;
			end
			if((address[11:3]== 6) && write_en)
			begin
				GPR_6_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_6_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_7 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_7_GPF <= 32'h0;
			GPR_7_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 7) && write_en)
			begin
				GPR_7_GPF <= write_data[31:0];
			end
			else if(GPR_7_GPF_wen)
			begin
				GPR_7_GPF <= GPR_7_GPF_next;
			end
			if((address[11:3]== 7) && write_en)
			begin
				GPR_7_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_7_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_8 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_8_GPF <= 32'h0;
			GPR_8_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 8) && write_en)
			begin
				GPR_8_GPF <= write_data[31:0];
			end
			else if(GPR_8_GPF_wen)
			begin
				GPR_8_GPF <= GPR_8_GPF_next;
			end
			if((address[11:3]== 8) && write_en)
			begin
				GPR_8_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_8_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_9 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_9_GPF <= 32'h0;
			GPR_9_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 9) && write_en)
			begin
				GPR_9_GPF <= write_data[31:0];
			end
			else if(GPR_9_GPF_wen)
			begin
				GPR_9_GPF <= GPR_9_GPF_next;
			end
			if((address[11:3]== 9) && write_en)
			begin
				GPR_9_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_9_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_10 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_10_GPF <= 32'h0;
			GPR_10_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 10) && write_en)
			begin
				GPR_10_GPF <= write_data[31:0];
			end
			else if(GPR_10_GPF_wen)
			begin
				GPR_10_GPF <= GPR_10_GPF_next;
			end
			if((address[11:3]== 10) && write_en)
			begin
				GPR_10_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_10_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_11 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_11_GPF <= 32'h0;
			GPR_11_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 11) && write_en)
			begin
				GPR_11_GPF <= write_data[31:0];
			end
			else if(GPR_11_GPF_wen)
			begin
				GPR_11_GPF <= GPR_11_GPF_next;
			end
			if((address[11:3]== 11) && write_en)
			begin
				GPR_11_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_11_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_12 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_12_GPF <= 32'h0;
			GPR_12_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 12) && write_en)
			begin
				GPR_12_GPF <= write_data[31:0];
			end
			else if(GPR_12_GPF_wen)
			begin
				GPR_12_GPF <= GPR_12_GPF_next;
			end
			if((address[11:3]== 12) && write_en)
			begin
				GPR_12_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_12_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_13 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_13_GPF <= 32'h0;
			GPR_13_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 13) && write_en)
			begin
				GPR_13_GPF <= write_data[31:0];
			end
			else if(GPR_13_GPF_wen)
			begin
				GPR_13_GPF <= GPR_13_GPF_next;
			end
			if((address[11:3]== 13) && write_en)
			begin
				GPR_13_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_13_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_14 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_14_GPF <= 32'h0;
			GPR_14_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 14) && write_en)
			begin
				GPR_14_GPF <= write_data[31:0];
			end
			else if(GPR_14_GPF_wen)
			begin
				GPR_14_GPF <= GPR_14_GPF_next;
			end
			if((address[11:3]== 14) && write_en)
			begin
				GPR_14_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_14_GPF_written <= 1'b0;
			end

		end
	end

	/* register GPR_15 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			GPR_15_GPF <= 32'h0;
			GPR_15_GPF_written <= 1'b0;
		end
		else
		begin

			if((address[11:3]== 15) && write_en)
			begin
				GPR_15_GPF <= write_data[31:0];
			end
			else if(GPR_15_GPF_wen)
			begin
				GPR_15_GPF <= GPR_15_GPF_next;
			end
			if((address[11:3]== 15) && write_en)
			begin
				GPR_15_GPF_written <= 1'b1;
			end
			else
			begin
				GPR_15_GPF_written <= 1'b0;
			end

		end
	end

	/* RamBlock RAM */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			`ifdef ASIC
			RAM_rf_addr <= 8'b0;
			RAM_rf_wdata  <= 16'b0;
			`endif
			RAM_rf_wen <= 1'b0;
			RAM_rf_ren <= 1'b0;
		end
		else
		begin
			if (address[11:11] == 1)
			begin
				RAM_rf_addr <= address[10:3];
				RAM_rf_wdata <= write_data[15:0];
				RAM_rf_wen <= write_en;
				RAM_rf_ren <= read_en;
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
			read_data   <= 32'b0;
			`endif

			read_en_dly0 <= 1'b0;
			read_en_dly1 <= 1'b0;
			read_en_dly2 <= 1'b0;
		end
		else
		begin
			read_en_dly0 <= read_en;
			read_en_dly1 <= read_en_dly0;
			read_en_dly2 <= read_en_dly1;

			casex(address[11:3])
				9'h0:
				begin
					read_data[31:0] <= GPR_0_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h1:
				begin
					read_data[31:0] <= GPR_1_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h2:
				begin
					read_data[31:0] <= GPR_2_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h3:
				begin
					read_data[31:0] <= GPR_3_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h4:
				begin
					read_data[31:0] <= GPR_4_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h5:
				begin
					read_data[31:0] <= GPR_5_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h6:
				begin
					read_data[31:0] <= GPR_6_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h7:
				begin
					read_data[31:0] <= GPR_7_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h8:
				begin
					read_data[31:0] <= GPR_8_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'h9:
				begin
					read_data[31:0] <= GPR_9_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'ha:
				begin
					read_data[31:0] <= GPR_10_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'hb:
				begin
					read_data[31:0] <= GPR_11_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'hc:
				begin
					read_data[31:0] <= GPR_12_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'hd:
				begin
					read_data[31:0] <= GPR_13_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'he:
				begin
					read_data[31:0] <= GPR_14_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				9'hf:
				begin
					read_data[31:0] <= GPR_15_GPF;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				{1'h1,8'bxxxxxxxx}:
				begin
					read_data[15:0] <= RAM_rf_rdata;
					read_data[31:16] <= 16'b0;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en_dly2;
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