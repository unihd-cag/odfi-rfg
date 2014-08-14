source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm
source ../../../tcl/address-hierarchical/address-hierarchical.tm
##source $::env(RFG_PATH)/tcl/generator-htmlbrowser/htmlbrowser.tm

set rf_fileList [glob *.rf]
foreach rf_file $rf_fileList {

	catch {namespace inscope osys::rfg {source $rf_file}} result

	puts "Processes RF: $result"

	osys::rfg::address::hierarchical::calculate $result
	osys::rfg::address::hierarchical::printTable $result
	##set htmlbrowser [::new osys::rfg::generator::htmlbrowser::HTMLBrowser #auto $result]
	set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]
	set destinationFile "compare_data/[file rootname $rf_file].v"

	$veriloggenerator produce_RegisterFile $destinationFile
	##set destinationFile "compare_data/[file rootname $rf_file].html"
	##$htmlbrowser produceToFile $destinationFile
	if {$result == "::hierarchicalRF"} { 
		$veriloggenerator produce_RF_Wrapper "compare_data/RF_Wrapper.v" 
	}
}

catch {exec sh "iverilog_run.sh"} result
if {$result != "VCD info: dumpfile hierarchicalRF.vcd opened for output."} {
 	error "Test failed result of the iverilog_run was:\n $result"
} else {
 	puts "Test sucessfull..."
}

