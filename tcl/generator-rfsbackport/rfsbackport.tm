## RFG Register File Generator
## Copyright (C) 2014  University of Heidelberg - Computer Architecture Group
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

package provide osys::rfg::generator::rfsbackport 1.0.0
package require osys::rfg

package require odfi::common
package require odfi::list 2.0.0
package require odfi::files

package require odfi::ewww::webdata 1.0.0

namespace eval osys::rfg::generator::rfsbackport {


   

    ##############################
    ## Implementation of generator
    ##############################
    itcl::class Rfsbackport {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

#        public method produceToFile targetFile {
#            set res [produce ]
#            odfi::files::writeToFile $targetFile $res 
#        }

        public method produce {destinationPath {generator ""}} {

            ## Create Special Stream 
            set out [odfi::common::newStringChannel]

            writeGroup $out $registerFile
            
            flush $out
            set res [read $out]
            close $out 
            
            file mkdir $destinationPath
            ::puts "Rfsbackport processing ${destinationPath}[$registerFile name].anot.xml"
            odfi::files::writeToFile ${destinationPath}[$registerFile name].anot.xml $res
                                
        }

        ##public method ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"

        public method writeGroup {out group} {

            ## No Name on top 
            set name "name=\"[$group name]\""
            if {[$group parent]==""} {
                odfi::common::println "<regfile>" $out
            } 

            odfi::common::println "<regroot $name desc=\"[$group description]\">"  $out
            
            odfi::common::printlnIndent
            

            ## Write Groups and Registers
            $group onEachComponent {
                #puts "Component: $it"
                if {[$it isa osys::rfg::Group]} {
                    writeGroup $out $it                
                }
                if {[$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
                    writeRegister $out $it
                }
            } 

            odfi::common::printlnOutdent
            odfi::common::println "</regroot>"  $out 
            if {[$group parent]==""} {
                odfi::common::println "</regfile>" $out
            }

        }

        public method writeRegister {out register} {

             #puts "Reg: $register"

            if {[$register isa osys::rfg::RamBlock]} {
                odfi::common::println "<ramblock name=\"[$register name]\" desc=\"[$register description]\" _absoluteAddress=\"0x[format %x [$register getAttributeValue software.osys::rfg::absolute_address]]\" addrsize=\"[expr {int(ceil(log([$register depth])/[expr log(2)]))}]\" width=\"[$register width]\">"  $out                         
            } else {
                odfi::common::println "<reg64 name=\"[$register name]\" desc=\"[$register description]\" _absoluteAddress=\"0x[format %x [$register getAttributeValue software.osys::rfg::absolute_address]]\">"  $out 
            }
            odfi::common::printlnIndent

            ## rreinit source 
            $register onAttributes {hardware.osys::rfg::rreinit_source} {
                ## ToDo check for =1 and rreinit source name 
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

            ## Prepare attributes
            set attributes [list ]

            $field onAttributes {hardware.osys::rfg::rw} {
                lappend attributes "hw=\"rw\""
            } otherwise {

                $field onAttributes {hardware.osys::rfg::ro} {
                    lappend attributes "hw=\"ro\""
                } otherwise {

                    $field onAttributes {hardware.osys::rfg::wo} {
                        lappend attributes "hw=\"wo\""
                    } otherwise {
                        lappend attributes "hw=\"\""
                    }
                }
            }

            $field onAttributes {software.osys::rfg::rw} {
                lappend attributes "sw=\"rw\""
            } otherwise {

                $field onAttributes {software.osys::rfg::ro} {
                    lappend attributes "sw=\"ro\""
                } otherwise {

                    $field onAttributes {software.osys::rfg::wo} {
                        lappend attributes "sw=\"wo\""
                    } otherwise {
                        lappend attributes "sw=\"\""
                    }
                }
            }

            $field onAttributes {hardware.osys::rfg::counter} {
                lappend attributes "counter=\"1\""
            }

            $field onAttributes {hardware.osys::rfg::rreinit} {
                lappend attributes "rreinit=\"1\""
            }

            if {![$field hasAttribute hardware.osys::rfg::no_wen]} {
                lappend attributes "hw_wen=\"1\""
            }

            $field onAttributes {hardware.osys::rfg::sofware_written} {
                lappend attributes "sw_written=\"[$it getAttributeValue hardware.osys::rfg::software_written]\""
            }

            $field onAttributes {hardware.osys::rfg::clear} {
                lappend attributes "hw_clr=\"1\"" 
            }

            $field onAttributes {hardware.osys::rfg::sticky} {
                lappend attributes "sticky=\"1\""
            }

            $field onAttributes {software.osys::rfg::write_xor} {
                lappend attributes "sw_write_xor=\"1\""
            }

            $field onAttributes {software.osys::rfg::write_clear} {
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
