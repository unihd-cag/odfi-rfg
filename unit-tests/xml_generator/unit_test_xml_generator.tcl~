package require odfi::dom

source ../../tcl/rfg.tm
source ../../xml-generator/XMLGenerator.tm

set result ""

## parse register file and catch an invalid description
catch {source regfile.rf} result
if {$result != "::extoll_rf"} {
    error "unit test failed expected no error parsing regfile.rf got the following error message:\n $result"
} else {

    ## write xml file from parsed register file
    set filename "compare_data/regfile.xml"
    set fileId [open $filename "w"]
    
    ## calculate the addresses    
    $result getAbsoluteAddress

    ## generate xml and write into file
    set xmlgenerator [::new osys::rfg::xmlgenerator::XMLGenerator #auto $result]
    puts -nonewline $fileId [$xmlgenerator produce]
    close $fileId
    puts "xml is written!"
    
    ## parse compare xml and read xml into a string 
    set xml [odfi::dom::buildDocumentFromFile "compare_data/regfile.xml"]
    set compare [odfi::dom::buildDocumentFromFile "compare_data/regfile_compare.xml"] 
    set xml_string [odfi::dom::toIndentedString $xml]
    set compare_string [odfi::dom::toIndentedString $compare]
    puts "xml parsing successfull!"
    
    ## compare the two strings
    if {$xml_string != $compare_string} {
        error("unit test failed the generated xml differs from the compare file!\n")
    } else {
        puts "unit test succeeded!"
    }
    
}


