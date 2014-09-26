

/* auto generated by RFG */
/* address map
info_reg: base: 0x0 size: 8

*/
/* instantiation template
SingleRF SingleRF_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
	.info_reg_info_field_next(),
	.info_reg_info_field(),
	.info_reg_info_field_wen()
);
*/
module SingleRF
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
	input wire[63:0] info_reg_info_field_next,
	output reg[63:0] info_reg_info_field,
	input wire info_reg_info_field_wen

);



	/* register info_reg */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			info_reg_info_field <= 0;
		end
		else
		begin

			if((address[3:3]== 0) && write_en)
			begin
				info_reg_info_field <= write_data[63:0];
			end
			else if(info_reg_info_field_wen)
			begin
				info_reg_info_field <= info_reg_info_field_next;
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
					read_data[63:0] <= info_reg_info_field;
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