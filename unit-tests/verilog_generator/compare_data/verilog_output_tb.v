module verilog_output_tb();

    parameter PERIOD =10;
    reg res_n;
    reg clk=0;
    reg[4:3] address;
    wire[63:0] read_data;
    wire invalid_address;
    wire access_complete;
    reg read_en;
    reg write_en;
    reg[63:0] write_data;
    wire[15:0] node_id;
    reg[23:0] node_guid_next;
    reg[15:0] r1_r1_1_next;
    wire[15:0] r1_r1_1;
    reg[15:0] r1_r1_2_next;
    wire[15:0] r1_r1_2;
    wire r1_r1_2_written;
    reg[15:0] r1_r1_3_next;
    wire[15:0] r1_r1_3;
    wire r1_r1_3_written;
    reg[15:0] r1_r1_4_next;
    reg	r1_r1_4_wen;
    wire[15:0] r1_r1_4;

    info_rf info_rf_I (
	    .res_n(res_n),
	    .clk(clk),
	    .address(address),
	    .read_data(read_data),
	    .invalid_address(invalid_address),
	    .access_complete(access_complete),
	    .read_en(read_en),
	    .write_en(write_en),
	    .write_data(write_data),
	    .node_id(node_id),
	    .node_guid_next(node_guid_next),
	    .r1_r1_1_next(r1_r1_1_next),
	    .r1_r1_1(r1_r1_1),
	    .r1_r1_2_next(r1_r1_2_next),
	    .r1_r1_2(r1_r1_2),
	    .r1_r1_2_written(r1_r1_2_written),
	    .r1_r1_3_next(r1_r1_3_next),
	    .r1_r1_3(r1_r1_3),
	    .r1_r1_3_written(r1_r1_3_written),
	    .r1_r1_4_next(r1_r1_4_next),
	    .r1_r1_4_wen(r1_r1_4_wen),
	    .r1_r1_4(r1_r1_4));

    always
    begin
        #(PERIOD/2) clk <= ~clk;
    end
    
    initial
    begin
        $dumpfile("verilog_output.vcd");
        $dumpvars(0,verilog_output_tb);
        res_n <= 0;
        #20
        res_n <= 1;
        #100
        $stop;
    end

endmodule
