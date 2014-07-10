package provide osys::rfg::generator::rfsannoXML 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0
package require odfi::files

package require odfi::ewww::webdata 1.0.0

namespace eval osys::rfg::generator::rfsannoXML {


    proc ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"

    ##############################
    ## Implementation of generator
    ##############################
    itcl::class RfsannoXML {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }
        public method produceToFile targetFile {
            set res [produce ]
            odfi::files::writeToFile $targetFile $res 
        }
        public method produce args {


            ## Create Special Stream 
            set out [odfi::common::newStringChannel]

            writeGroup $out $registerFile

            flush $out
            set res [read $out]
            close $out
            return $res

            odfi::common::println "<regroot name=\"[$registerFile name]\" >"  $out 
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
            odfi::common::println "</regroot>"  $out 

        

            ## Read  form special stream and return 
            flush $out
            set res [read $out]
            close $out
            return $res



        }

        public method writeGroup {out group} {

            ## No Name on top 
            set name ""
            if {[$group parent]!=""} {
                set name "name=\"[$group name]\""
            }

            if {[$group isa osys::rfg::RegisterFile]} {
                odfi::common::println "<regfile $name external=\"1\" desc=\"[$group description]\">"  $out
            } else {
                odfi::common::println "<regroot $name desc=\"[$group description]\">"  $out
            } 
            odfi::common::printlnIndent
            

            ## Write Groups and Registers
            $group onEachComponent {
                #puts "Component: $it"
                if {[$it isa osys::rfg::Group]} {
                    writeGroup $out $it                
                } else {
                    writeRegister $out $it
                }
            } 

            odfi::common::printlnOutdent
            if {[$group isa osys::rfg::RegisterFile]} {
                odfi::common::println "</regfile>"  $out 
            } else {
                odfi::common::println "</regroot>"  $out 
            }

        }

        public method writeRegister {out register} {

             #puts "Reg: $register"

            if {[$register isa osys::rfg::RamBlock]} {
                odfi::common::println "<ramblock name=\"[$register name]\" desc=\"[$register description]\" absolute_address=\"[$register getAttributeValue software.osys::rfg::absolute_address]\" addrsize=\"[ld $register depth]\" width=\"[$register size]\">"  $out                         
            } else {
                odfi::common::println "<reg64 name=\"[$register name]\" desc=\"[$register description]\" absolute_address=\"[$register getAttributeValue software.osys::rfg::absolute_address]\">"  $out 
            }
            odfi::common::printlnIndent

            ## rreinit source 
            $register onAttribute {hardware.osys::rfg::rreinit_source} {
                ## ToDo check for =1 and rreinit source name 
                odfi::common::println "<rreinit_source/>" $out 
            }

            ## Write Fields
            ######################
            $register onEachField {
                writeField $out $it
            }


            odfi::common::printlnOutdent
            if {[$register isa osys::rfg::RamBlock]} {
                odfi::common::println "</ramblock>"  $out            
            } else {
                odfi::common::println "</reg64>"  $out
            } 


        }

        public method writeField {out field} {

            ## Reset 
            set reset "reset=\"[$field reset]\""

            ## Prepare attributes
            set attributes [list ]

            $field onAttribute {hardware.osys::rfg::rw} {
                lappend attributes "hw=\"rw\""
            } otherwise {

                $field onAttribute {hardware.osys::rfg::ro} {
                    lappend attributes "hw=\"ro\""
                } otherwise {

                    $field onAttribute {hardware.osys::rfg::wo} {
                        lappend attributes "hw=\"wo\""
                    } otherwise {
                        lappend attributes "hw=\"\""
                    }
                }
            }

            $field onAttribute {software.osys::rfg::rw} {
                lappend attributes "sw=\"rw\""
            } otherwise {

                $field onAttribute {software.osys::rfg::ro} {
                    lappend attributes "sw=\"ro\""
                } otherwise {

                    $field onAttribute {software.osys::rfg::wo} {
                        lappend attributes "sw=\"wo\""
                    } otherwise {
                        lappend attributes "sw=\"\""
                    }
                }
            }

            $field onAttribute {hardware.osys::rfg::counter} {
                lappend attributes "counter=\"1\""
            }

            $field onAttribute {hardware.osys::rfg::rreinit} {
                lappend attributes "rreinit=\"1\""
            }

            $field onAttribute {hardware.osys::rfg::hardware_wen} {
                lappend attributes "hw_wen=\"1\""
            }

            $field onAttribute {hardware.osys::rfg::sofware_written} {
                lappend attributes "sw_written=\"[$it getAttributeValue hardware.osys::rfg::software_written]\""
            }

            $field onAttribute {hardware.osys::rfg::hardware_clear} {
                lappend attributes "hw_clr=\"1\"" 
            }

            $field onAttribute {hardware.osys::rfg::sticky} {
                lappend attributes "sticky=\"1\""
            }

            $field onAttribute {hardware.osys::rfg::software_write_xor} {
                lappend attributes "sw_write_xor=\"1\""
            }

            $field onAttribute {software.osys::rfg::software_write_clear} {
                lappend attributes "sw_write_clr=\"1\""
            }

            ## Output 
            if {[[$field parent] isa osys::rfg::RamBlock]} {

                odfi::common::println "<field name=\"[$field name]\"  width=\"[$field width]\" desc=\"[$field description]\" $reset [join $attributes] />"  $out 

            }  else {

                odfi::common::println "<hwreg name=\"[$field name]\"  width=\"[$field width]\" desc=\"[$field description]\" $reset [join $attributes] />"  $out 
            }
            
        }

    }

}
