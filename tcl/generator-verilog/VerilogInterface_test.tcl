package require osys::rfg
package require HelperFunctions
package require osys::rfg::address::hierarchical
source VerilogInterface.tm

proc anonym_proc {name args closure} {
    set res "proc $name $args {
        uplevel 1 {$closure}
    }"
    uplevel 1 $res
}

proc getRFAddrOffset {object} {
    return [ld [expr [$object register_size]/8]]
}

proc getRFAddrWidth {object} {
    return [expr [getAddrBits $object]-[getRFAddrOffset $object]]
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
        
        if {$it hasAttribute hardware.osys::rfg::ro || \
            $it hasAttribute hardware.osys::rfg::wo || \
            $it hasAttribute hardware.osys::rfg::rw} {
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

anonym_proc writeRegisterFileInterface {it} {
    output [getName $it]_address reg [getRFAddrWidth $rf] [getRFAddrOffset $it]
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

    $rf walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlockInterface $it
        }

        if {[$it isa osys::rfg::Register]} {
            writeRegisterInterface $it
        }

        if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
            writeRegisterFileInterface $it
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
} body {
    $rf walkDepthFirst {
        
        ::if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::external} {
                
                $it onWrite {software} {
                    
                    $it onAttributes {hardware.osys::rfg::shared_bus} {
                        
                    } otherwise {

                    }
                
                } otherwise {
                    
                    $it onAttributes {hardware.osys::rfg::shared_bus} {
    
                    } otherwise {
                        
                    }

                }
            
            } otherwise {

                $it onWrite {

                }

                $it onRead {

                }
            }
        }

        ::if {[$it isa osys::rfg::Register]} {
            $it onAttributes {hardware.osys::rfg::rreinit_source} {

            } otherwise {

                $it onEachField {
                    ::if {[$it name] != "Reserved"} {
                        $it onAttributes {hardware.osys::rfg::counter} {
                            
                            ## Check if this is equivilant
                            $it onWrite {hardware} {

                            } otherwise {
                                $it onWrite {software} {

                                }
                            }

                            ::if {[$it getAttributeValue hardware.osys::rfg::software_written] == 2} {
                                
                            }
                            
                        } otherwise {
                            
                            $it onAttributes {hardware.osys::rfg::software_written} {
                                ::if {[$it getAttributeValue hardware.osys::rfg::software_written] == 2} {
                                    
                                }
                            }

                            if {![$it hasAttribute hardware.osys::rfg::ro] && ![$it hasAttribute hardware.osys::rfg::rw] } {
                            
                            }

                        }
                    }
                }
            }
        }

        ::if {[$it isa osys::rfg::RegisterFile]} {
            $it onAttributes {hardware.osys::rfg::internal} {

            }
        }

    }
    ::puts "I am in the body"
}
