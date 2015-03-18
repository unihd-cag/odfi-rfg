package require osys::rfg
package require HelperFunctions
package require osys::rfg::address::hierarchical
#source ${::osys::rfg::generator::verilog::location}/VerilogInterface.tm
source ${::osys::rfg::generator::verilog::location}/Instances.tm

set rb_save ""
proc hasRamBlock {rf} {
    global rb_save 
    if {$rb_save == ""} {
        set rb_save false
        $rf walkDepthFirst {
            if {[$it isa osys::rfg::RamBlock]} {
                if {![$it hasAttribute hardware.osys::rfg::external]} {
                    set rb_save true
                }
            }

            if {[$it isa osys::rfg::RegisterFile]} {
                return false	
            } else {
                return true
            }
        }
        return $rb_save
    } else {
        return $rb_save
    }
}

proc getRBAddrssDecode {object rf} {
    set dontCare [string repeat x [expr [ld [$object depth]] + [$object getAttributeValue software.osys::rfg::address_shift]]]
    set dontCare_width [expr [ld [$object depth]] + [$object getAttributeValue software.osys::rfg::address_shift]]
    set care [expr ([$object getAttributeValue software.osys::rfg::relative_address]/([$object depth]*[$rf register_size]/8)) >> [$object getAttributeValue software.osys::rfg::address_shift]] 
    set care [format %x $care]
    set care_width [expr [getAddrBits $rf] - [ld [$object depth]] - 3 - [$object getAttributeValue software.osys::rfg::address_shift]]
    if {$care_width == 0} {
        return "$dontCare_width'h$dontCare"
    } else {
        return "$care_width'h$care,$dontCare_width'h$dontCare"
    }
}

proc getRFAddrOffset {object} {
    return [ld [expr [$object register_size]/8]]
}
set AddrBits ""
set addr_object ""

proc getRFAddrWidth {object} {
    global AddrBits
    global addr_object
    if {$AddrBits == "" || $addr_object != $object} {
        set AddrBits [expr [getAddrBits $object]-[getRFAddrOffset $object]]
        set addr_object $object
    }
    return $AddrBits
}

proc getFirstSharedBusObject {object} {
    set obj ""
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::shared_bus} {
                set obj $it
            }
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            return false	
        } else {
            return true
        }

    }
    return $obj

}

proc needDelay {object} {
    set obj ""
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            if {![$it hasAttribute hardware.osys::rfg::external]} {
                set obj $it
            }
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            return false	
        } else {
            return true
        }
    }

    return $obj

}

proc CheckForRegBlock {object} {
    set return_value false
    if {[$object isa osys::rfg::RamBlock]} {
        $object onWrite {software} {
            set return_value true
        }

        $object onRead {software} {
            set return_value true
        }

    } else {
        $object onAttributes {hardware.osys::rfg::rreinit_source} {
            set return_value true
        } otherwise {
            $object onEachField {
                if {[$it reset] != ""} {
                    set return_value true
                }
                $it onWrite {software} {
                    set return_value true
                }
                $it onWrite {hardware} {
                    set return_value true
                }

            }
        }
    }

    return $return_value

}

proc hasReset {object} {
    set return_value false
    $object onEachField {
       if {[$it reset] != ""} {
            set return_value true 
       }
    }
    return $return_value
}

proc getRelAddress {object} {
    return [$object getAttributeValue software.osys::rfg::relative_address]
}

proc hasWrite {interface object} {
    set return_value false
    $object onEachField {
        $it onWrite $interface {
            set return_value true
        }
    }
    return $return_value
}

odfi::closures::oproc writeRamBlockInterface {it} {
    
    $it onAttributes {hardware.osys::rfg::external} {
        output [getName $it]_rf_addr wire [ld [$it depth]]

        $it onRead {software} {
            output [getName $it]_rf_ren reg
            input [getName $it]_rf_rdata wire [$it width]
        }
        $it onWrite {software} {
            output [getName $it]_rf_wen reg
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
                
                input [getName $it]_countup wire 

            } otherwise {

                $it onRead {hardware} {
                    output [getName $it] [find_internalRF $it $rf] [$it width]
                }
                
                $it onWrite {hardware} {
                    input [getName $it]_next wire [$it width]
                    
                    $it onAttributes {hardware.osys::rfg::hardware_wen} {
                        input [getName $it]_wen wire    
                    }

                }
                
                $it onAttributes {hardware.osys::rfg::software_written} {
                    output [getName $it]_written [find_internalRF $it $rf]
                }

                $it onAttributes {hardware.osys::rfg::hardware_clear} {
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
                reg address_reg [ld [$it depth]]
            }
        } otherwise {
            reg [getName $it]_address_reg [ld [$it depth]]        
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
    } otherwise {

        $it onEachField {
            ::if {[$it name] != "Reserved"} {
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

                    ::if {![$it hasAttribute hardware.osys::rfg::ro] && \
                        ![$it hasAttribute hardware.osys::rfg::rw]} {
                        wire [getName $it] [$it width]
                    }
                        
                } otherwise {
                    
                    $it onAttributes {hardware.osys::rfg::software_written} {
                        if {[$it getAttributeValue hardware.osys::rfg::software_written] == 2} {
                            reg [getName $it]_res_in_last_cycle
                        }
                    }

                    if {![$it hasAttribute hardware.osys::rfg::ro] && \
                        ![$it hasAttribute hardware.osys::rfg::rw] } {
                        reg [getName $it] [$it width]
                    }

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
    vif "(address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]:[getRFAddrOffset $rf]\] == [expr [getRelAddress [$it parent]]/8]) && write_en" {
        $it onAttributes {hardware.osys::rfg::counter} {
            vputs "[getName $it]_load_enable <= 1'b1"
            vputs "[getName $it]_load_value <= write_data\[[expr [$it width] + $offset -1]:$offset\]"
        } otherwise {
            $it onAttributes {software.osys::rfg::software_clear} {
                vputs "[getName $it] <= [$it width]'b0"
            } otherwise {
            
                $it onAttributes {software.osys::rfg::software_write_xor} {
                    vputs "[getName $it] <= write_data\[[expr [$it width] + $offset -1]:$offset\] ^ [getName $it]"
                } otherwise {
                    vputs "[getName $it] <= write_data\[[expr [$it width] + $offset - 1]:$offset\]"
                }

            }
     
            $it onAttributes {software.osys::rfg::software_written} {
                vputs "[getName $it]_written <= 1'b1"
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
        vputs "[getName $it]_written <= 1'b1"
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
        $object onAttributes {hardware.osys::rfg::hardware_clear} {
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
            $object onAttributes {hardware.osys::rfg::hardware_no_wen} { 
                writeHardFieldFunction $object      
            } otherwise {
                    vif "[getName $object]_wen" {
                        writeHardFieldFunction $object
                    }
            }
        } else {
            $object onAttributes {hardware.osys::rfg::hardware_no_wen} {
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
    $object onAttributes {hardware.osys::rfg::rreinit_source} {
        
        vif "!res_n" {
            vputs "rreinit <= 1'b0"    
        }

    } otherwise {
        
        if {[hasReset $object] == true} {
            vif "!res_n" {
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

                    } ohterwise {
                        if {[$it name] != "Reserved"} {
                            vputs "[getName $it] <= [$it reset]"
                        }
                        $it onAttributes {software.osys::rfg::software_written} {
                            vputs "[getName $it]_written <= 1'b0"
                        }
                    }
                }
            }
        }
    }
}

odfi::closures::oproc writeRegisterWrite {object} {
    $object onAttributes {hardware.osys::rfg::rreinit_source} {
        vif "(address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]:[getRFAddrOffset $rf]\] == [expr [getRelAddress $object]/8]) && write_en" {
            vputs "rreinit <= 1'b1"   
        }
        velse {
            vputs "rreinit <= 1'b0"
        }
    } otherwise {
        set offset 0
        $object onEachField {
            $it onWrite {software} {
                    writeFieldSoftWrite $it $offset            
                $it onWrite {hardware} {
                    set condition "elsecond"
                    writeFieldHardWrite $it
                }

            } otherwise {
                
                $it onWrite {hardware} {
                    set condition "ifcond"
                    writeFieldHardWrite $it
                }

            }
            
            incr offset [$it width]

        }
    }
}

odfi::closures::oproc writeRegisterBlock {object} {

    ## check if anything is generated
    if {[CheckForRegBlock $object] == true} {
        comment "Register: [getName $object]"
        always $always_content {
            ## write Reset
            writeRegisterReset $object
            ## write Software write
            $object onAttributes {hardware.osys::rfg::rreinit_source} {
                velse {
                    writeRegisterWrite $object
                }
            } otherwise {
                if {[hasWrite software $object] == true} {
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
           vputs "[getName $object]_rf_addr <= [ld [$object depth]]'b0"
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
            vputs "[getName $object]_rf_addr <= address\[$higher:$lower\]"
        }
        
        $object onWrite {software} {
            if {![$object hasAttribute hardware.osys::rfg::external]} {
                vputs "[getName $object]_wdata <= write_data\[[expr [$object width]-1]:0\]"
            }
            vputs "[getName $object]_rf_wen <= write_en"
        }
        $object onRead {software} {
            vputs "[getName $object]_rf_ren <= read_en"
        }
   
    } else {
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
                assign [getName $object]_rf_addr [getName $object]_address_reg
            }
        }
        comment "RamBlock: [getName $object]"
        always $always_content {
            writeRamBlockReset $object
            velse {
                writeRamBlockWrite $object
            }

        }

    }
}

odfi::closures::oproc writeRFBlock {object} {
    comment "RegisterFile: [getName $object]"
    always $always_content {
        vif "!res_n" {
            vputs "[getName $object]_write_en <= 1'b0"
            vputs "[getName $object]_read_en <= 1'b0"
            vputs "[getName $object]_write_data <= [getRFmaxWidth $object]'b0"
            vputs "[getName $object]_address <= [getRFAddrWidth $object]'b0"
        }
        velse {
            set upper [expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] - 1]
            set lower [expr [getRFAddrWidth $object] + [getRFAddrOffset $object]]
            set care [expr [$object getAttributeValue software.osys::rfg::relative_address] >> [getRFAddrOffset $object]]
            set care [format %x $care]
            set care_width [expr [getRFAddrWidth $rf] - [getRFAddrWidth $object]]
            vif "address\[$upper:$lower\] == $care_width'h$care" {
                vputs "subRF0_address <= address\[[expr [getRFAddrWidth $object] + [getRFAddrOffset $object] - 1]:[getRFAddrOffset $object]\]"
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
    case_select "[getRFAddrWidth $rf]'h[format %x [expr [$object getAttributeValue software.osys::rfg::relative_address] / ([$rf register_size]/8)]]" {
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
    case_select "\{[getRBAddrssDecode $object $rf]\}" {
        $object onRead {software} {
            vputs "read_data\[[expr [$object width]-1]:0\] <= [getName $object]_rf_rdata"
        }
        if {[$object width] != [getRFmaxWidth $rf]} {
            vputs "read_data\[[expr [getRFmaxWidth $rf]-1]:[$object width]\] <= [expr [getRFmaxWidth $rf] - [$object width]]'b0"
        }
        vputs "invalid_address <= 1'b0"
        vputs "access_complete <= write_en || read_en_dly2"
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
                    set lower_addr [expr [getRFAddrOffset $rf] + [$it getAttributeValue software.osys::rfg::address_shift]]
                    set higher_addr [expr [ld [$it depth]] -1 + [$it getAttributeValue software.osys::rfg::address_shift] + [getRFAddrOffset $rf]]
                    vputs "[getName $it]_address_reg <= address\[$higher_addr:$lower_addr\]"
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
    set care [expr [$object getAttributeValue software.osys::rfg::relative_address] >> [getRFAddrOffset $object]]
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
    always $always_content { 
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

            case "address\[[expr [getRFAddrWidth $rf] + [getRFAddrOffset $rf] -1]:[getRFAddrOffset $rf]\]" {
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

osys::verilogInterface::module [$rf name] {

    ## Write RegisterFile Signal Interface
    writeVModuleInterface $rf

} body {
    set always_content "posedge clk"
    $options onAttributes {options.::reset} {
        if {[$options getAttributeValue options.::reset] != "sync"} {
            set always_content "posedge clk or negedge res_n"    
        }
    }
    ## Write Internal Signals
    writeInternalSigs $rf

    ## Write RAM/RF/Counter Instances
    writeInstances $rf
    
    ## Write Hardware/Software Write Interface/Always Block
    writeWriteInterface $rf
    
    ## Writhe the Software Read Interface/ Address Decoder
    writeSoftReadInterface $rf

}
