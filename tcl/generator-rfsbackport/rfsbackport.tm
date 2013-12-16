package provide osys::rfg::generator::rfsbackport 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0
package require odfi::files

package require odfi::ewww::webdata 1.0.0

namespace eval osys::rfg::generator::rfsbackport {

    ##############################
    ## Implementation of generator
    ##############################
    itcl::class RFSBackport {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
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
                odfi::common::println "<ramblock name=\"[$register name]\" desc=\"[$register description]\" addrsize=\"[string length [format %b [$register depth]]]\" width=\"[$register size]\">"  $out                         
            } else {
                odfi::common::println "<reg64 name=\"[$register name]\" desc=\"[$register description]\" >"  $out 
            }
            odfi::common::printlnIndent
       

            ## Specical Stuff 
            #########################

            #$register onEachAttributes2 {
            #    puts "Attr: $it"
#
             #   $it onEachAttribute2 {
             #       puts "---> $it"
            #    }
            # }
            ## rreinit 
            if {[$register hasAttribute hardware.global.rreinit_source]} {
                odfi::common::println "<rreinit/>" $out 
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


             #$field onEachAttributes2 {
             #   puts "Attr: $it"

             #   $it onEachAttribute2 {
             #       puts "---> $it"
              #  }
             #}

            ## Prepare attributes
            set attributes [list ]
            $field onEachAttributes {

                #puts "Attributes: $attrs"
                if {[$attrs name]=="hardware"} {

                    ## Rights
                    ################
                    if {[$attrs contains "global.rw"]} {
                        lappend attributes "hw=\"rw\""
                    } elseif {[$attrs contains "global.ro"]} {
                        lappend attributes "hw=\"ro\""
                    } elseif {[$attrs contains "global.wo"]} {
                        lappend attributes "hw=\"wo\""
                    } else {
                        lappend attributes "hw=\"\""
                    }

                    ## Special stuff
                    ##################
                    if {[$attrs contains "global.counter"]} {
                        lappend attributes "counter=\"1\""
                        set reset ""
                    }
                    if {[$attrs contains "global.rreinit"]} {
                        lappend attributes "rreinit=\"1\""
                        set reset ""
                    }

                } elseif {[$attrs name]=="software"} {

                    if {[$attrs contains "global.rw"]} {
                        lappend attributes "sw=\"rw\""
                    } elseif {[$attrs contains "global.ro"]} {
                        lappend attributes "sw=\"ro\""
                    } elseif {[$attrs contains "global.wo"]} {
                        lappend attributes "sw=\"wo\""
                    } else {
                        lappend attributes "sw=\"\""
                    }

                }

            }

            ## Make sure hw and sw attributes are present
            if {[lsearch -glob $attributes "hw*"]==-1} {
                lappend attributes "hw=\"\""
            }
            if {[lsearch -glob $attributes "sw*"]==-1} {
                lappend attributes "sw=\"\""
            }

            ## Output 
            if {[[$field parent] isa osys::rfg::RamBlock]} {

                odfi::common::println "<field name=\"[$field name]\"  width=\"[$field width]\" desc=\"[$field description]\" $reset [join $attributes] />"  $out 

            }  else {

                odfi::common::println "<hwreg name=\"[$field name]\"  width=\"[$field width]\" desc=\"[$field description]\" $reset [join $attributes] />"  $out 
            }
            
    
        

        }

        

    }


    #####################
    ## Utilities
    #####################


    ## Converts the file at provided location to RFS and returns the result as string
    proc convertFileToRFS {filePath {targetFile ""}} {

        ## Convert 
        ################
        set res [namespace eval ::osys::rfg "source $filePath"]

        set gen [osys::rfg::getGenerator "RFSBackport" $res]

        set res [$gen produce]

        ## Write to file if required
        ####################
        if {$targetFile!=""} {
            odfi::files::writeToFile $targetFile $res
        }

        ## Return 
        return $res

    }


}
