// Author: Tobias Markus
module counter_RF_tb();

    parameter PERIOD =10;
    integer i;

    reg res_n;
    reg clk=0;
    reg[5:3] address;
    wire[47:0] read_data;
    wire invalid_address;
    wire access_complete;
    reg read_en;
    reg write_en;
    reg[47:0] write_data;

    reg[47:0] tsc_cnt_next;
    wire[47:0] tsc_cnt;
    reg tsc_cnt_wen;
    reg tsc_cnt_countup;

    reg tsc2_cnt_countup;

    reg tsc3_cnt_countup;

    reg[47:0] tsc4_cnt_next;
    wire[47:0] tsc4_cnt;
    reg tsc4_cnt_wen;
    reg tsc4_cnt_countup;

    counter_RF counter_RF_I (
    .res_n(res_n),
    .clk(clk),
    .address(address),
    .read_data(read_data),
    .invalid_address(invalid_address),
    .access_complete(access_complete),
    .read_en(read_en),
    .write_en(write_en),
    .write_data(write_data),
    .tsc_cnt_next(tsc_cnt_next),
    .tsc_cnt(tsc_cnt),
    .tsc_cnt_wen(tsc_cnt_wen),
    .tsc_cnt_countup(tsc_cnt_countup),
    .tsc2_cnt_countup(tsc2_cnt_countup),
    .tsc3_cnt_countup(tsc3_cnt_countup),
    .tsc4_cnt_next(tsc4_cnt_next),
    .tsc4_cnt(tsc4_cnt),
    .tsc4_cnt_wen(tsc4_cnt_wen),
    .tsc4_cnt_countup(tsc4_cnt_countup)
);

    always
    begin
        #(PERIOD/2) clk <= ~clk;
    end

    initial
    begin
        $dumpfile("counter_RF.vcd");
        $dumpvars(0,counter_RF_tb);
        res_n <= 1'b0;
        read_en <= 1'b0;
        write_en <= 1'b0;
        tsc_cnt_wen <= 1'b0;
        tsc4_cnt_wen <= 1'b0;
        address <= 3'b0;
        #10
        res_n <= 1'b1;
        tsc_cnt_countup <= 1'b1;
        tsc2_cnt_countup <= 1'b1;
        tsc3_cnt_countup <= 1'b1;
        tsc4_cnt_countup <= 1'b1;
        for(i=0;i<200;i=i+1)
        begin
            @(negedge(clk));
            if (tsc_cnt != i || tsc4_cnt != i) begin
                $error("tsc_cnt or tsc4_cnt does not match counting value i...");
                $stop;
            end
        end
        tsc_cnt_countup <= 1'b0;
        tsc2_cnt_countup <= 1'b0;
        tsc3_cnt_countup <= 1'b0;
        tsc4_cnt_countup <= 1'b0;
        address <= 3'h2;
        read_en <= 1'b1;
        @(negedge(clk));
        if(read_data != 199)
        begin
            $error("tsc2 does not match 199");
            $stop;
        end
        address <= 3'h3;
        @(negedge(clk));
        if(read_data != 199)
        begin
            $error("tsc3 does not match 199");
            $stop;
        end
        read_en <= 1'b0;
        tsc_cnt_wen <= 1'b1;
        tsc4_cnt_wen <= 1'b1;
        tsc_cnt_next <= 400;
        tsc4_cnt_next <= 400;
        @(negedge(clk));
        @(negedge(clk));
        tsc_cnt_countup <= 1'b1;
        tsc4_cnt_countup <= 1'b1;
        tsc_cnt_wen <= 1'b0;
        tsc4_cnt_wen <= 1'b0;
        @(negedge(clk));
        for(i=401;i<600;i=i+1)
        begin
            @(negedge(clk));
            if (tsc_cnt != i || tsc4_cnt != i)
            begin
                $error("tsc_cnt or tsc4_cnt does not macht conting value after load");
                $stop;
            end
        end
        tsc_cnt_countup <= 1'b0;
        tsc2_cnt_countup <= 1'b0;
        tsc3_cnt_countup <= 1'b0;
        tsc4_cnt_countup <= 1'b0;
        address <= 3'h1;
        write_en <= 1'b1;
        @(negedge(clk));
        write_en <= 1'b0;
        @(negedge(clk));
        @(negedge(clk));
        if(tsc_cnt != 599 || tsc4_cnt != 0)
        begin
            $error("tsc_cnt or tsc4_cnt does not match value after rreinit");
            //$stop;
        end
        address <= 3'h2;
        read_en <= 1'b1;
        @(negedge(clk));
        if(read_data != 0)
        begin
            $error("tsc2 does not match zero after rreinit");
            $stop;
        end
        address <= 3'h3;
        @(negedge(clk));
        if(read_data != 0)
        begin
            $error("tsc3 does not match zero after rreinit");
            $stop;
        end
        read_en <= 1'b0;
        $stop;
    end

endmodule