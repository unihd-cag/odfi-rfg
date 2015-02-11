package require osys::rfg
package require HelperFunctions
catch {namespace eval osys::rfg:: {source ../../examples/ExampleRF.rf}} rf
source VerilogInterface.tm

osys::verilogInterface::module [$rf name] {

    $rf walkDepthFirst {
        
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
