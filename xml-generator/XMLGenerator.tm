package provide osys::rfg::xmlgenerator 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::rfg::xmlgenerator {


    itcl::class XMLGenerator {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

        public method writeDescription {out object} {
            if {[$object description] != ""} {
                odfi::common::println "<Description>"  $out
                odfi::common::printlnIndent
                odfi::common::println "<!\[CDATA\[[$object description]\]\]>"  $out
                odfi::common::printlnOutdent            
                odfi::common::println "</Description>"  $out
            }
        }

        public method produce args {


            ## Create Special Stream 
            set out [odfi::common::newStringChannel]

            odfi::common::println "<RegisterFile name=\"[$registerFile name]\" relative_address=\"0x[format %X [$registerFile address]]\" \
                                    absolute_address=\"0x[format %X [$registerFile getAbsoluteAddress]]\" size=\"[$registerFile size]\">"  $out 
            odfi::common::printlnIndent
            writeDescription $out $registerFile

            ## Write Components
            $registerFile onEachComponent {
                if {[$it isa osys::rfg::Group]} {
                    writeGroup $out $it                
                } else {
                    writeRegister $out $it
                }
            }
 
            odfi::common::printlnOutdent
            odfi::common::println "</RegisterFile>"  $out 

        

            ## Read  form special stream and return 
            flush $out
            set res [read $out]
            close $out
            return $res



        }

        public method writeGroup {out group} {
            if {[$group isa osys::rfg::RegisterFile]} {
                odfi::common::println "<RegisterFile name=\"[$group name]\" relative_address=\"0x[format %X [$group address]]\" \
                                        absolute_address=\"0x[format %X [$group getAbsoluteAddress]]\" size=\"[$group size]\">"  $out
            } else {
                odfi::common::println "<Group name=\"[$group name]\" relative_address=\"0x[format %X [$group address]]\" \
                                        absolute_address=\"0x[format %X [$group getAbsoluteAddress]]\" size=\"[$group size]\">"  $out
            } 
            odfi::common::printlnIndent
            writeDescription $out $group
            ## Write Groups and Registers
            $group onEachComponent {
                if {[$it isa osys::rfg::Group]} {
                    writeGroup $out $it                
                } else {
                    writeRegister $out $it
                }
            } 

            odfi::common::printlnOutdent
            if {[$group isa osys::rfg::RegisterFile]} {
                odfi::common::println "</RegisterFile>"  $out 
            } else {
                odfi::common::println "</Group>"  $out 
            }

        }

        public method writeRegister {out register} {
            if {[$register isa osys::rfg::RamBlock]} {
                odfi::common::println "<RamBlock name=\"[$register name]\" depth=\"[$register depth]\" relative_address=\"0x[format %X [$register address]]\" \
                                        absolute_address=\"0x[format %X [$register getAbsoluteAddress]]\" size=\"[$register size]\">"  $out                         
            } else {
                odfi::common::println "<Register name=\"[$register name]\" relative_address=\"0x[format %X [$register address]]\" \
                                        absolute_address=\"0x[format %X [$register getAbsoluteAddress]]\" size=\"[$register size]\">"  $out 
            }
            odfi::common::printlnIndent
            writeDescription $out $register
            ## Write Fields
            $register onEachField {
                writeField $out $it
            }

            odfi::common::printlnOutdent
            if {[$register isa osys::rfg::RamBlock]} {
                odfi::common::println "</RamBlock>"  $out            
            } else {
                odfi::common::println "</Register>"  $out
            } 


        }

        public method writeField {out field} {

            ## Reset 
            set reset "reset=\"[$field reset]\""

            ## Output 
            odfi::common::println "<Field name=\"[$field name]\"  width=\"[$field width]\" $reset >"  $out 
            odfi::common::printlnIndent
            writeDescription $out $field
            $field onEachAttributes {
                    writeAttributes $out $attrs        
            }
            odfi::common::printlnOutdent
            odfi::common::println "</Field>" $out
        }

        public method writeAttributes {out attributes} {
                       
            odfi::common::println "<Attributes for=\"[$attributes name]\">"  $out
            odfi::common::printlnIndent
            writeDescription $out $attributes            
            foreach element [$attributes attr_list] { ## write each attribute
               if {[llength $element] == 2} {
                    odfi::common::println "<Attribute name=\"[lindex $element 0]\">[lindex $element 1]</Attribute>"  $out
               } else {
                    odfi::common::println "<Attribute name=\"$element\"/>"  $out
               }
            }
            odfi::common::printlnOutdent
            odfi::common::println "</Attributes>" $out
        }

    }


}
