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
    foreach rf [itcl::find objects -isa osys::rfg::RegisterFile] {
            $rf getAbsoluteAddress        
    }

    foreach rf [itcl::find objects -isa osys::rfg::RegisterFile ] {       
        if {[$rf parent] == ""} {
            set xmlgenerator [::new osys::rfg::xmlgenerator::XMLGenerator #auto $rf]
            puts -nonewline $fileId [$xmlgenerator produce]
        }
    }
    close $fileId
    puts "xml is written!"
    ## parse compare xml and written xml 
    set xml [odfi::dom::buildDocumentFromFile "compare_data/regfile.xml"]
    set compare [odfi::dom::buildDocumentFromFile "compare_data/regfile_compare.xml"] 
    odfi::dom::toIndentedString $xml
    odfi::dom::toIndentedString $compare
    set fileId_xml [open "compare_data/regfile.xml" "w"]
    set fileId_compare [open "compare_data/regfile_compare.xml" "w"]

    ## write xml
    puts -nonewline $fileId_xml [::dom::DOMImplementation serialize $xml -method xml -indent false -encoding UTF-8]
    puts -nonewline $fileId_compare [::dom::DOMImplementation serialize $compare -method xml -indent false -encoding UTF-8]
    close $fileId_xml
    close $fileId_compare
    puts "xml parsing successfull!"
    
    ## make a diff on the two files catch resulting output
    catch {exec diff compare_data/regfile.xml compare_data/regfile_compare.xml} result
    if {$result != ""} {
        error("unit test failed the generated xml differs from the compare file a diff gives the following error:\n $result")
    } else {
        puts "unit test succeeded!"
    }
    
}


