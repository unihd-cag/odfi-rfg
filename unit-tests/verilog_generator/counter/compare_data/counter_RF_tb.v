module SimpleRF_tb();

    parameter PERIOD =10;
    reg res_n;
    reg clk;
    reg address;
    wire[63:0] read_data;
    wire invalid_address;
    wire access_complete;
    reg read_en;
    reg write_en;
    reg[63:0] write_data;
    ///}@
    reg[47:0] tsc_cnt_next;
    wire[47:0] tsc_cnt;
    reg tsc_cnt_wen;
    reg tsc_cnt_countup;

    always
    begin
        #(PERIOD/2) clk <= ~clk;
    end

    initial
    begin

    end

endmodule