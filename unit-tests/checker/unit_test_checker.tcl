source ../../tcl/rfg.tm
source ../../xml-generator/XMLGenerator.tm
source ../../tcl/address-hierarchical/address-hierarchical.tm

set result ""

##########################################
## test checker with a valid register file
##########################################

catch {source unit_test_checker_valid.rf} result

osys::rfg::address::hierarchical::calculate $result
osys::rfg::address::hierarchical::printTable $result

#check for valid result 
if {$result != "::extoll_rf"} {
    error "unit test (invalid) failed! \nThere should not be an error the valid Registerfile, but error is:\nResult: $result"
} else {
    puts "unit test (valid) succeeded!"
    set filename "compare_data/unit_tests_valid.xml"
    set fileId [open $filename "w"]
    foreach rf [itcl::find objects -isa osys::rfg::RegisterFile] {
            $rf getAbsoluteAddress        
    }

    foreach rf [itcl::find objects -isa osys::rfg::RegisterFile ] {       
        if {[$rf parent] == ""} {
            set xmlgenerator [::new osys::rfg::xmlgenerator::XMLGenerator #auto $rf]
            puts -nonewline $fileId [$xmlgenerator produce]
        }
    }
}

#############################################
## test checker with an invalid register file
#############################################

set compare_message "The addresspan within the checker in ::osys::rfg::Group::extoll_rf.info_rf.group1 is 4104 but only 4096 addresses are allowed!"

## catch error, get message and check
catch {source unit_test_checker_invalid.rf} result
if {$result == $compare_message} {
    puts "unit test (invalid) succeeded!"
} else {
    error "unit test (invalid) failed!\nresulting message was:\n$result\nexpected message was:"
    puts $compare_message
}
