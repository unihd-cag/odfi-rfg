	.RamBlockRF_external_invalid_address(),
	.RamBlockRF_external_access_complete(),
	.RamBlockRF_external_read_en(),
	.RamBlockRF_external_read_data(),
	.RamBlockRF_external_write_en(),
	.RamBlockRF_external_write_data(),
	.RamBlockRF_internal_test_test_field(),
	.RamBlockRF_internal_test_test_field_next(),
	.RamBlockRF_internal_test_test_field_wen(),
	.RamBlockRF_internal_test_ram_addr(),
	.RamBlockRF_internal_test_ram_ren(),
	.RamBlockRF_internal_test_ram_rdata(),
	.RamBlockRF_internal_test_ram_wen(),
	.RamBlockRF_internal_test_ram_wdata()
);
*/






module RF (
    input wire clk,
    input wire res_n,
    input wire[11:3] address,
    output reg invalid_address,
    output reg access_complete,
    input wire read_en,
    output reg[31:0] read_data,
    input wire write_en,
    input wire[31:0] write_data,
    output reg[10:3] RamBlockRF_external_address,
    input wire RamBlockRF_external_invalid_address,
    input wire RamBlockRF_external_access_complete,
    output reg RamBlockRF_external_read_en,
    input wire[31:0] RamBlockRF_external_read_data,
    output reg RamBlockRF_external_write_en,
    output reg[31:0] RamBlockRF_external_write_data,
    output wire[31:0] RamBlockRF_internal_test_test_field,
    input wire[31:0] RamBlockRF_internal_test_test_field_next,
    input wire RamBlockRF_internal_test_test_field_wen,
    input wire[6:0] RamBlockRF_internal_test_ram_addr,
    input wire RamBlockRF_internal_test_ram_ren,
    output wire[31:0] RamBlockRF_internal_test_ram_rdata,
    input wire RamBlockRF_internal_test_ram_wen,
    input wire[31:0] RamBlockRF_internal_test_ram_wdata
);
    reg[10:3] RamBlockRF_internal_address;
    wire RamBlockRF_internal_invalid_address;
    wire RamBlockRF_internal_access_complete;
    reg RamBlockRF_internal_read_en;
    wire[31:0] RamBlockRF_internal_read_data;
    reg RamBlockRF_internal_write_en;
    reg[31:0] RamBlockRF_internal_write_data;
    
    RamBlockRF_internal RamBlockRF_internal_I (
    	.res_n(res_n),
    	.clk(clk),
    	.address(RamBlockRF_internal_address),
    	.read_data(RamBlockRF_internal_read_data),
    	.invalid_address(RamBlockRF_internal_invalid_address),
    	.access_complete(RamBlockRF_internal_access_complete),
    	.read_en(RamBlockRF_internal_read_en),
    	.write_en(RamBlockRF_internal_write_en),
    	.write_data(RamBlockRF_internal_write_data),
	    .RamBlockRF_internal_test_test_field_next(RamBlockRF_internal_test_test_field_next),
	    .RamBlockRF_internal_test_test_field(RamBlockRF_internal_test_test_field),
	    .RamBlockRF_internal_test_test_field_wen(RamBlockRF_internal_test_test_field_wen),
	    .RamBlockRF_internal_test_ram_addr(RamBlockRF_internal_test_ram_addr),
	    .RamBlockRF_internal_test_ram_ren(RamBlockRF_internal_test_ram_ren),
	    .RamBlockRF_internal_test_ram_rdata(RamBlockRF_internal_test_ram_rdata),
	    .RamBlockRF_internal_test_ram_wen(RamBlockRF_internal_test_ram_wen),
	    .RamBlockRF_internal_test_ram_wdata(RamBlockRF_internal_test_ram_wdata)
    );
    
    
    //RegisterFile: RamBlockRF_external
    always @(posedge clk)
    begin
        
        if(!res_n)
        begin
            RamBlockRF_external_write_en <= 1'b0;
            RamBlockRF_external_read_en <= 1'b0;
            RamBlockRF_external_write_data <= 32'b0;
            RamBlockRF_external_address <= 8'b0;
        end
        else
        begin
            
            if(address[11:11] == 1'h0)
            begin
                RamBlockRF_external_address <= address[10:3];
            end
            
            if((address[11:11] == 1'h0) && write_en)
            begin
                RamBlockRF_external_write_data <= write_data[31:0];
                RamBlockRF_external_write_en <= 1'b1;
            end
            else
            begin
                RamBlockRF_external_write_en <= 1'b0;
            end
            
            if((address[11:11] == 1'h0) && read_en)
            begin
                RamBlockRF_external_read_en <= 1'b1;
            end
            else
            begin
                RamBlockRF_external_read_en <= 1'b0;
            end
        end

    end
    
    //RegisterFile: RamBlockRF_internal
    always @(posedge clk)
    begin
        
        if(!res_n)
        begin
            RamBlockRF_internal_write_en <= 1'b0;
            RamBlockRF_internal_read_en <= 1'b0;
            RamBlockRF_internal_write_data <= 32'b0;
            RamBlockRF_internal_address <= 8'b0;
        end
        else
        begin
            
            if(address[11:11] == 1'h1)
            begin
                RamBlockRF_internal_address <= address[10:3];
            end
            
            if((address[11:11] == 1'h1) && write_en)
            begin
                RamBlockRF_internal_write_data <= write_data[31:0];
                RamBlockRF_internal_write_en <= 1'b1;
            end
            else
            begin
                RamBlockRF_internal_write_en <= 1'b0;
            end
            
            if((address[11:11] == 1'h1) && read_en)
            begin
                RamBlockRF_internal_read_en <= 1'b1;
            end
            else
            begin
                RamBlockRF_internal_read_en <= 1'b0;
            end
        end

    end
    
    //Address Decoder Software Read:
    always @(posedge clk)
    begin
        
        if(!res_n)
        begin
            invalid_address <= 1'b0;
            access_complete <= 1'b0;
            read_data <= 32'b0;
        end
        else
        begin
            
            casex(address[11:3])
                {1'h0,8'bxxxxxxxx}:
                begin
                    read_data[31:0] <= RamBlockRF_external_read_data;
                    invalid_address <= RamBlockRF_external_invalid_address;
                    access_complete <= RamBlockRF_external_access_complete;
                end
                {1'h1,8'bxxxxxxxx}:
                begin
                    read_data[31:0] <= RamBlockRF_internal_read_data;
                    invalid_address <= RamBlockRF_internal_invalid_address;
                    access_complete <= RamBlockRF_internal_access_complete;
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
