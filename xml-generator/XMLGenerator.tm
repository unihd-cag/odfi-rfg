package provide osys::rfg::xmlgenerator 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::rfg::xmlgenerator {



    itcl::class XMLGenerator {

        public variable registerFile 

        constructor cRegisterFile {

            ## Init
            #########
            set registerFile $cRegisterFile
        }

        public method produce args {


            ## Create Special Stream 
            set out [odfi::common::newStringChannel]

            odfi::common::println "<RegisterFile name=\"[$registerFile name]\">"  $out 
            odfi::common::printlnIndent

            ## Write Groups 
            $registerFile onEachGroup {
                writeGroup $out $it
            }

            ## Write Registers 
            $registerFile onEachRegister {
                writeRegister $out $it
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

            odfi::common::println "<Group name=\"[$group name]\">"  $out 
            odfi::common::printlnIndent

            ## Write Groups 
            $group onEachGroup {
                writeGroup $out $it
            }

            ## Write Registers 
            $group onEachRegister {
                writeRegister $out $it
            }

            odfi::common::printlnOutdent
            odfi::common::println "</Group>"  $out 


        }

        public method writeRegister {out register} {

            odfi::common::println "<Register name=\"[$register name]\">"  $out 
            odfi::common::printlnIndent

            ## Write Fields
            $register onEachField {
                writeField $out $it
            }

            odfi::common::printlnOutdent
            odfi::common::println "</Register>"  $out 


        }

        public method writeField {out field} {

            ## Prepare Rights
            set rightsString {}
            foreach {target rights} [$field rights] {
                lappend rightsString "$target=\"[join $rights ""]\""
            }

            ## Reset 
            set reset "reset=\"[$field reset]\""

            ## Output 
            odfi::common::println "<Field name=\"[$field name]\"  width=\"[$field width]\" $reset [join $rightsString]/>"  $out 


        }

    }


}
