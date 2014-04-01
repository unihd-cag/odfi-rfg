

/* auto generated by RFG */
/* address map
g1_r1: base: 0x0 size: 8
g1_r2: base: 0x8 size: 8

*/
/* instantiation template
testing testing_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
	.g1_r1_f1_next(),
	.g1_r1_f1(),
	.g1_r1_f1_wen(),
	.g1_r1_f1_countup(),
	.g1_r1_f2_next(),
	.g1_r1_f2(),
	.g1_r2_f1_next(),
	.g1_r2_f1()

);
*/
module testing
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
	input wire[62:0] g1_r1_f1_next,
	output wire[62:0] g1_r1_f1,
	input wire g1_r1_f1_wen,
	input wire g1_r1_f1_countup,
	input wire g1_r1_f2_next,
	output reg g1_r1_f2,
	input wire[63:0] g1_r2_f1_next,
	output reg[63:0] g1_r2_f1


);

	reg g1_r1_f1_load_enable;
	reg[62:0] g1_r1_f1_load_value;

	counter48 #(
		.DATASIZE(63)
	) g1_r1_I (
		.clk(clk),
		.res_n(res_n),
		.increment(g1_r1_f1_countup),
		.load(g1_r1_f1_load_value),
		.load_enable(g1_r1_f1_load_enable),
		.value(g1_r1_f1)
	);


	/* register r1 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			g1_r1_f1_load_enable <= 1'b0;
			g1_r1_f2 <= 0;
		end
		else
		begin

			if((address[3:3]== 0) && write_en)
			begin
				g1_r1_f1_load_enable <= 1'b1;
				g1_r1_f1_load_value <= write_data[62:0];
			end
			else if(g1_r1_f1_wen)
			begin
				g1_r1_f1_load_value <= g1_r1_f1_next;
				g1_r1_f1_load_enable <= 1'b1;
			end
			else
			begin
				g1_r1_f1_load_enable <= 1'b0;
			end
			if((address[3:3]== 0) && write_en)
			begin
				g1_r1_f2 <= (write_data[63:63]^g1_r1_f2);
			end
			else
			begin
				g1_r1_f2 <= g1_r1_f2_next;
			end
		end
	end

	/* register r2 */
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			g1_r2_f1 <= 0;
		end
		else
		begin

			if((address[3:3]== 1) && write_en)
			begin
				g1_r2_f1 <= write_data[63:0];
			end
			else
			begin
				g1_r2_f1 <= g1_r2_f1_next;
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
					read_data[62:0] <= g1_r1_f1;
					read_data[63:63] <= g1_r1_f2;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				1'h1:
				begin
					read_data[63:0] <= g1_r2_f1;
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