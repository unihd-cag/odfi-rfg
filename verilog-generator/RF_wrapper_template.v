<%

    # logarithmus dualis function for address bit calculation
    proc ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"
    
    # function to get the address Bits for the register file 
    proc getRFsize {registerfile} {
        set size 0
        set offset [$registerfile getAttributeValue software.osys::rfg::absolute_address]
        $registerfile walk {
            if {![$item isa osys::rfg::Group]} {
                if {[string is integer [$item getAttributeValue software.osys::rfg::absolute_address]]} {
                    if {$size <= [$item getAttributeValue software.osys::rfg::absolute_address]} {
                        set size [expr [$item getAttributeValue software.osys::rfg::absolute_address]+[$item getAttributeValue software.osys::rfg::size]]
                    }
                }
            }
        }
        return [expr $size - $offset]
    }

    proc getAddrBits {registerfile} {
        return [ld [getRFsize $registerfile]]
    }

    # function which returns the Name with all parents
    proc getAddrBits {registerfile} {
        return [ld [getRFsize $registerfile]]
    }

    # function which returns the Name with all parents
    proc getName {object} {
        set name {}
        set list [lreplace [$object parents] 0 0]
        set i 0
        set deleteIndex 0
        
        foreach element $list {
            if {[$element isa osys::rfg::RegisterFile] && [$element hasAttribute hardware.osys::rfg::external]} {
                set deleteIndex [expr $i+1]
            }

            incr i 1
        }

        if {$deleteIndex == [llength $list]} {
            foreach element $list {
                lappend name [$element name]
            }
        } else {
            set i 0
            foreach element $list {
                if {$i >= $deleteIndex} { 
                    lappend name [$element name]
                }
                incr i 1        
            }
        }

        return [join $name "_"] 
    }


    # write the verilog template for an easy implementation in a higher level module 
    proc writeTemplate {object context} {
        set signalList {}
        $object walkDepthFirst {
            if {[$it isa osys::rfg::RamBlock]} {
                
                $it onAttributes {hardware.osys::rfg::rw} { 
                    lappend signalList "        .${context}[getName $it]_addr()"
                    lappend signalList "        .${context}[getName $it]_ren()"
                    lappend signalList "        .${context}[getName $it]_rdata()"
                    lappend signalList "        .${context}[getName $it]_wen()"
                    lappend signalList "        .${context}[getName $it]_wdata()"
                }

            } elseif {[$it isa osys::rfg::Register]} {

                $it onEachField {
                    if {[$it name] != "Reserved"} {
                        $it onAttributes {hardware.osys::rfg::counter} {
                            
                            $it onAttributes {hardware.osys::rfg::rw} {
                                lappend signalList "        .${context}[getName $it]_next()"
                                lappend signalList "        .${context}[getName $it]()"
                                lappend signalList "        .${context}[getName $it]_wen()"
                            }
                            
                            $it onAttributes {hardware.osys::rfg::wo} {
                                lappend signalList "        .${context}[getName $it]_next()"
                                lappend signalList "        .${context}[getName $it]_wen()"
                            }

                            $it onAttributes {hardware.osys::rfg::ro} {
                                lappend signalList "        .${context}[getName $it]()"
                            }

                            $it onAttributes {hardware.osys::rfg::software_written} {
                                lappend signalList "        .${context}[getName $it]_written()"
                            }

                            lappend signalList "        .${context}[getName $it]_countup()"

                        } otherwise {

                            $it onAttributes {hardware.osys::rfg::rw} {
                                lappend signalList "        .${context}[getName $it]_next()"
                                lappend signalList "        .${context}[getName $it]()"
                                
                                $it onAttributes {hardware.osys::rfg::hardware_wen} {
                                    lappend signalList "        .${context}[getName $it]_wen()"
                                }
                            }
                            
                            $it onAttributes {hardware.osys::rfg::wo} {
                                lappend signalList "        .${context}[getName $it]_next()"
                                
                                $it onAttributes {hardware.osys::rfg::hardware_wen} {
                                    lappend signalList "        .${context}[getName $it]_wen()"
                                }
                            }

                            $it onAttributes {hardware.osys::rfg::ro} {
                                lappend signalList "        .${context}[getName $it]()"
                            }

                            $it onAttributes {hardware.osys::rfg::software_written} {
                                lappend signalList "        .${context}[getName $it]_written()"
                            }

                        }

                    }
                }
            }

            if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
                set registerfile $it
                lappend signalList "        .[getName $registerfile]_address()"
                lappend signalList "        .[getName $registerfile]_read_data()"
                lappend signalList "        .[getName $registerfile]_invalid_address()"
                lappend signalList "        .[getName $registerfile]_access_complete()"
                lappend signalList "        .[getName $registerfile]_read_en()"
                lappend signalList "        .[getName $registerfile]_write_en()"
                lappend signalList "        .[getName $registerfile]_write_data()"
                ##writeTemplate $it "[$registerfile name]_"
                return false
            } else {
                return true
            }

        }

        puts [join $signalList ",\n"]
    
    }

proc writeBlackbox {object context} {
        set signalList {}

        $object walkDepthFirst {
            if {[$it isa osys::rfg::RamBlock]} {

                $it onAttributes {hardware.osys::rfg::rw} { 
                    lappend signalList "    input wire\[[expr [ld [$it depth]]-1]:0\] ${context}[getName $it]_addr"
                    lappend signalList "    input wire ${context}[getName $it]_ren"
                    lappend signalList "    output wire\[[expr [$it width]-1]:0\] ${context}[getName $it]_rdata"
                    lappend signalList "    input wire ${context}[getName $it]_wen"
                    lappend signalList "    input wire\[[expr [$it width]-1]:0\] ${context}[getName $it]_wdata"
                }

            } elseif {[$it isa osys::rfg::Register]} {
                
                $it onEachField {

                    $it onAttributes {hardware.osys::rfg::counter} {
                            
                        $it onAttributes {hardware.osys::rfg::rw} {
                            if {[$it width] == 1} {
                                lappend signalList "    input wire ${context}[getName $it]_next"
                                lappend signalList "    output wire ${context}[getName $it]"            
                            } else {
                                lappend signalList "    input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
                                lappend signalList "    output wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
                            }

                            lappend signalList "    input wire ${context}[getName $it]_wen"
                        }
                            
                        $it onAttributes {hardware.osys::rfg::wo} {
                            if {[$it width] == 1} {
                                lappend signalList "    input wire ${context}[getName $it]_next"    
                            } else {
                                lappend signalList "    input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
                            }

                            lappend signalList "    input wire ${context}[getName $it]_wen" 
                        }

                        $it onAttributes {hardware.osys::rfg::ro} {
                            if {[$it width] == 1} {
                                lappend signalList "    output wire ${context}[getName $it]"        
                            } else {
                                lappend signalList "    output wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
                            }

                        }

                        $it onAttributes {hardware.osys::rfg::software_written} {
                            lappend signalList "    output wire ${context}[getName $it]_written"
                        }

                        lappend signalList "    input wire ${context}[getName $it]_countup"

                    } otherwise {

                        $it onAttributes {hardware.osys::rfg::rw} {
                            if {[$it width] == 1} {
                                lappend signalList "    input wire ${context}[getName $it]_next"
                                lappend signalList "    output wire ${context}[getName $it]" 
                            } else {
                                lappend signalList "    input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
                                lappend signalList "    output wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
                            }   

                            $it onAttributes {hardware.osys::rfg::hardware_wen} {
                                lappend signalList "    input wire ${context}[getName $it]_wen"
                            }
                        }
                            
                        $it onAttributes {hardware.osys::rfg::wo} {
                            if {[$it width] == 1} {
                                lappend signalList "    input wire ${context}[getName $it]_next"        
                            } else {
                                lappend signalList "    input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
                            }   

                            $it onAttributes {hardware.osys::rfg::hardware_wen} {
                                lappend signalList "    input wire ${context}[getName $it]_wen" 
                            }
                        }

                        $it onAttributes {hardware.osys::rfg::ro} {
                            if {[$it width] == 1} {
                                lappend signalList "    output wire ${context}[getName $it]"
                            } else {
                                lappend signalList "    output wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
                            }
                            
                        }

                        $it onAttributes {hardware.osys::rfg::software_written} {
                            lappend signalList "    output wire ${context}[getName $it]_written" 
                        }

                    }

                }   
            }
            ## ToDo rewrite with wire and reg signals
            if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
                set registerfile $it
                if {[expr [getAddrBits $registerfile]-1] < [ld [expr [$registerfile register_size]/8]]} {
                    lappend signalList "    output wire\[[getAddrBits $registerfile]:[ld [expr [$registerFile register_size]/8]]\] [getName $registerfile]_address"
                } else {
                    lappend signalList "    output wire\[[expr [getAddrBits $registerfile]-1]:[ld [expr [$registerFile register_size]/8]]\] [getName $registerfile]_address"
                }
                lappend signalList "    input wire\[[expr [$registerFile register_size] - 1]:0\] [getName $registerfile]_read_data"
                lappend signalList "    input wire [getName $registerfile]_invalid_address"
                lappend signalList "    input wire [getName $registerfile]_access_complete"
                lappend signalList "    output wire [getName $registerfile]_read_en"
                lappend signalList "    output wire [getName $registerfile]_write_en"
                lappend signalList "    output wire\[[expr [$registerFile register_size] - 1]:0\] [getName $registerfile]_write_data"
                ##writeBlackbox $it "[$registerfile name]_"
                return false
            } else {
                return true
            }

        }
        puts [join $signalList ",\n"]
    }

# write RF instance
    proc writeRFModule {object} {
        puts "    [$object name] [$object name]_I ("
        puts "        .res_n(res_n),"
        puts "        .clk(clk),"
        puts "        .address(cpu_if_address),"
        puts "        .read_data(cpu_if_read_data),"
        puts "        .invalid_address(cpu_if_invalid_address),"
        puts "        .access_complete(cpu_if_access_complete),"
        puts "        .read_en(cpu_if_read),"
        puts "        .write_en(cpu_if_write),"
        puts "        .write_data(cpu_if_write_data),"

        set signalList {}
        $object walkDepthFirst {
            if {[$it isa osys::rfg::RamBlock]} {
                
                $it onAttributes {hardware.osys::rfg::rw} { 
                    lappend signalList "        .[getName $it]_addr([getName $it]_addr)"
                    lappend signalList "        .[getName $it]_ren([getName $it]_ren)"
                    lappend signalList "        .[getName $it]_rdata([getName $it]_rdata)"
                    lappend signalList "        .[getName $it]_wen([getName $it]_wen)"
                    lappend signalList "        .[getName $it]_wdata([getName $it]_wdata)"
                }

            } elseif {[$it isa osys::rfg::Register]} {

                $it onEachField {
                    if {[$it name] != "Reserved"} {
                        $it onAttributes {hardware.osys::rfg::counter} {
                            
                            $it onAttributes {hardware.osys::rfg::rw} {
                                lappend signalList "        .[getName $it]_next([getName $it]_next)"
                                lappend signalList "        .[getName $it]([getName $it])"
                                lappend signalList "        .[getName $it]_wen([getName $it]_wen)"
                            }
                            
                            $it onAttributes {hardware.osys::rfg::wo} {
                                lappend signalList "        .[getName $it]_next([getName $it]_next)"
                                lappend signalList "        .[getName $it]_wen([getName $it]_wen)"
                            }

                            $it onAttributes {hardware.osys::rfg::ro} {
                                lappend signalList "        .[getName $it]([getName $it])"
                            }

                            $it onAttributes {hardware.osys::rfg::software_written} {
                                lappend signalList "        .[getName $it]_written([getName $it]_written)"
                            }

                            lappend signalList "        .[getName $it]_countup([getName $it]_countup)"

                        } otherwise {

                            $it onAttributes {hardware.osys::rfg::rw} {
                                lappend signalList "        .[getName $it]_next([getName $it]_next)"
                                lappend signalList "        .[getName $it]([getName $it])"
                                
                                $it onAttributes {hardware.osys::rfg::hardware_wen} {
                                    lappend signalList "        .[getName $it]_wen([getName $it]_wen)"
                                }
                            }
                            
                            $it onAttributes {hardware.osys::rfg::wo} {
                                lappend signalList "        .[getName $it]_next([getName $it]_next)"
                                
                                $it onAttributes {hardware.osys::rfg::hardware_wen} {
                                    lappend signalList "        .[getName $it]_wen([getName $it]_wen)"
                                }
                            }

                            $it onAttributes {hardware.osys::rfg::ro} {
                                lappend signalList "        .[getName $it]([getName $it])"
                            }

                            $it onAttributes {hardware.osys::rfg::software_written} {
                                lappend signalList "        .[getName $it]_written([getName $it]_written)"
                            }

                        }

                    }
                }
            }

            if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
                set registerfile $it
                lappend signalList "        .[getName $registerfile]_address([getName $registerfile]_address)"
                lappend signalList "        .[getName $registerfile]_read_data([getName $registerfile]_read_data)"
                lappend signalList "        .[getName $registerfile]_invalid_address([getName $registerfile]_invalid_address)"
                lappend signalList "        .[getName $registerfile]_access_complete([getName $registerfile]_access_complete)"
                lappend signalList "        .[getName $registerfile]_read_en([getName $registerfile]_read_en)"
                lappend signalList "        .[getName $registerfile]_write_en([getName $registerfile]_write_en)"
                lappend signalList "        .[getName $registerfile]_write_data([getName $registerfile]_write_data)"
                return false
            } else {
                return true
            }

        }

        puts [join $signalList ",\n"]

        puts "    );"
        puts ""
    }

%>
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
<% writeTemplate $registerFile ""%>
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
    output wire[63:0] rf_read_data,
    input wire[63:0] rf_write_data,
    output wire rf_access_complete,
    input wire snq_posted_empty,
    output wire snq_posted_shift_out,
    input wire[`HTAX_WIDTH-2:0] snq_posted_data,
    input wire res_n,
    input wire clk,

<% writeBlackbox $registerFile ""%>

);

    wire cpu_if_read, cpu_if_write, cpu_if_access_complete, cpu_if_invalid_address;
    wire [22:3] cpu_if_address;
    wire [63:0] cpu_if_write_data, cpu_if_read_data;

<% writeRFModule $registerFile %>

    HT_to_RF_converter #(
        .LG_NUM_REQS(LG_NUM_REQS),
        .RF_DATA_WIDTH(64),
        .RF_ADDR_WIDTH(20)
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
