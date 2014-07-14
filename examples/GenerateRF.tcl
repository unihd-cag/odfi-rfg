#!/bin/tclsh
package require osys::rfg 1.0.0
package require osys::rfg::address::hierarchical
package require osys::rfg::generator::veriloggenerator
package require osys::rfg::generator::htmlbrowser
package require osys::rfg::generator::rfsannoXML


#########################################################
## Output folders for the generated files
#########################################################
set verilog_folder ""
set doc_folder ""
set xml_folder ""

## reading the top.rf file 
if {$argc == 1} {
	set rf_head [lindex $argv 0]
	puts ""
	puts "Using [lindex $argv 0] as top rf file"
	puts ""
} else {
	puts ""
	error "Wrong number of arguments!\n\nTool usage: tclsh GenerateRF.tcl <top_level_rf_file>\n\n"
}
catch {namespace inscope osys::rfg {source $rf_head}} rf_head

set rf_list {}
set generated_list {}

## add top register file to list
lappend rf_list $rf_head

## add all underlaying register files
$rf_head walkDepthFirst {
	if {[$it isa osys::rfg::RegisterFile]} {
		lappend rf_list $it
	}
	return true
}

## walk through all registerFiles in the list
foreach rf $rf_list {
		## only generate files when the file name was not generated before...
		if {[lsearch $generated_list [$rf getAttributeValue rfg.osys::rfg::file]] == -1} {
			## add file name to generated list
			lappend generated_list [$rf getAttributeValue rfg.osys::rfg::file]

			puts ""
			puts "Reading $rf"
			puts ""
			
			## read the registerfile
			catch {namespace inscope osys::rfg {source [$rf getAttributeValue rfg.osys::rfg::file]}} result
			
			## calculate addresses
			osys::rfg::address::hierarchical::calculate $result

			## generate verilog code
			set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]
			if {[$rf parent]== ""} {
				set destinationFile "${verilog_folder}RF_Wrapper.v"
	  			$veriloggenerator produce_RF_Wrapper $destinationFile
	  			puts ""
	  			puts "generate RF_Wrapper:"
	  			puts "[$result name].rf > ${verilog_folder}RF_Wrapper.v"
	  			puts ""
			}
			set destinationFile "${verilog_folder}[$result name].v"
			$veriloggenerator produce_RegisterFile $destinationFile
			puts ""
	 		puts "generate verilog description:"
	 		puts "[$result name].rf > ${verilog_folder}[$result name].v"
	 		puts ""			

	 		## generate html documentation
	 		set htmlbrowser [::new osys::rfg::generator::htmlbrowser::HTMLBrowser #auto $result]
	 		set destinationFile "${doc_folder}[$result name].html"
	 		$htmlbrowser produceToFile $destinationFile
	 		puts ""
	 		puts "generate htmlbrowser:"
	 		puts "[$result name].rf > ${doc_folder}[$result name].html"
 			puts ""

 			## generate annotated rfs xml file 
 			set rfsannoXML [::new osys::rfg::generator::rfsannoXML::RfsannoXML #auto $result]
 			set destinationFile "[$result name].xml"
 			$rfsannoXML produceToFile $destinationFile 
		}
}