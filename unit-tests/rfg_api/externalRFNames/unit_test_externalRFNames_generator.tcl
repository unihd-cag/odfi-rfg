package require osys::rfg 
package require osys::generator

readRF "externalRFNames.rf"
set result $osys::generator::registerFile
set i 0
$result walkDepthFirst {
    if {[$it isa osys::rfg::RegisterFile]} {
        if {$i == 0} {
            if {[$it name] != "subRF"} {
                error "Unit Test failed name should be subRF but is [$it name]"
            } 				
        }
        if {$i == 1} {
            if {[$it name] != "test"} {
                error "Unit Test failed name should be test but is [$it name]"
            } 				
        }
        if {$i == 2} {
            if {[$it name] != "test2"} {
                error "Unit Test failed name should be test2 but is [$it name]"
            } 				
        }
        if {$i == 3} {
            if {[$it name] != "test4"} {
                error "Unit Test failed name should be test4 but is [$it name]"
            } 				
        }
        if {$i > 3} {
            if {[$it name] != "subRF_[expr $i - 4]"} {
                error "Unit Test failed name should be subRF_[expr $i - 4] but is [$it name]"
            }
        }
        puts $i
        incr i
    }
    return true
}
puts "Unit Test succeded"

