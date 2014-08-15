
/*
    RF_wrapper #(
        .LG_NUM_REQS()
    ) RF_wrapper_I (
        .core2rf_vc_req(),
        .core2rf_cad(),
        .rf2core_vc_gnt(),
        .core2rf_sot(),
        .core2rf_eot(),
        // interface to HT XBar:
        .core2rf_vc_gnt(),
        .rf2core_cad(),
        .rf2core_outp_req(),
        .rf2core_vc_req(),
        .rf2core_sot(),
        .rf2core_eot(),
        .rf2core_release_grant(),

        // buffer queue interface
        .response_fifo_full(),
        .response_shift_in(),
        .response_data(),
        .response_src_tag(),

        .rf_read_request(),
        .rf_write_request(),
        .rf_address(),
        .rf_read_data(),
        .rf_write_data(),
        .rf_access_complete(),
        .snq_posted_empty(),
        .snq_posted_shift_out(),
        .snq_posted_data(),

        .res_n(),
        .clk(),
        .Example1_address(),
        .Example1_read_data(),
        .Example1_invalid_address(),
        .Example1_access_complete(),
        .Example1_read_en(),
        .Example1_write_en(),
        .Example1_write_data(),
        .Example2_address(),
        .Example2_read_data(),
        .Example2_invalid_address(),
        .Example2_access_complete(),
        .Example2_read_en(),
        .Example2_write_en(),
        .Example2_write_data()

    );
*/
/* auto generated by RFG */

`include "rfs_v.h"
`include "htax.h"

module RF_wrapper #(
    parameter LG_NUM_REQS     = 5
) (
    input wire[`NUM_HTAX_VCS-1:0] core2rf_vc_req,
    input wire[`HTAX_WIDTH-1:0] core2rf_cad,
    output wire[`NUM_HTAX_VCS-1:0] rf2core_vc_gnt,
    input wire[`NUM_HTAX_VCS-1:0] core2rf_sot,
    input wire core2rf_eot,
    // interface to HT XBar:
    input wire[`NUM_HTAX_VCS-1:0] core2rf_vc_gnt,
    output wire[`HTAX_WIDTH-1:0] rf2core_cad,
    output wire[`NUM_HTAX_PORTS-1:0] rf2core_outp_req,
    output wire[`NUM_HTAX_VCS-1:0] rf2core_vc_req,
    output wire[`NUM_HTAX_VCS-1:0] rf2core_sot,
    output wire rf2core_eot,
    output wire rf2core_release_grant,

    // buffer queue interface
    input wire response_fifo_full,
    output wire response_shift_in,
    output wire[`HTAX_WIDTH-2:0] response_data,
    output wire[LG_NUM_REQS-1:0] response_src_tag,

    input wire rf_read_request,
    input wire rf_write_request,
    input wire[`RFS_AWIDTH-1:0] rf_address,
    output wire[31:0] rf_read_data,
    input wire[31:0] rf_write_data,
    output wire rf_access_complete,
    input wire snq_posted_empty,
    output wire snq_posted_shift_out,
    input wire[`HTAX_WIDTH-2:0] snq_posted_data,
    input wire res_n,
    input wire clk,

    output wire[11:3] Example1_address,
    input wire[31:0] Example1_read_data,
    input wire Example1_invalid_address,
    input wire Example1_access_complete,
    output wire Example1_read_en,
    output wire Example1_write_en,
    output wire[31:0] Example1_write_data,
    output wire[11:3] Example2_address,
    input wire[31:0] Example2_read_data,
    input wire Example2_invalid_address,
    input wire Example2_access_complete,
    output wire Example2_read_en,
    output wire Example2_write_en,
    output wire[31:0] Example2_write_data


);

    wire cpu_if_read, cpu_if_write, cpu_if_access_complete, cpu_if_invalid_address;
    wire [22:3] cpu_if_address;
    wire [63:0] cpu_if_write_data, cpu_if_read_data;

    test test_I (
        .res_n(res_n),
        .clk(clk),
        .address(cpu_if_address),
        .read_data(cpu_if_read_data),
        .invalid_address(cpu_if_invalid_address),
        .access_complete(cpu_if_access_complete),
        .read_en(cpu_if_read),
        .write_en(cpu_if_write),
        .write_data(cpu_if_write_data),
        .Example1_address(Example1_address),
        .Example1_read_data(Example1_read_data),
        .Example1_invalid_address(Example1_invalid_address),
        .Example1_access_complete(Example1_access_complete),
        .Example1_read_en(Example1_read_en),
        .Example1_write_en(Example1_write_en),
        .Example1_write_data(Example1_write_data),
        .Example2_address(Example2_address),
        .Example2_read_data(Example2_read_data),
        .Example2_invalid_address(Example2_invalid_address),
        .Example2_access_complete(Example2_access_complete),
        .Example2_read_en(Example2_read_en),
        .Example2_write_en(Example2_write_en),
        .Example2_write_data(Example2_write_data)
    );



    HT_to_RF_converter #(
        .LG_NUM_REQS(LG_NUM_REQS),
        .RF_DATA_WIDTH(32),
        .RF_ADDR_WIDTH(13)
    ) HT_to_RF_converter_I (
        .clk(clk),
        .res_n(res_n),
        .cpu_if_read(cpu_if_read),
        .cpu_if_write(cpu_if_write),
        .cpu_if_address(cpu_if_address),
        .cpu_if_write_data(cpu_if_write_data),
        .cpu_if_read_data(cpu_if_read_data),
        .cpu_if_access_complete(cpu_if_access_complete),
        .cpu_if_invalid_address(cpu_if_invalid_address),
        // interface to the HT XBar:
        .core2rf_vc_gnt(core2rf_vc_gnt),
        .rf2core_cad(rf2core_cad),
        .rf2core_outp_req(rf2core_outp_req),
        .rf2core_vc_req(rf2core_vc_req),
        .rf2core_sot(rf2core_sot),
        .rf2core_release_grant(rf2core_release_grant),
        .rf2core_eot(rf2core_eot),
        // interface to Buffer Queue
        .response_shift_in(response_shift_in),
        .response_data(response_data),
        .response_src_tag(response_src_tag),
        .response_fifo_full(response_fifo_full),
        // interface from the HT XBar:
        .core2rf_vc_req(core2rf_vc_req),
        .core2rf_cad(core2rf_cad),
        .rf2core_vc_gnt(rf2core_vc_gnt),
        .core2rf_sot(core2rf_sot),
        .core2rf_eot(core2rf_eot),
        .snq_read_data(rf_read_data),
        .snq_access_complete(rf_access_complete),
        .snq_posted_shift_out(snq_posted_shift_out),
        .snq_posted_data(snq_posted_data),
        .snq_read_request(rf_read_request),
        .snq_write_request(rf_write_request),
        .snq_address(rf_address),
        .snq_write_data(rf_write_data),
        .snq_posted_empty(snq_posted_empty)
    );

endmodule
