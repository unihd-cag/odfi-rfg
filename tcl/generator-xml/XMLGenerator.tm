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

package provide osys::rfg::generator::xmlgenerator 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::rfg::generator::xmlgenerator {


    itcl::class Xmlgenerator {

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

        public method produce {destinationPath {generator ""}} {


            ## Create Special Stream 
            set out [odfi::common::newStringChannel]

            odfi::common::println "<RegisterFile name=\"[$registerFile name]\">"  $out 
            odfi::common::printlnIndent
            writeDescription $out $registerFile

            ## Write Components
            $registerFile onEachComponent {
                if {[$it isa osys::rfg::Group]} {
                    writeGroup $out $it                
                }
                if {[$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {

                    writeRegister $out $it
                }
            }
 
            odfi::common::printlnOutdent
            odfi::common::println "</RegisterFile>"  $out 

            file mkdir $destinationPath
            ::puts "XMLGenerator processing $registerFile > ${destinationPath}[$registerFile name].xml"
            ## Read  form special stream and return 
            flush $out
            set res [read $out]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].xml $res


        }

        public method writeGroup {out group} {
            if {[$group isa osys::rfg::RegisterFile]} {
                odfi::common::println "<RegisterFile name=\"[$group name]\" >"  $out
            } else {
                odfi::common::println "<Group name=\"[$group name]\" >"  $out
            } 
            odfi::common::printlnIndent
            writeDescription $out $group
            ## Write Groups and Registers
            $group onEachComponent {
                if {[$it isa osys::rfg::Group]} {
                    writeGroup $out $it                
                }
                if {[$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
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
                odfi::common::println "<RamBlock name=\"[$register name]\" depth=\"[$register depth]\" >"  $out                         
            } else {
                odfi::common::println "<Register name=\"[$register name]\">"  $out 
            }
            odfi::common::printlnIndent
            writeDescription $out $register

            ## Write attributes 
            $register onEachAttributes {
                    writeAttributes $out $attrs        
            }

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
