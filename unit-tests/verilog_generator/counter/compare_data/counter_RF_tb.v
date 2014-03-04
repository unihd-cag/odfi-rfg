module counter_RF_tb();

    parameter PERIOD =10;
    reg res_n;
    reg clk=0;
    reg address;
    wire[63:0] read_data;
    wire invalid_address;
    wire access_complete;
    reg read_en;
    reg write_en;
    reg[63:0] write_data;
    reg[47:0] tsc_cnt_next;
    wire[47:0] tsc_cnt;
    reg tsc_cnt_wen;
    reg tsc_cnt_countup;

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
        .tsc_cnt_countup(tsc_cnt_countup));

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
        address <= 1'b0;
        #10
        res_n <= 1'b1;
        tsc_cnt_countup <= 1'b1;
        #200
        $stop;
    end

endmodule