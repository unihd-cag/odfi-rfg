

/* instantiation template
RamBlock RamBlock_I (
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
	.test_test_field(),
	.test_ram_addr(),
	.test_ram_ren(),
	.test_ram_rdata(),
	.test_ram_wen(),
	.test_ram_wdata()
);
*/
module RamBlock
(
	input wire clk,
	input wire res_n,
	// Software Interface
    input wire[10:3] address,
	output reg[31:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[31:0] write_data,
	// Hardware Interface
	input wire[31:0] test_test_field_next,
	output reg[31:0] test_test_field,
	input wire[6:0] test_ram_addr,
	input wire test_ram_ren,
	output wire[31:0] test_ram_rdata,
	input wire test_ram_wen,
	input wire[31:0] test_ram_wdata
);

	reg[6:0] test_ram_rf_addr;
	reg test_ram_rf_ren;
	wire[31:0] test_ram_rf_rdata;
	reg test_ram_rf_wen;
	reg[31:0] test_ram_rf_wdata;
	reg read_en_dly0;
	reg read_en_dly1;
	reg read_en_dly2;

	ram_2rw_1c #(
		.DATASIZE(32),
		.ADDRSIZE(7),
		.PIPELINED(0)
	) test_ram (
		.clk(clk),
		.wen_a(test_ram_rf_wen),
		.ren_a(test_ram_rf_ren),
		.addr_a(test_ram_rf_addr),
		.wdata_a(test_ram_rf_wdata),
		.rdata_a(test_ram_rf_rdata),
		.wen_b(test_ram_wen),
		.ren_b(test_ram_ren),
		.addr_b(test_ram_addr),
		.wdata_b(test_ram_wdata),
		.rdata_b(test_ram_rdata)
	);


	/* register test */
	always @(posedge clk)
	begin
		if (!res_n)
		begin
			test_test_field <= 0;
		end
		else
		begin

			if((address[10:3]== 0) && write_en)
			begin
				test_test_field <= write_data[31:0];
			end
			else
			begin
				test_test_field <= test_test_field_next;
			end
		end
	end

	/* RamBlock test_ram */
	always @(posedge clk)
	begin
		if (!res_n)
		begin
			`ifdef ASIC
			test_ram_rf_addr <= 7'b0;
			test_ram_rf_wdata  <= 32'b0;
			`endif
			test_ram_rf_wen <= 1'b0;
			test_ram_rf_ren <= 1'b0;
		end
		else
		begin
			if (address[10:10] == 1)
			begin
				test_ram_rf_addr <= address[9:3];
				test_ram_rf_wdata <= write_data[31:0];
				test_ram_rf_wen <= write_en;
				test_ram_rf_ren <= read_en;
			end
		end
	end

	always @(posedge clk)
	begin
		if (!res_n)
		begin
			invalid_address <= 1'b0;
			access_complete <= 1'b0;

			read_en_dly0 <= 1'b0;
			read_en_dly1 <= 1'b0;
			read_en_dly2 <= 1'b0;
		end
		else
		begin
			read_en_dly0 <= read_en;
			read_en_dly1 <= read_en_dly0;
			read_en_dly2 <= read_en_dly1;

			casex(address[10:3])
				8'h0:
				begin
					read_data[31:0] <= test_test_field;
					invalid_address <= 1'b0;
					access_complete <= write_en || read_en;
				end
				{1'h1,7'bxxxxxxx}:
				begin
					read_data[31:0] <= test_ram_rf_rdata;
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
