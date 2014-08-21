source ../../../tcl/rfg.tm
source ../../../tcl/generator-verilog/VerilogGenerator.tm
source ../../../tcl/address-hierarchical/address-hierarchical.tm
source ../../../tcl/generator-htmlbrowser/htmlbrowser.tm

set rf_fileList [glob *.rf]
foreach rf_file $rf_fileList {

	catch {namespace inscope osys::rfg {source $rf_file}} result

	puts "Processes RF: $result"
	puts [$result name]
	puts [$result getAttributeValue rfg.osys::rfg::file]
	set i 0
	$result walkDepthFirst {
		if {[$it isa osys::rfg::RegisterFile]} {
			puts [$it name]
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
			puts [$it getAttributeValue rfg.osys::rfg::file]
		}
		return true
	}
	puts "Unit Test succeded"
}

