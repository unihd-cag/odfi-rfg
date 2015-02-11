package require osys::rfg
package require HelperFunctions
catch {namespace eval osys::rfg:: {source ../../examples/ExampleRF.rf}} rf
source VerilogInterface.tm

osys::verilogInterface::module [$rf name] {

    $rf walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::external} {
                
                output [getName $it]_rf_addr wire [ld [$it depth]] 

                $it onRead {software} {
                    output [getName $it]_rf_ren reg 1
                    input [getName $it]_rf_rdata wire [$it width]
                }

                $it onWrite {software} {
                    output [getName $it]_rf_wen reg 1
                    output [getName $it]_rf_wdata wire [$it width]
                }

                input [getName $it]_rf_access_complete wire 1


            } otherwise {
                
                if {$it hasAttribute hardware.osys::rfg::ro || \
                    $it hasAttribute hardware.osys::rfg::wo || \
                    $it hasAttribute hardware.osys::rfg::rw} {
                    input [getName $it]_addr wire [ld [$it depth]]
                }

                $it onRead {hardware} {
                    input [getName $it]_ren wire 1
                    output [getName $it]_rdata wire [$it width]
                }

                $it onWrite {hardware} {
                    input [getName $it]_wen wire 1
                    input [getName $it]_wdata wire [$it width]
                }
            
            }
        }

        if {[$it isa osys::rfg::Register]} {
        
            $it onEachField {

                $it onAttributes {hardware.osys::rfg::ro} {

                }

                $it onAttributes {hardware.osys::rfg::wo} {

                }

                $it onAttributes {hardware.osys::rfg::rw} {
                    input [getName $it]_next wire [$it width]
                    output [getName $it] reg [$it width]
                }
            }
        }

        if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
            return false	
        } else {
            return true
        }
    }

} body {
   ::puts "I am in the body"
}
