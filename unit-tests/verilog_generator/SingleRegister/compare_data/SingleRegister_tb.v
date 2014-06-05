// Author: Tobias Markus
module SingleRegister_tb();

    parameter PERIOD =10;
    reg res_n;
    reg clk = 0;
    reg[3:3] address;
    wire[63:0] read_data;
    wire invalid_address;
    reg read_en;
    reg write_en;
    reg[63:0] write_data;
    reg[63:0] info_reg_info_field_next;
    wire[63:0] info_reg_info_field;
    reg info_reg_info_field_wen;

    SingleRF SingleRF_I (
        .res_n(res_n),
        .clk(clk),
        .address(address),
        .read_data(read_data),
        .invalid_address(invalid_address),
        .access_complete(access_complete),
        .read_en(read_en),
        .write_en(write_en),
        .write_data(write_data),
        .info_reg_info_field_next(info_reg_info_field_next),
        .info_reg_info_field(info_reg_info_field),
        .info_reg_info_field_wen(info_reg_info_field_wen)
    );

    always
    begin
        #(PERIOD/2) clk <= ~clk;
    end

    initial
    begin
        $dumpfile("SingleRegister.vcd");
        $dumpvars(0,SingleRegister_tb);
        res_n <= 1'b0;
        address <= 0;
        read_en <=1'b0;
        write_en <= 1'b0;
        write_data <= 0;
        #40
        @(negedge(clk));
        res_n <= 1'b1;
        address <= 0;
        write_en <= 1'b1;
        write_data <= 64'h555AAA555AAA555A;
        @(negedge(clk));
        if (access_complete != 1)
        begin
            $error("\nERROR access_complete was not set @timestep %0d and address 0\n",$time);
            $stop;
        end
        if(info_reg_info_field != 64'h555AAA555AAA555A)
        begin
            $error("\nERROR info_reg_info_field does not have to correct value...");
            $stop;
        end
        write_en <= 1'b0;
        info_reg_info_field_wen <= 1'b1;
        @(negedge(clk));
        info_reg_info_field_wen <= 1'b0;
        @(negedge(clk));
        read_en <= 1'b1;
        address <= 0;
        @(negedge(clk));
        read_en <= 1'b0;
        if (access_complete != 1)
        begin
            $error("\nERROR (Software Read) access_complete was not set @timestep %0d and address 0\n",$time);
            $stop;
        end
        if (read_data != 0)
        begin
            $error("\nERROR (Software Read) access_complete was not set @timestep %0d and address 0\n",$time);
            $stop;
        end
        @(negedge(clk));
        read_en <= 1'b1;
        address <= 1;
        @(negedge(clk));
        read_en <= 1'b0;
        if(invalid_address != 1)
        begin
            $error("\nERROR (Software Read) invalid_address was not set");
            $stop;
        end
        #100
        $stop;
    end
endmodule