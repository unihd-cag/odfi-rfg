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

package provide osys::rfg::generator::scalamenu 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::generator::scalamenu {

    itcl::class Scalamenu {

        public variable registerFile 

        constructor cRegisterFile {
            set registerFile $cRegisterFile
        }

        ###########################################
        ## help functions
        ###########################################     

        ## does group/registerFile contain registers?
        public method containsRegisters {instance} {
            set result false
            if {[$instance isa osys::rfg::Group]} {
                $instance onEachComponent {
                    if {[$it isa osys::rfg::Register]} {
                        set result true
                    }
                }
            } else {
                ::puts "method containsRegisters should only be called for groups/registerFiles"
            }
            return $result
        }

        ## decide if HexConversions is needed within a class/object
        public method needsHexConversions {instance} {
            if {[$instance isa osys::rfg::RamBlock]} {
                return true
            } elseif {[$instance isa osys::rfg::Group]} {
                if {[containsRegisters $instance]} {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }

        ## get the absolute address of the instance as hex
        public method getHexAddress {instance} {
            return "0x[format %x [$instance getAttributeValue software.osys::rfg::absolute_address]]"
        }

        ###########################################
        ## produce
        ###########################################        

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            ::puts "scalamenu Generator processing $registerFile > ${destinationPath}[$registerFile name].scala"
            set res [produce_RegisterFile ]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].scala $res
        }


        public method produce_RegisterFile args {
            set out [odfi::common::newStringChannel]

            ## package declaration
            odfi::common::println "package com.extoll.rfmenu\n" $out

            ## imports
            odfi::common::println "import com.extoll.utils.HexConversions"         $out
            odfi::common::println "import com.extoll.utils.menu.{Menu, MenuTrait}" $out
            odfi::common::println "import uni.hd.cag.osys.rfg.rf.device.Device\n"  $out

            ## print top registerFile object
            if {[needsHexConversions $registerFile]} {
                odfi::common::println "object RfMenu extends App with MenuTrait with HexConversions \{\n" $out
            } else {
                odfi::common::println "object RfMenu extends App with MenuTrait \{\n" $out
            }

            odfi::common::printlnIndent

            ## instantiate components within registerFile
            $registerFile onEachComponent {
                if {[$it isa osys::rfg::Register]} {
                    odfi::common::println "registerMenuItem(() => s\"Write [$it name] (current $\{Device.readRegister(0,[getHexAddress $it])\})\") \{" $out
                    odfi::common::printlnIndent
                    odfi::common::println "println(\"Enter new value:\")" $out
                    odfi::common::println "val value = hexToLong(Menu.getUserInputString())" $out
                    odfi::common::println "Device.writeRegister(0,[getHexAddress $it],value)" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "\}\n" $out
                } elseif {[$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Group]} {
                    odfi::common::println "[$it name]" $out
                }
            }

            odfi::common::printlnOutdent

            odfi::common::println "\}" $out

            flush $out
            set res [read $out]
            close $out
            return $res
        
        }
    }
}
