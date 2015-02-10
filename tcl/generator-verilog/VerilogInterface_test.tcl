
package require osys::rfg
catch {namespace eval osys::rfg:: {source ../../examples/ExampleRF.rf}} rf
puts $rf
source VerilogInterface.tm

osys::verilogInterface::module TestModule {
    $rf walkDepthFirst {
        if {[$it isa osys::rfg::Register]} {
            $it onEachField {
                $it onAttributes {hardware.osys::rfg::rw} {
                    input [$it name]_next wire [$it width]
                    output [$it name] reg [$it width]
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
