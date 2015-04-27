package require osys::rfg
package require HelperFunctions
package require osys::rfg::address::hierarchical
source ${::osys::rfg::generator::verilog::location}/Instances.tm

set rb_save ""
set AddrBits ""
set addr_object ""

odfi::closures::oproc writeRamBlockInterface {it} {
    
    $it onAttributes {hardware.osys::rfg::external} {
        if {[$it depth] != 1} {
            output [getName $it]_rf_addr wire [ld [$it depth]]
        }
        $it onRead {software} {
            output [getName $it]_rf_ren [find_internalRF $it $rf]
            input [getName $it]_rf_rdata wire [$it width]
        }
        $it onWrite {software} {
            output [getName $it]_rf_wen [find_internalRF $it $rf]
            output [getName $it]_rf_wdata wire [$it width]
        }

        input [getName $it]_rf_access_complete wire


    } otherwise {
        if {[$it hasAttribute hardware.osys::rfg::ro] || \
            [$it hasAttribute hardware.osys::rfg::wo] || \
            [$it hasAttribute hardware.osys::rfg::rw]} {
            input [getName $it]_addr wire [ld [$it depth]]
        }

        $it onRead {hardware} {
            input [getName $it]_ren wire
            output [getName $it]_rdata wire [$it width]
        }

        $it onWrite {hardware} {
            input [getName $it]_wen wire
            input [getName $it]_wdata wire [$it width]
        }
    
    }
}


odfi::closures::oproc writeRegisterInterface {it} {
    $it onEachField {
        if {[$it name] != "Reserved"} {
            $it onAttributes {hardware.osys::rfg::counter} {
                $it onRead {hardware} {
                    output [getName $it] wire [$it width]
                }

                $it onWrite {hardware} {
                    input [getName $it]_next wire [$it width]
                    input [getName $it]_wen wire
                }

                $it onAttributes {hardware.osys::rfg::software_written} {
                    output [getName $it]_written [find_internalRF $it $rf] 
                }

                $it onAttributes {hardware.osys::rfg::changed} {
                    output [getName $it]_changed [find_internalRF $it $rf] 
                }

                $it onAttributes {hardware.osys::rfg::edge_trigger} {
                    input [getName $it]_edge wire
                } otherwise {
                    input [getName $it]_countup wire
                }

            } otherwise {

                $it onRead {hardware} {
                    output [getName $it] [find_internalRF $it $rf] [$it width]
                }
                
                $it onWrite {hardware} {
                    input [getName $it]_next wire [$it width]
                    
                    if {![$it hasAttribute hardware.osys::rfg::no_wen]} {
                        input [getName $it]_wen wire    
                    }

                }
                
                $it onAttributes {hardware.osys::rfg::software_written} {
                    output [getName $it]_written [find_internalRF $it $rf]
                }

                $it onAttributes {hardware.osys::rfg::changed} {
                    output [getName $it]_changed [find_internalRF $it $rf]
                }


                $it onAttributes {hardware.osys::rfg::clear} {
                    input [getName $it]_clear wire
                }
            
            }
        }
    }
}


odfi::closures::oproc writeRegisterFileInterface {it} {
    output [getName $it]_address reg [getRFAddrWidth $it] [getRFAddrOffset $it]
    input [getName $it]_invalid_address wire
    input [getName $it]_access_complete wire
    output [getName $it]_read_en reg
    input [getName $it]_read_data wire [getRFmaxWidth $it]
    output [getName $it]_write_en reg
    output [getName $it]_write_data reg [getRFmaxWidth $it]
}


odfi::closures::oproc writeVModuleInterface {rf} {
    
    input clk wire
    input res_n wire
    input address wire [getRFAddrWidth $rf] [getRFAddrOffset $rf]
    output invalid_address reg
    output access_complete reg
    input read_en wire
    output read_data reg [getRFmaxWidth $rf]
    input write_en wire
    input write_data wire [getRFmaxWidth $rf]
    
    $rf walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlockInterface $it
        }

        if {[$it isa osys::rfg::Register]} {
            writeRegisterInterface $it
        }

        if {[$it isa osys::rfg::RegisterFile] && \
            [$it hasAttribute hardware.osys::rfg::external]} {
            writeRegisterFileInterface $it
            return false	
        } else {
            return true
        }
    }
}


odfi::closures::oproc writeRamBlockInternalSigs {it} {

    $it onAttributes {hardware.osys::rfg::external} {
        
        $it onWrite {software} {
            
            $it onAttributes {hardware.osys::rfg::shared_bus} {
                if {$it == [getFirstSharedBusObject $rf]} {
                    reg write_data_reg [$it width]
                }
            } otherwise {
                reg [getName $it]_write_data_reg [$it width]
            }

        }

        $it onAttributes {hardware.osys::rfg::shared_bus} {
            ## Maybe with Offset
            if {$it == [getFirstSharedBusObject $rf]} {
                if {[$it depth] != 1} {
                    reg address_reg [ld [$it depth]]
                }
            }
        } otherwise {
            if {[$it depth] != 1} {
                reg [getName $it]_address_reg [ld [$it depth]]
            }
        }

    } otherwise {
        if {[$it hasAttribute software.osys::rfg::ro] || \
            [$it hasAttribute software.osys::rfg::wo] || \
            [$it hasAttribute software.osys::rfg::rw]} {
            reg [getName $it]_rf_addr [ld [$it depth]]
        }

        $it onWrite {software} {
            reg [getName $it]_rf_wen
            reg [getName $it]_rf_wdata [$it width]
        }

        $it onRead {software} {
            reg [getName $it]_rf_ren
            wire [getName $it]_rf_rdata [$it width]
        }

        ## Delays
        ## Maybe with Offset
        ::if {$it == [needDelay $rf]} {
            set delays 3
            for {set i 0} {$i < $delays} {incr i} {
                reg read_en_dly$i
            }
        }

    }

}

odfi::closures::oproc writeRegisterInternalSigs {it} {  

    $it onAttributes {hardware.osys::rfg::rreinit_source} {
        reg rreinit
    }

    $it onEachField {
        if {[$it name] != "Reserved"} {
            $it onAttributes {hardware.osys::rfg::counter} {
                
                ## Check if this is equivilant
                $it onWrite {hardware} {
                    reg [getName $it]_load_enable
                    reg [getName $it]_load_value [$it width]
                } otherwise {
                    $it onWrite {software} {
                        reg [getName $it]_load_enable
                        reg [getName $it]_load_value [$it width]
                    }
                }
                $it onAttributes {hardware.osys::rfg::edge_trigger} {
                    reg [getName $it]_countup
                    reg [getName $it]_edge_last
                }

                if {![$it hasAttribute hardware.osys::rfg::ro] && \
                    ![$it hasAttribute hardware.osys::rfg::rw]} {
                    wire [getName $it] [$it width]
                }
                    
            } otherwise {
                
                $it onAttributes {hardware.osys::rfg::changed} {
                        reg [getName $it]_res_in_last_cycle
                }

                if {![$it hasAttribute hardware.osys::rfg::ro] && \
                    ![$it hasAttribute hardware.osys::rfg::rw] } {
                    reg [getName $it] [$it width]
                }

            }
        }
    }

}

odfi::closures::oproc writeRegisterFileInternalSigs {rf} {
            
    $it onAttributes {hardware.osys::rfg::internal} {
        reg [getName $it]_address [getRFAddrWidth $it] [getRFAddrOffset $it]
        wire [getName $it]_invalid_address
        wire [getName $it]_access_complete
        reg [getName $it]_read_en
        wire [getName $it]_read_data [getRFmaxWidth $it]
        reg [getName $it]_write_en
        reg [getName $it]_write_data [getRFmaxWidth $it]
    }

}

odfi::closures::oproc writeInternalSigs {rf} {

    $rf walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlockInternalSigs $it
        }

        if {[$it isa osys::rfg::Register]} {
            writeRegisterInternalSigs $it
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            writeRegisterFileInternalSigs $it

            return false
        
        } else {

            return true

        }

    }

}

odfi::closures::oproc writeFieldSoftWrite {it offset} {
    if {[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1] < [getRFAddrOffset $rf]} {
        set if_cond "(address == [expr [getRelAddress [$it parent]]/8]) && write_en"     
    } else {
        set if_cond "(address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]:[getRFAddrOffset $rf]\] == [expr [getRelAddress [$it parent]]/8]) && write_en"
    }
    vif $if_cond {
        $it onAttributes {hardware.osys::rfg::counter} {
            vputs "[getName $it]_load_enable <= 1'b1"
            vputs "[getName $it]_load_value <= write_data\[[expr [$it width] + $offset -1]:$offset\]"
        } otherwise {
            $it onAttributes {software.osys::rfg::write_clear} {
                vputs "[getName $it] <= [$it width]'b0"
            } otherwise {
            
                $it onAttributes {software.osys::rfg::write_xor} {
                    vputs "[getName $it] <= write_data\[[expr [$it width] + $offset -1]:$offset\] ^ [getName $it]"
                } otherwise {
                    vputs "[getName $it] <= write_data\[[expr [$it width] + $offset - 1]:$offset\]"
                }

            }
    
            $it onAttributes {hardware.osys::rfg::software_written} {
                vputs "[getName $it]_written <= 1'b1"
            }
            $it onAttributes {hardware.osys::rfg::changed} {
                vputs "[getName $it]_changed <= 1'b1"
            }
        }

    }
}

odfi::closures::oproc writeHardFieldFunction {it} {

    $it onAttributes {hardware.osys::rfg::sticky} {
        vputs "[getName $it] <= [getName $it]_next | [getName $it]"
    } otherwise {
        vputs "[getName $it] <= [getName $it]_next"
    }
    
    $it onAttributes {hardware.osys::rfg::software_written} {
        vputs "[getName $it]_written <= 1'b0"
    }

    $it onAttributes {hardware.osys::rfg::changed} {
        vputs "[getName $it]_changed <= 1'b0"
    }


}

odfi::closures::oproc writeFieldHardWrite {object} { 
    $object onAttributes {hardware.osys::rfg::counter} {
        if {$condition == "ifcond"} {
            
            vif "[getName $object]_wen" {
                vputs "[getName $object]_load_value <= [getName $object]_next"
                vputs "[getName $object]_load_enable <= 1'b1"
            }

            velse {
                vputs "[getName $object]_load_value <= [$object width]'b0"
                vputs "[getName $object]_load_enable <= 1'b0"
            }

        } else {
            
            velseif "[getName $object]_wen" {
                vputs "[getName $object]_load_value <= [getName $object]_next"
                vputs "[getName $object]_load_enable <= 1'b1"
            }

            velse {
                vputs "[getName $object]_load_value <= [$object width]'b0"
                vputs "[getName $object]_load_enable <= 1'b0"
            }

        }
    } otherwise {
        $object onAttributes {hardware.osys::rfg::clear} {
            if {$condition == "ifcond"} {
                vif "[getName $object]_clear" {
                    vputs "[getName $object] <= [$object width]'b0"
                }
                set condition "elsecond"
            } else {
                velseif "[getName $object]_clear" {
                    vputs "[getName $object] <= [$object width]'b0"
                }
            }
        }

        if {$condition == "ifcond"} {
            $object onAttributes {hardware.osys::rfg::no_wen} { 
                writeHardFieldFunction $object      
            } otherwise {
                    vif "[getName $object]_wen" {
                        writeHardFieldFunction $object
                    }
            }
        } else {
            $object onAttributes {hardware.osys::rfg::no_wen} {
                velse {
                    writeHardFieldFunction $object
                }
            } otherwise {
                velseif "[getName $object]_wen" {
                    writeHardFieldFunction $object
                }
                $object onAttributes {hardware.osys::rfg::software_written} {
                    velse {
                        vputs "[getName $object]_written <= 1'b0"
                    }
                }
            }
        }
    }
}

odfi::closures::oproc writeRegisterReset {object} {
#    $object onAttributes {hardware.osys::rfg::rreinit_source} {
#        
#        vif "!res_n" {
#            vputs "rreinit <= 1'b0"    
#        }
#
#    } otherwise {
#        
        if {[hasReset $object] == true} {
            vif "!res_n" {

                $object onAttributes {hardware.osys::rfg::rreinit_source} {
                    vputs "rreinit <= 1'b0"
                }

                $object onEachField {
                    $it onAttributes {hardware.osys::rfg::counter} {
                        
                        $it onWrite {software} {
                            vputs "[getName $it]_load_value <= [$it reset]"
                            vputs "[getName $it]_load_enable <= 1'b0"
                        } otherwise {

                            $it onWrite {hardware} {
                                vputs "[getName $it]_load_value <= [$it reset]"
                                vputs "[getName $it]_load_enable <= 1'b0"
                            }
                        }

                        $it onAttributes {hardware.osys::rfg::edge_trigger} {
                            vputs "[getName $it]_edge_last <= 1'b0"
                            vputs "[getName $it]_countup <= 1'b0"
                        }
                        
                        $it onAttributes {hardware.osys::rfg::software_written} {
                            vputs "[getName $it]_written <= 1'b0"
                        }
                        
                        $it onAttributes {hardware.osys::rfg::changed} {
                            vputs "[getName $it]_changed <=1'b0"
                            vputs "[getName $it]_res_in_last_cycle <= 1'b1"
                        }

                    } ohterwise {
                        if {[$it name] != "Reserved"} {
                            vputs "[getName $it] <= [$it reset]"
                        }

                        $it onAttributes {hardware.osys::rfg::software_written} {
                            vputs "[getName $it]_written <= 1'b0"
                        }

                        $it onAttributes {hardware.osys::rfg::changed} {
                            vputs "[getName $it]_changed <=1'b0"
                            vputs "[getName $it]_res_in_last_cycle <= 1'b1"
                        }
                    }
                }
            }
        }
    #}
}

odfi::closures::oproc writeRegisterWrite {object} {
    $object onAttributes {hardware.osys::rfg::rreinit_source} {
        vif "(address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]:[getRFAddrOffset $rf]\] == [expr [getRelAddress $object]/(2**[getRFAddrOffset $rf])]) && write_en" {
            vputs "rreinit <= 1'b1"   
        }
        velse {
            vputs "rreinit <= 1'b0"
        }
    } 
    #otherwise {
        set offset 0
        $object onEachField {
            $it onWrite {software} {
                    writeFieldSoftWrite $it $offset            
                $it onWrite {hardware} {
                    set condition "elsecond"
                    writeFieldHardWrite $it
                } otherwise {
                    $it onAttributes {hardware.osys::rfg::software_written} {
                        velse {
                            vputs "[getName $it]_written <= 1'b0"
                        }
                    }
                    $it onAttributes {hardware.osys::rfg::changed} {
                        velse {
                            vputs "[getName $it]_changed <= 1'b0"
                        }
                    }
                }

            } otherwise {
                
                $it onWrite {hardware} {
                    set condition "ifcond"
                    writeFieldHardWrite $it
                } 

            }
            
            incr offset [$it width]
            
            $it onAttributes {hardware.osys::rfg::edge_trigger} {
                set obj $it
                vif "[getName $obj]_edge != [getName $obj]_edge_last" {
                    vputs "[getName $obj]_countup <= 1'b1"
                    vputs "[getName $obj]_edge_last <= [getName $obj]_edge"
                }
                velse {
                    vputs "[getName $obj]_countup <= 1'b0"
                }
            }

            $it onAttributes {hardware.osys::rfg::changed} {
                set obj $it
                vif "[getName $obj]_res_in_last_cycle == 1'b1" {
                    vputs "[getName $obj]_changed <= 1'b1"
                    vputs "[getName $obj]_res_in_last_cycle <= 1'b0"
                }
            }

        }
    #}
}

odfi::closures::oproc writeRegisterBlock {object} {

    ## check if anything is generated
    if {[CheckForRegBlock $object] == true} {
        comment "Register: [getName $object]"
        clocked clk res_n $res_type {
            ## write Reset
            writeRegisterReset $object
            ## write Software write
            $object onAttributes {hardware.osys::rfg::rreinit_source} {
                velse {
                    writeRegisterWrite $object
                }
            } otherwise {
                if {[hasWrite software $object] == true || [hasWrite hardware $object]} {
                    if {[hasReset $object] == true} {
                        velse {
                            writeRegisterWrite $object
                        }
                    } else {
                        writeRegisterWrite $object
                    }
                }
            }
        }
    }

}

odfi::closures::oproc writeRamBlockReset {object} {
    vif "!res_n" {
        if {![$object hasAttribute hardware.osys::rfg::external]} {
            if {[$object depth] != 1} {
                vputs "[getName $object]_rf_addr <= [ld [$object depth]]'b0"
            }
        }
        $object onWrite {software} {
            vputs "[getName $object]_rf_wen <= 1'b0"
            if {![$object hasAttribute hardware.osys::rfg::external]} {
                vputs "[getName $object]_rf_wdata <= [$object width]'b0"
            }
        }
        $object onRead {software} {
            vputs "[getName $object]_rf_ren <= 1'b0"
        }
    }
}

odfi::closures::oproc writeRamBlockWrite {object} {
    set lower_identifier [expr [ld [$object depth]]+[getRFAddrOffset $rf]+[$object getAttributeValue software.osys::rfg::address_shift]]
    set equal [expr ([$object getAttributeValue software.osys::rfg::relative_address]/([$object depth]*[$rf register_size]/8)) >> [$object getAttributeValue software.osys::rfg::address_shift]]
    if {$lower_identifier > [expr [getAddrBits $rf] - 1]} {
        set higher [expr [ld [$object depth]] +[getRFAddrOffset $rf] - 1 + [$object getAttributeValue software.osys::rfg::address_shift]]
        set lower [expr [getRFAddrOffset $rf] + [$object getAttributeValue software.osys::rfg::address_shift]]
        
        if {![$object hasAttribute hardware.osys::rfg::external]} {
            if {[$object depth] != 1} {
                vputs "[getName $object]_rf_addr <= address\[$higher:$lower\]"
            }
        }
        
        $object onWrite {software} {
            if {![$object hasAttribute hardware.osys::rfg::external]} {
                vputs "[getName $object]_rf_wdata <= write_data\[[expr [$object width]-1]:0\]"
            }
            vputs "[getName $object]_rf_wen <= write_en"
        }
        $object onRead {software} {
            vputs "[getName $object]_rf_ren <= read_en"
        }
   
    } else {
        if {[$object depth] != 1} {
            vif "address\[[expr [getAddrBits $rf] - 1]:$lower_identifier\] == $equal" {
                set higher [expr [ld [$object depth]] +[getRFAddrOffset $rf] - 1 + [$object getAttributeValue software.osys::rfg::address_shift]]
                set lower [expr [getRFAddrOffset $rf] + [$object getAttributeValue software.osys::rfg::address_shift]]
                
                if {![$object hasAttribute hardware.osys::rfg::external]} {
                    vputs "[getName $object]_rf_addr <= address\[$higher:$lower\]"
                }

                $object onWrite {software} {
                    
                    if {![$object hasAttribute hardware.osys::rfg::external]} {
                        vputs "[getName $object]_rf_wdata <= write_data\[[expr [$object width]-1]:0\]"
                    }
                    
                    vputs "[getName $object]_rf_wen <= write_en"
                }
                $object onRead {software} {
                    vputs "[getName $object]_rf_ren <= read_en"
                }
            }
        } else {
            vif "(address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]:[getRFAddrOffset $rf]\] == [expr [getRelAddress $object]/(2**[getRFAddrOffset $rf])])" {
                $object onWrite {software} {
                    
                    if {![$object hasAttribute hardware.osys::rfg::external]} {
                        vputs "[getName $object]_rf_wdata <= write_data\[[expr [$object width]-1]:0\]"
                    }
                    
                    vputs "[getName $object]_rf_wen <= write_en"
                }
                $object onRead {software} {
                    vputs "[getName $object]_rf_ren <= read_en"
                }
               
            }
        }
    }
}

odfi::closures::oproc writeRamBlock {object} {
    if {[CheckForRegBlock $object] == true} {
        $object onAttributes {hardware.osys::rfg::external} {
            odfi::common::println "" $resolve
            $object onAttributes {hardware.osys::rfg::shared_bus} {
                $object onWrite {software} {
                    assign [getName $object]_rf_wdata "write_data_reg\[[expr [$object width]-1]:0\]"
                }
                set higher [expr [ld [$object depth]] - 1 + [expr [getRFAddrOffset $rf]]  + [$object getAttributeValue software.osys::rfg::address_shift]]
                set lower [expr [getRFAddrOffset $rf] + [$object getAttributeValue software.osys::rfg::address_shift]]
                assign [getName $object]_rf_addr "address_reg\[$higher:$lower\]"
            } otherwise {
                $object onWrite {software} {
                    assign [getName $object]_rf_wdata [getName $object]_write_data_reg
                }
                if {[$object depth] != 1} {
                    assign [getName $object]_rf_addr [getName $object]_address_reg
                }
            }
        }
        comment "RamBlock: [getName $object]"
        
        clocked clk res_n $res_type {
        #always $always_content {}
            writeRamBlockReset $object
            velse {
                writeRamBlockWrite $object
            }

        }

    }
}

odfi::closures::oproc writeRFBlock {object} {
    comment "RegisterFile: [getName $object]"
    clocked clk res_n $res_type {
    #always $always_content {}
        vif "!res_n" {
            vputs "[getName $object]_write_en <= 1'b0"
            vputs "[getName $object]_read_en <= 1'b0"
            vputs "[getName $object]_write_data <= [getRFmaxWidth $object]'b0"
            vputs "[getName $object]_address <= [getRFAddrWidth $object]'b0"
        }
        velse {
            set upper [expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]
            set lower [expr [getRFAddrWidth $object] + [getRFAddrOffset $object]]
            set care [expr [$object getAttributeValue software.osys::rfg::relative_address] >> ([getRFAddrOffset $object] + [getRFAddrWidth $object])]
            set care [format %x $care]
            set care_width [expr [getRFAddrWidth $rf] - [getRFAddrWidth $object]]
            vif "address\[$upper:$lower\] == $care_width'h$care" {
                vputs "[getName $object]_address <= address\[[expr [getRFAddrWidth $object] + [getRFAddrOffset $object] - 1]:[getRFAddrOffset $object]\]"
            }
            vif "(address\[$upper:$lower\] == $care_width'h$care) && write_en" {
                vputs "[getName $object]_write_data <= write_data\[[expr [getRFmaxWidth $object] - 1]:0\]"
                vputs "[getName $object]_write_en <= 1'b1"
            }
            velse {
                vputs "[getName $object]_write_en <= 1'b0"
            }
            vif "(address\[$upper:$lower\] == $care_width'h$care) && read_en" {
                vputs "[getName $object]_read_en <= 1'b1"
            }
            velse {
                vputs "[getName $object]_read_en <= 1'b0"
            }
        }
    }
}

odfi::closures::oproc writeWriteInterface {object} {
    
    $rf walkDepthFirst {

        if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlock $it
        }

        if {[$it isa osys::rfg::Register]} {
            writeRegisterBlock $it
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            writeRFBlock $it
            return false    
        
        } else {

            return true
        
        }

    }

}

odfi::closures::oproc writeRegisterSoftRead {object} {
    if {[getRFAddrWidth $rf] == 0} {
        set width 1
    } else {
        set width [getRFAddrWidth $rf]
    }
    case_select "$width'h[format %x [expr [$object getAttributeValue software.osys::rfg::relative_address] / ([$rf register_size]/8)]]" {
        set offset 0
        $object onEachField {
            
            $it onRead {software} {
                vputs "read_data\[[expr [$it width] + $offset - 1]:$offset\] <= [getName $it]"
            }
            incr offset [$it width]
            
        }
        if {$offset != [getRFmaxWidth $rf]} {
            vputs "read_data\[[expr [getRFmaxWidth $rf]-1]:$offset\] <= [expr [getRFmaxWidth $rf] - $offset]'b0"
        }
        vputs "invalid_address <= 1'b0"
        vputs "access_complete <= read_en || write_en"
    }
}

odfi::closures::oproc writeRamBlockSoftRead {object} {
    set dontCare [string repeat x [expr [ld [$object depth]] + [$object getAttributeValue software.osys::rfg::address_shift]]]
    set care [expr ([$object getAttributeValue software.osys::rfg::relative_address]/([$object depth]*[$rf register_size]/8)) >> [$object getAttributeValue software.osys::rfg::address_shift]] 
    set care [format %x $care]
    set care_width [expr [getAddrBits $rf] - [ld [$object depth]] - 3 - [$object getAttributeValue software.osys::rfg::address_shift]]
    set dontCare_width [expr [ld [$object depth]] + [$object getAttributeValue software.osys::rfg::address_shift]]
    if {[$object depth] != 1} {
        case_select "\{[getRBAddrssDecode $object $rf]\}" {
            $object onRead {software} {
                vputs "read_data\[[expr [$object width]-1]:0\] <= [getName $object]_rf_rdata"
            }
            if {[$object width] != [getRFmaxWidth $rf]} {
                vputs "read_data\[[expr [getRFmaxWidth $rf]-1]:[$object width]\] <= [expr [getRFmaxWidth $rf] - [$object width]]'b0"
            }
            vputs "invalid_address <= 1'b0"
            $object onAttributes {hardware.osys::rfg::external} {
                vputs "access_complete <= [getName $object]_rf_access_complete"
            } otherwise {
                vputs "access_complete <= write_en || read_en_dly2"
            }
        }
    } else {
        case_select "$width'h[format %x [expr [$object getAttributeValue software.osys::rfg::relative_address] / ([$rf register_size]/8)]]" {
            $object onRead {software} {
                vputs "read_data\[[expr [$object width]-1]:0\] <= [getName $object]_rf_rdata"
            }
            if {[$object width] != [getRFmaxWidth $rf]} {
                vputs "read_data\[[expr [getRFmaxWidth $rf]-1]:[$object width]\] <= [expr [getRFmaxWidth $rf] - [$object width]]'b0"
            }
            vputs "invalid_address <= 1'b0"
            $object onAttributes {hardware.osys::rfg::external} {
                vputs "access_complete <= [getName $object]_rf_access_complete"
            } otherwise {
                vputs "access_complete <= write_en || read_en_dly2"
            }
        }
    }
}

odfi::closures::oproc writeExternalRamSignals {object} {
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::external} {
                $it onAttributes {hardware.osys::rfg::shared_bus} {
                    if {[getFirstSharedBusObject $rf] == $it} {
                        $it onWrite {software} {
                            vputs "write_data_reg <= write_data"
                        }
                        vputs "address_reg <= address"
                    }
                } otherwise {
                    $it onWrite {software} {
                        vputs "[getName $it]_write_data_reg <= write_data\[[expr [$it width]-1]:0\]"
                    }
                    if {[$it depth] != 1} {
                        set lower_addr [expr [getRFAddrOffset $rf] + [$it getAttributeValue software.osys::rfg::address_shift]]
                        set higher_addr [expr [ld [$it depth]] -1 + [$it getAttributeValue software.osys::rfg::address_shift] + [getRFAddrOffset $rf]]
                        vputs "[getName $it]_address_reg <= address\[$higher_addr:$lower_addr\]"
                    }
                }
            }
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            return false
        } else {
            return true
        }
  
    }
}

odfi::closures::oproc writeRFSoftRead {object} {
    set care [expr [$object getAttributeValue software.osys::rfg::relative_address] >> ([getRFAddrOffset $object] + [getRFAddrWidth $object])]
    set care [format %x $care]
    set care_width [expr [getRFAddrWidth $rf] - [getRFAddrWidth $object]]
    set dontCare_width [getRFAddrWidth $object]
    set dontCare [string repeat x [getRFAddrWidth $object]]
    case_select "\{$care_width'h$care,$dontCare_width'b$dontCare\}" {
        vputs "read_data\[[expr [getRFmaxWidth $object] - 1]:0\] <= [getName $object]_read_data"
        if {[getRFmaxWidth $object] != [getRFmaxWidth $rf]} {
            vputs "read_data\[[expr [getRFmaxWidth $rf] -1]:[getRFmaxWidth $object]\] <= [expr [getRFmaxWidth $rf] -  [getRFmaxWidth $object]]'b0"
        }
        vputs "invalid_address <= [getName $object]_invalid_address"
        vputs "access_complete <= [getName $object]_access_complete"
    }
}

odfi::closures::oproc writeSoftReadInterface {object} {
    comment "Address Decoder Software Read:"
    clocked clk res_n $res_type {
    #always $always_content {}
        vif "!res_n" {
            vputs "invalid_address <= 1'b0"
            vputs "access_complete <= 1'b0"
            vputs "read_data <= [getRFmaxWidth $rf]'b0"
        }
        velse {
            if {[hasRamBlock $rf]} {
                vputs "read_en_dly0 <= read_en"
                vputs "read_en_dly1 <= read_en_dly0"
                vputs "read_en_dly2 <= read_en_dly1"
            }
            
            writeExternalRamSignals $rf
                if {[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1] < [getRFAddrOffset $rf]} {
                    set case_cond "address"     
                } else {
                    set case_cond "address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] -1]:[getRFAddrOffset $rf]\]" 
                }
            case $case_cond {
                $rf walkDepthFirst {
                    ##RamBlock
                    if {[$it isa osys::rfg::RamBlock]} {
                        writeRamBlockSoftRead $it
                    }
                    ##Register
                    if {[$it isa osys::rfg::Register]} {
                        writeRegisterSoftRead $it       
                    }
                    if {[$it isa osys::rfg::RegisterFile]} {
                        writeRFSoftRead $it
                        return false
                    } else {
                        return true
                    }

                }

                case_select "default" {
                    vputs "invalid_address <= read_en || write_en"
                    vputs "access_complete <= read_en || write_en"
                }
            }
        }
    }

}

odfi::closures::oproc writeInstances {object} {
    $object walkDepthFirst {
        if {[$it isa osys::rfg::Register]} {
            set register $it
            $it onEachField {
                $it onAttributes {hardware.osys::rfg::counter} {
                    writeCounterModule $register $it
                }
            }
        }
        if {[$it isa osys::rfg::RamBlock]} {
            if {![$it hasAttribute hardware.osys::rfg::external]} {
                writeRamModule $it
            }
        }
        
        if {[$it isa osys::rfg::RegisterFile]} {
            $it onAttributes {hardware.osys::rfg::internal} {
                writeRFModule $it
            }
            return false
        } else {
            return true
        }
    }
}

odfi::closures::oproc writeAddrComment {object} {
    set str {}
    $object walkDepthFirst {
        if {(![$it isa osys::rfg::Group] && ![$it isa osys::rfg::Aligner]) || [$it isa osys::rfg::RegisterFile]} {
            lappend str "[getName $it]: relative Address([expr [getAddrBits $object] - 1]:[getRFAddrOffset $object]) : [expr [$it getAttributeValue software.osys::rfg::relative_address] / 2**[getRFAddrOffset $object] ] size (Byte): [$it getAttributeValue software.osys::rfg::size]"
            lappend str "InternalDebug: relativeAddress(Byte) : [expr [$it getAttributeValue software.osys::rfg::relative_address]]"
        }
        if {[$it isa osys::rfg::RegisterFile]} {
            return false
        } else {
            return true
        }
    }
    setCommentHeader [join $str "\n"]
}

osys::verilogInterface::module [$rf name] {
    writeAddrComment $rf
    ## Write RegisterFile Signal Interface
    writeVModuleInterface $rf

} body {
    set res_type "sync" 
    $options onAttributes {options.::reset} {
        set res_type [$options getAttributeValue options.::reset]
    }
    #set always_content "posedge clk"
    #$options onAttributes {options.::reset} {
    #    if {[$options getAttributeValue options.::reset] != "sync"} {
    #        set always_content "posedge clk or negedge res_n"    
    #    }
    #}
    ## Write Internal Signals
    writeInternalSigs $rf

    ## Write RAM/RF/Counter Instances
    writeInstances $rf
    
    ## Write Hardware/Software Write Interface/Always Block
    writeWriteInterface $rf
    
    ## Writhe the Software Read Interface/ Address Decoder
    writeSoftReadInterface $rf

}
