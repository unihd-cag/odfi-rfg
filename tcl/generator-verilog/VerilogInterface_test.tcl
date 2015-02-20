package require osys::rfg
package require HelperFunctions
package require osys::rfg::address::hierarchical
source VerilogInterface.tm

proc anonym_proc {name args closure} {
    set res "proc $name $args {
        odfi::closures::doClosure {$closure} 1
    }"
    odfi::closures::doClosure $res 1
}

proc getRFAddrOffset {object} {
    return [ld [expr [$object register_size]/8]]
}

proc getRFAddrWidth {object} {
    return [expr [getAddrBits $object]-[getRFAddrOffset $object]]
}

proc getFirstSharedBusObject {object} {
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::shared_bus} {
                set obj $it
            }
        }
        return false
    }
    return $obj
}

proc needDelay {object} {
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            if {![$it hasAttribute hardware.osys::rfg::external]} {
                set obj $it
            }
        }
        return false
    }
    return $obj
}

anonym_proc writeRamBlockInterface {it} {
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

anonym_proc writeRegisterInterface {it} {
    $it onEachField {
        if {[$it name] != "Reserved"} {
            $it onAttributes {hardware.osys::rfg::counter} {
                ::puts "Counter In"
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
                    ::puts "s_written"
                    output [getName $it]_written [find_internalRF $it $rf]
                }

                $it onAttributes {hardware.osys::rfg::hardware_clear} {
                    ::puts "h_clear"
                    input [getName $it]_clear wire
                }
            
            }
        }
    }
}

anonym_proc writeRegisterFileInterface {it} {
    output [getName $it]_address reg [getRFAddrWidth $it] [getRFAddrOffset $it]
    input [getName $it]_invalid_address wire
    input [getName $it]_access_complete wire
    output [getName $it]_read_en reg
    input [getName $it]_read_data wire [getRFmaxWidth $it]
    output [getName $it]_write_en reg
    output [getName $it]_write_data reg [getRFmaxWidth $it]
}

anonym_proc writeVModuleInterface {rf} {
    
    input res_n wire
    input clk wire
    input address wire [getRFAddrWidth $rf] [getRFAddrOffset $rf]
    output invalid_address reg
    output access_complete reg
    input read_en wire
    output read_data reg [getRFmaxWidth $rf]
    input write_en wire
    input write_data wire [getRFmaxWidth $rf]
    ::puts "Before Walk"
    $rf walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlockInterface $it
        }

        if {[$it isa osys::rfg::Register]} {
            ::puts "RegInterface in"
            writeRegisterInterface $it
            ::puts "RegInterface out"
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

anonym_proc writeRamBlockInternalSigs {it} {

    $it onAttributes {hardware.osys::rfg::external} %%{
        
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

    } otherwise %{
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

anonym_proc writeRegisterInternalSigs {it} {   

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
                        ::if {[$it getAttributeValue hardware.osys::rfg::software_written] == 2} {
                            reg [getName $it]_res_in_last_cycle
                        }
                    }

                    ::if {![$it hasAttribute hardware.osys::rfg::ro] && \
                        ![$it hasAttribute hardware.osys::rfg::rw] } {
                        reg [getName $it]
                    }

                }
            }
        }
    }

}

anonym_proc writeRegisterFileInternalSigs {rf} {
            
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

anonym_proc writeInternalSigs {rf} {

    $rf walkDepthFirst {
        ::if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlockInternalSigs $it
        }

        ::if {[$it isa osys::rfg::Register]} {
            writeRamBlockInternalSigs $it
        }

        ::if {[$it isa osys::rfg::RegisterFile]} {
            writeRamBlockInternalSigs $it

            return false
        
        } else {

            return true

        }

    }

}

catch {namespace eval osys::rfg:: {source ../../examples/ExampleRF.rf}} rf

osys::rfg::address::hierarchical::calculate $rf

osys::verilogInterface::module [$rf name] {

    writeVModuleInterface $rf
    ::puts "WriteVModuleInterface"

} body {

    ##writeInternalSigs $rf                               

}
