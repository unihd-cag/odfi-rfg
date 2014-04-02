

/* auto generated by RFG */
/* address map
info_rf_driver: base: 0x0 size: 8
info_rf_node: base: 0x8 size: 8
info_rf_r1: base: 0x10 size: 8

*/
/* instantiation template
SimpleRF SimpleRF_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
	.info_rf_node_id(),
	.info_rf_node_guid_next(),
	.info_rf_r1_r1_1_next(),
	.info_rf_r1_r1_1(),
	.info_rf_r1_r1_2_next(),
	.info_rf_r1_r1_2(),
	.info_rf_r1_r1_2_written(),
	.info_rf_r1_r1_3_next(),
	.info_rf_r1_r1_3(),
	.info_rf_r1_r1_3_written(),
	.info_rf_r1_r1_4_next(),
	.info_rf_r1_r1_4(),
	.info_rf_r1_r1_4_wen()
 );
*/
module SimpleRF
(
	///\defgroup sys
	///@{ 
	input wire res_n,
	input wire clk,
	///}@ 
	///\defgroup rw_if
	///@{ 
	input wire[4:3] address,
	output reg[63:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[63:0] write_data,
	///}@ 
 	output reg[15:0] info_rf_node_id,
	input wire[23:0] info_rf_node_guid_next,
	input wire[15:0] info_rf_r1_r1_1_next,
	output reg[15:0] info_rf_r1_r1_1,
	input wire[15:0] info_rf_r1_r1_2_next,
	output reg[15:0] info_rf_r1_r1_2,
	output reg info_rf_r1_r1_2_written,
	input wire[15:0] info_rf_r1_r1_3_next,
	output reg[15:0] info_rf_r1_r1_3,
	output reg info_rf_r1_r1_3_written,
	input wire[15:0] info_rf_r1_r1_4_next,
	output reg[15:0] info_rf_r1_r1_4,
	input wire info_rf_r1_r1_4_wen

);

	reg[31:0] info_rf_driver_version;
	reg[23:0] info_rf_node_guid;
	reg[15:0] info_rf_node_vpids;
	reg info_rf_r1_r1_3_res_in_last_cycle;


	/* register driver */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			info_rf_driver_version <= 32'h12abcd;
		end
		else
		begin

		end
	end

	/* register node */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			info_rf_node_id <= 0;
			info_rf_node_guid <= 24'h12abcd;
			info_rf_node_vpids <= 0;
		end
		else
		begin

			if((address[4:3]== 1) && write_en)
			begin
				info_rf_node_id <= write_data[15:0];
			end
			else
			begin
				info_rf_node_guid <= info_rf_node_guid_next;
			end
		end
	end

	/* register r1 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			info_rf_r1_r1_1 <= 0;
			info_rf_r1_r1_2 <= 0;
			info_rf_r1_r1_2_written <= 1'b0;
			info_rf_r1_r1_3 <= 0;
			info_rf_r1_r1_3_written <= 1'b0;
			info_rf_r1_r1_3_res_in_last_cycle <= 1'b1;
			info_rf_r1_r1_4 <= 0;
		end
		else
		begin

			if((address[4:3]== 2) && write_en)
			begin
				info_rf_r1_r1_1 <= write_data[15:0];
			end
			else
			begin
				info_rf_r1_r1_1 <= info_rf_r1_r1_1_next;
			end
			if((address[4:3]== 2) && write_en)
			begin
				info_rf_r1_r1_2 <= write_data[31:16];
			end
			else
			begin
				info_rf_r1_r1_2 <= info_rf_r1_r1_2_next;
			end
			if((address[4:3]== 2) && write_en)
			begin
				info_rf_r1_r1_2_written <= 1'b1;
			end
			else
			begin
				info_rf_r1_r1_2_written <= 1'b0;
			end

			if((address[4:3]== 2) && write_en)
			begin
				info_rf_r1_r1_3 <= write_data[47:32];
			end
			else
			begin
				info_rf_r1_r1_3 <= info_rf_r1_r1_3_next;
			end
			if(((address[4:3]== 2) && write_en) || info_rf_r1_r1_3_res_in_last_cycle)
			begin
				info_rf_r1_r1_3_written <= 1'b1;
				info_rf_r1_r1_3_res_in_last_cycle <= 1'b0;
			end
			else
			begin
				info_rf_r1_r1_3_written <= 1'b0;
			end

			if((address[4:3]== 2) && write_en)
			begin
				info_rf_r1_r1_4 <= write_data[63:48];
			end
			else if(info_rf_r1_r1_4_wen)
			begin
				info_rf_r1_r1_4 <= info_rf_r1_r1_4_next;
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

			casex(address[4:3])
				2'h0:
				begin
					read_data[31:0] <= info_rf_driver_version;
					read_data[63:32] <= 32'b0;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				2'h1:
				begin
					read_data[15:0] <= info_rf_node_id;
					read_data[39:16] <= info_rf_node_guid;
					read_data[55:40] <= info_rf_node_vpids;
					read_data[63:56] <= 8'b0;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				2'h2:
				begin
					read_data[15:0] <= info_rf_r1_r1_1;
					read_data[31:16] <= info_rf_r1_r1_2;
					read_data[47:32] <= info_rf_r1_r1_3;
					read_data[63:48] <= info_rf_r1_r1_4;
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