#!/bin/tclsh
source $::env(RFG_PATH)/tcl/rfg.tm
source $::env(RFG_PATH)/verilog-generator/VerilogGenerator.tm
source $::env(RFG_PATH)/tcl/generator-htmlbrowser/htmlbrowser.tm
source $::env(RFG_PATH)/tcl/address-hierarchical/address-hierarchical.tm

if {$argc == 1} {
	set rf_head [lindex $argv 0]
	puts ""
	puts "Using [lindex $argv 0] as top rf file"
	puts ""
} else {
	puts "No top rf file defined..."
}

set rf_list {}

proc registerFileWalk {rf} \
{
	global rf_list
	lappend rf_list $rf
	$rf walkDepthFirst {
		if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
			registerFileWalk $it
		}

		return true
	}	
}

catch {namespace inscope osys::rfg {source $rf_head}} result

registerFileWalk $result

foreach rf $rf_list {
	
	osys::rfg::address::hierarchical::calculate $rf 
	##osys::rfg::address::hierarchical::printTable $result
	
	set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $rf]
	
	if {[$rf parent] == ""} {
	 	set destinationFile "RF_Wrapper.v"
  		$veriloggenerator produce_RF_Wrapper $destinationFile
  		puts ""
  		puts "generate RF_Wrapper:"
  		puts "[$rf name].rf > RF_Wrapper.v"
  		puts ""
	}

	
	set destinationFile "[$rf name].v"
 	
	$veriloggenerator produce_RegisterFile $destinationFile
	puts ""
 	puts "generate verilog description:"
 	puts "[$rf name].rf > [$rf name].v"
 	puts ""

 	set htmlbrowser [::new osys::rfg::generator::htmlbrowser::HTMLBrowser #auto $rf]
 	set destinationFile "[$rf name].html"
 	
 	$htmlbrowser produceToFile $destinationFile
 	puts ""
 	puts "generate htmlbrowser:"
 	puts "[$rf name].rf > [$rf name].html"
 	puts ""
}