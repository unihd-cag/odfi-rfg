
module SimpleRF_tb();

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
    integer i;

    SimpleRF SimpleRF_I (
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
        $dumpfile("SimpleRF.vcd");
        $dumpvars(0,SimpleRF_tb);
        res_n <= 0;
        address <= 2'b00;
        read_en <= 1'b0;
        write_en <= 1'b0;
        write_data <= 64'b0;
        node_guid_next <= 24'b0;
        r1_r1_1_next <= 16'b0;
        r1_r1_2_next <= 16'b0;
        r1_r1_3_next <= 16'b0;
        r1_r1_4_next <= 16'b0;
        r1_r1_4_wen <= 1'b0;
        #20
        res_n <= 1;
        #20

        // software write/ hardware read
        for(i=0;  i<4; i=i+1)
		begin
            @(negedge(clk));
            address <= i;
            write_en <= 1'b1;
            write_data <= 64'h555AAA555AAA555A;
            @(negedge(clk));
            if (access_complete != 1) begin
                $error("\nERROR access_complete was not set @timestep %0d and address %0d\n",$time,i);
                $stop;
            end
            if (i == 1) begin
                if (node_id != 16'h555A) begin
                    $error("\nERROR node_id has the wrong value it should be 0x555a but it is 0x%h",node_id);
                    $stop;
                end
            end
            if (i == 2) begin
                if (r1_r1_1 != 16'h555A) begin
                    $error("\nERROR r1_r1_1 has the wrong value it should be 0x555a but it is 0x%h",r1_r1_1);
                    $stop;
                end
                if (r1_r1_2 != 16'h5AAA) begin
                    $error("\nERROR r1_r1_2 has the wrong value it should be 0x5aaa but it is 0x%h",r1_r1_2);
                    $stop;
                    if (r1_r1_2_written != 1) begin
                        $error("\nERROR r1_r1_2_written was not set");
                        $stop;
                    end
                end
                if (r1_r1_3 != 16'hAA55) begin
                    $error("\nERROR r1_r1_3 has the wrong value it should be 0xaa55 but it is 0x%h",r1_r1_3);
                    $stop;
                    if (r1_r1_3_written != 1) begin
                        $error("\nERROR r1_r1_3_written was not set");
                        $stop;
                    end
                end
                if (r1_r1_4 != 16'h555A) begin
                    $error("\nERROR r1_r1_4 has the wrong value it should be 0x555a but it is 0x%h",r1_r1_4);
                    $stop;
                end
            end
            if (i == 3) begin
                if (invalid_address == 0) begin
                    $error("\nERROR invalid_address was not set at address 3");
                    $stop;
                end
            end
            write_en <= 1'b0;
        end

        //hardware write/read
        @(negedge(clk));
        if (node_id !=16'h555A) begin
            $error("\nERROR (Hardware Write/Read) node_id has the wrong value it should be 0x555a but it is 0x%h",node_id);
            $stop;
        end
        if (r1_r1_1 !=16'h0000) begin
            $error("\nERROR (Hardware Write/Read) r1_r1_1 has the wrong value it should be 0x0000 but it is 0x%h",r1_r1_1);
            $stop;
        end
        if (r1_r1_2 !=16'h0000) begin
            $error("\nERROR (Hardware Write/Read) r1_r1_2 has the wrong value it should be 0x0000 but it is 0x%h",r1_r1_2);
            $stop;
        end
        if (r1_r1_3 !=16'h0000) begin
            $error("\nERROR (Hardware Write/Read) r1_r1_3 has the wrong value it should be 0x0000 but it is 0x%h",r1_r1_3);
            $stop;
        end
        if (r1_r1_4 !=16'h555A) begin
            $error("\nERROR (Hardware Write/Read) r1_r1_4 has the wrong value it should be 0x555a but it is 0x%h",r1_r1_4);
            $stop;
        end
        @(negedge(clk));
        r1_r1_4_wen <= 1'b1;
        @(negedge(clk));
        r1_r1_4_wen <= 1'b0;
        if (r1_r1_4 !=16'h0000) begin
            $error("\nERROR (Hardware Write/Read) r1_r1_4 has the wrong value it should be 0x0000 but it is 0x%h",r1_r1_4);
            $stop;
        end

        //software read
        for(i=0;  i<4; i=i+1)
        begin
            @(negedge(clk));
            read_en <= 1'b1;
            address <= i;
            @(negedge(clk));
            read_en <= 1'b0;
            if (access_complete != 1) begin
                $error("\nERROR (Software Read) access_complete was not set @timestep %0d and address %0d\n",$time,i);
                $stop;
            end
            if (i == 0 && read_data != 64'h000000000012ABCD) begin
                $error("\nERROR (Software Read) read_data has the wrong value");
                $stop;
            end
            if (i == 1 && read_data != 64'h000000000000555A) begin
                $error("\nERROR (Software Read) read_data has the wrong value");
                $stop;
            end
            if (i == 2 && read_data != 64'h0000000000000000) begin
                $error("\nERROR (Software Read) read_data has the wrong value");
                $stop;
            end
            if (i == 3 && invalid_address == 0) begin
                $error("\nERROR (Software Read) invalid_address was not set");
                $stop;
            end
        end
        #100
        $stop;
    end

endmodule
