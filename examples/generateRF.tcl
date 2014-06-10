source ../tcl/rfg.tm
source ../verilog-generator/VerilogGenerator.tm
source ../tcl/generator-htmlbrowser/htmlbrowser.tm
source ../tcl/address-hierarchical/address-hierarchical.tm


if {$argc > 0} {
	set path [lindex $argv 1]
	puts "searching in path: [lindex $argv 1]"
} else {
	set path ./
	puts "searching in path: ./"
}

set rf_fileList [glob -path $path *.rf]

puts "found the following registerfiles:"

foreach rf_file $rf_fileList {
	puts $rf_file
}

puts "processing registerfiles:"
foreach rf_file $rf_fileList {

	catch {namespace inscope osys::rfg {source $rf_file}} result

	osys::rfg::address::hierarchical::calculate $result
	##osys::rfg::address::hierarchical::printTable $result

	set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]
	set destinationFile "[file rootname $rf_file].v"
	$veriloggenerator produce_RegisterFile $destinationFile
	puts ""
	puts "generate verilog description:"
	puts "$rf_file > [file rootname $rf_file].v"
	puts ""

	set htmlbrowser [::new osys::rfg::generator::htmlbrowser::HTMLBrowser #auto $result]
	set destinationFile "[file rootname $rf_file].html"
	$htmlbrowser produceToFile $destinationFile
	puts ""
	puts "generate htmlbrowser:"
	puts "$rf_file > [file rootname $rf_file].html"
	puts ""
}

