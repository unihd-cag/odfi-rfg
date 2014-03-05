module ramRF_tb();

    parameter PERIOD =10;
    integer i;
    reg res_n;
    reg clk = 0;
    reg[8:3] address;
    wire[63:0] read_data;
    wire invalid_address;
    reg read_en;
    reg write_en;
    reg[63:0] write_data;
    reg[4:0] TestRAM_addr;
    reg TestRAM_ren;
    wire[15:0] TestRAM_rdata;
    reg TestRAM_wen;
    reg[15:0] TestRAM_wdata;

    ramRF ramRF_I (
        .res_n(res_n),
        .clk(clk),
        .address(address),
        .read_data(read_data),
        .invalid_address(invalid_address),
        .access_complete(access_complete),
        .read_en(read_en),
        .write_en(write_en),
        .write_data(write_data),
        .TestRAM_addr(TestRAM_addr),
        .TestRAM_ren(TestRAM_ren),
        .TestRAM_rdata(TestRAM_rdata),
        .TestRAM_wen(TestRAM_wen),
        .TestRAM_wdata(TestRAM_wdata)
    );

    always
    begin
        #(PERIOD/2) clk <= ~clk;
    end

    initial
    begin
        $dumpfile("ramRF.vcd");
        $dumpvars(0,ramRF_tb);
        res_n <= 1'b0;
        address <= 0;
        read_en <=1'b0;
        write_en <= 1'b0;
        write_data <= 0;
        TestRAM_addr <= 0;
        TestRAM_ren <= 1'b0;
        TestRAM_wen <=1'b0;
        #40
        @(negedge(clk));
        res_n <= 1'b1;
        write_en <= 1'b1;
        for(i=32;i<64;i=i+1)
        begin
        	address <= i;
        	write_data <= i;
        	@(negedge(clk));
        end
        write_en <= 1'b0;
        TestRAM_ren <= 1'b1;
        TestRAM_wdata <= 0;
        for(i=0;i<32;i=i+1)
        begin
        	TestRAM_addr <= i;
        	@(negedge(clk));
            if (TestRAM_rdata != i+32) 
            begin
                $error("TestRAM_rdata does not match the written data...");
                $stop;
            end
        end
        TestRAM_ren <= 1'b0;
        TestRAM_wen <= 1'b1;
        for(i=0;i<32;i=i+1)
        begin
        	TestRAM_addr <= i;
        	TestRAM_wdata <= i;
        	@(negedge(clk));
        end
        TestRAM_wen <= 1'b0;
        read_en <= 1'b1;
        for(i=32;i<64;i=i+1)
        begin
        	read_en <= 1'b1;
        	address <= i;
        	while(access_complete == 0)
        	begin
        		@(negedge(clk));
        		read_en <= 1'b0;
        	end
            if (read_data != i-32) begin
                $error("read_data does not match written data...");
                $stop;
            end
        	read_en <= 1'b0;
        	@(negedge(clk));
        end
        #200
        $stop;
    end

endmodule