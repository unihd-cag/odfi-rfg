


/* address map
test: base[3:3] 0 size: 8

*/
/* instantiation template
reg_hrw_srw_sticky reg_hrw_srw_sticky_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
	.test_test_field_next(),
	.test_test_field()
);
*/
module reg_hrw_srw_sticky
(
	input wire res_n,
	input wire clk,
	// Software Interface
    input wire[3:3] address,
	output reg[31:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[31:0] write_data,
	// Hardware Interface
	input wire[31:0] test_test_field_next,
    input wire test_test_field_wen,
	output reg[31:0] test_test_field

);

	/* register test */
	always @(posedge clk)
	begin
		if (!res_n)
		begin
			test_test_field <= 32'h0;
		end
		else
		begin

			if((address[3:3]== 0) && write_en)
			begin
				test_test_field <= write_data[31:0];
			end
			else if(test_test_field_wen)
			begin
				test_test_field <= test_test_field_next | test_test_field;
			end
		end
	end

	always @(posedge clk)
	begin
		if (!res_n)
		begin
			invalid_address <= 1'b0;
			access_complete <= 1'b0;
		end
		else
		begin
			casex(address[3:3])
				1'h0:
				begin
					read_data[31:0] <= test_test_field;
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
