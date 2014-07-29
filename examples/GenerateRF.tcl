#!/bin/tclsh
package require osys::rfg 1.0.0
package require osys::rfg::address::hierarchical
package require osys::rfg::generator::veriloggenerator
package require osys::rfg::generator::htmlbrowser
package require osys::rfg::generator::rfsbackport
package require osys::rfg::generator::rfgheader

#########################################################
## Output folders for the generated files
#########################################################
set verilog_folder "verilog/"
set doc_folder "doc/"
set xml_folder "anot_xml/"
set verilog_header_folder "../include/"

## reading the top.rf file 
if {$argc == 1} {
	if {[lindex $argv 0]== "--cleanup"} {
		puts "finding files to delete:"
		set rf_files [glob *.rf]
		lappend rf_files [glob *.tcl]
		set all_files [glob *]
		foreach case {"dryrun" "delete"} {
			if {$case == "delete"} {
				puts "Do you want to continue?\[y,n\]"
		 		set selection [gets stdin]
			}
			foreach file $all_files {
			 	if {[lsearch $rf_files $file] == -1} {
			 		if {$case== "dryrun"} {
			 			puts "\"$file\" will be deleted..." 
			 		} else {
			 			if {$selection == "y"} {
			 				puts "Deleting $file"
			 				file delete -force $file
			 			}
			 		}
			 	}
			}
		}
		exit 2 
	}

	set rf_head [lindex $argv 0]
	puts ""
	puts "Using [lindex $argv 0] as top rf file"
	puts ""

} else {

	puts ""
	error "Wrong number of arguments!\n\nTool usage: tclsh GenerateRF.tcl <top_level_rf_file>\n\n"

}
catch {namespace inscope osys::rfg {source $rf_head}} rf_head

file mkdir $verilog_folder $doc_folder $xml_folder $verilog_header_folder

set rf_list {}
set generated_list {}
set fp [open "${verilog_folder}/[$rf_head name].f" w]

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
	  			puts $fp "[pwd]/$destinationFile"
	  			puts ""
	  			puts "generate RF_Wrapper:"
	  			puts "[$result name].rf > $destinationFile"
	  			puts ""

	  			## generate annotated rfs xml file 
	 			set rfsbackport [::new osys::rfg::generator::rfsbackport::Rfsbackport #auto $result]
	 			set destinationFile "${xml_folder}[$result name].anot.xml"
	 			$rfsbackport produceToFile $destinationFile 
	 			puts ""
		 		puts "generate xml:"
		 		puts "[$result name].rf > $destinationFile"
	 			puts ""

	 			## generate rfg verilog header file 
	 			set rfgheader [::new osys::rfg::generator::rfgheader::Rfgheader #auto $result]
	 			set destinationFile "${verilog_header_folder}rfg_v.h"
	 			$rfgheader produceToFile $destinationFile 
	 			puts ""
		 		puts "generate header file:"
		 		puts "[$result name].rf > $destinationFile"
	 			puts ""
			}
			set destinationFile "${verilog_folder}[$result name].v"
			$veriloggenerator produce_RegisterFile $destinationFile
			puts $fp "[pwd]/$destinationFile"
			puts ""
	 		puts "generate verilog description:"
	 		puts "[$result name].rf > $destinationFile"
	 		puts ""			

	 		## generate html documentation
	 		set htmlbrowser [::new osys::rfg::generator::htmlbrowser::HTMLBrowser #auto $result]
	 		set destinationFile "${doc_folder}[$result name].html"
	 		$htmlbrowser produceToFile $destinationFile
	 		puts ""
	 		puts "generate htmlbrowser:"
	 		puts "[$result name].rf > $destinationFile"
 			puts ""
		}
}