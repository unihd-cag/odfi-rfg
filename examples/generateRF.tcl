#!/bin/tclsh
source $::env(RFG_PATH)/tcl/rfg.tm
source $::env(RFG_PATH)/verilog-generator/VerilogGenerator.tm
source $::env(RFG_PATH)/tcl/generator-htmlbrowser/htmlbrowser.tm
source $::env(RFG_PATH)/tcl/address-hierarchical/address-hierarchical.tm

set rf_list {}

proc registerFileWalk {rf} \
{
	global rf_list
	lappend rf_list [$rf getAttributeValue rfg.osys::rfg::file]
	$rf walkDepthFirst {
		if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
			registerFileWalk $it
		}

		return true
	}	
}

if {$argc == 1} {
	set rf_head [lindex $argv 0]
	puts ""
	puts "Using [lindex $argv 0] as top rf file"
	puts ""
} else {
	puts ""
	puts "No top rf file defined..."
	puts ""
}

set rf_head externalRFNames.rf

catch {namespace inscope osys::rfg {source $rf_head}} head_result

registerFileWalk $head_result

set generated_list {}

foreach rf $rf_list {
	
	if {[lsearch $generated_list $rf] == -1} {
		
		lappend generated_list $rf

		puts ""
		puts "Reading $rf"
		puts ""

		catch {namespace inscope osys::rfg {source $rf}} result
		osys::rfg::address::hierarchical::calculate $result 
		##osys::rfg::address::hierarchical::printTable $result
		
		set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]
		
		if {$head_result == $result} {
		 	set destinationFile "RF_Wrapper.v"
	  		$veriloggenerator produce_RF_Wrapper $destinationFile
	  		puts ""
	  		puts "generate RF_Wrapper:"
	  		puts "[$result name].rf > RF_Wrapper.v"
	  		puts ""
		}

		
		set destinationFile "[$result name].v"
	 	
		$veriloggenerator produce_RegisterFile $destinationFile
		puts ""
	 	puts "generate verilog description:"
	 	puts "[$result name].rf > [$result name].v"
	 	puts ""

	 	set htmlbrowser [::new osys::rfg::generator::htmlbrowser::HTMLBrowser #auto $result]
	 	set destinationFile "[$result name].html"
	 	
	 	$htmlbrowser produceToFile $destinationFile
	 	puts ""
	 	puts "generate htmlbrowser:"
	 	puts "[$result name].rf > [$result name].html"
 		puts ""
 	}
}