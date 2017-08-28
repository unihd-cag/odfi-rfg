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

        ## get the name of the registerFile enclosing instance
        public method getEnclosingRF {instance} {
            if {[[$instance parent] isa osys::rfg::RegisterFile]} {
                return [$instance parent]
            } else {
                return [getEnclosingRF [$instance parent]]
            }
        }

        ## get the concat names of the groups containing instance
        public method getGroupsName {instance} {
            if {[[$instance parent] isa osys::rfg::Group]} {
                if {[[$instance parent] isa osys::rfg::RegisterFile]} {
                    return ""
                } else {
                    return "[getGroupsName [$instance parent]][[$instance parent] name]_"
                }
            } else {
                return [getGroupsName [$instance parent]]
            }
        }

        ## get the enclosing registerFile and groups extended name of instance
        public method getFullName instance {
            if {[$instance isa osys::rfg::RamBlock]} {
                return "ram_[[getEnclosingRF $instance] name]_[getGroupsName $instance][$instance name]"
            } elseif {[$instance isa osys::rfg::Register]} {
                return "reg_[[getEnclosingRF $instance] name]_[getGroupsName $instance][$instance name]"
            } elseif {[$instance isa osys::rfg::Group]} {
                if {[$instance isa osys::rfg::RegisterFile]} {
                    return "rf_[$instance name]"
                } else {
                    return "grp_[[getEnclosingRF $instance] name]_[getGroupsName $instance][$instance name]"
                }
            }
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

            ## instantiate components within top registerFile
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
                    odfi::common::println "registerMenuItem(\"[$it name]\") \{" $out

                    odfi::common::printlnIndent
                    odfi::common::println "(new [getFullName $it]_menu).runMenu()" $out
                    odfi::common::printlnOutdent

                    odfi::common::println "\}\n" $out
                }
            }

            odfi::common::println "runMenu(true)" $out
            odfi::common::printlnOutdent

            odfi::common::println "\}\n" $out

            ## declare classes for sub-components
            $registerFile walkDepthFirst {

                ## RamBlock
                if {[$it isa osys::rfg::RamBlock]} {
                    odfi::common::println "class [getFullName $it]_menu extends MenuTrait with HexConversions \{\n" $out

                    ## MenuHeader
                    odfi::common::printlnIndent
                    odfi::common::println "registerMenuHeader(\"[$it name] Menu\")\n" $out

                    ## read entry
                    odfi::common::println "registerMenuItem(\"Read Entry\") \{" $out
                    odfi::common::printlnIndent
                    odfi::common::println "println(\"Select Entry:\")" $out
                    odfi::common::println "var entry = Menu.getUserInput()\n" $out
                    ## error checking
                    odfi::common::println "while (entry < 0 || entry >= [$it depth]) \{" $out
                    odfi::common::printlnIndent
                    odfi::common::println "println(\"Specified entry does not exist for RamBlock [$it name] (size [$it depth]). Select Entry:\")" $out
                    odfi::common::println "entry = Menu.getUserInput()" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "\}\n" $out

                    odfi::common::println "println(Device.readRegister(0,[getHexAddress $it]+(8*entry)).ToHexString)" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "\}\n" $out

                    ## write entry
                    odfi::common::println "registerMenuItem(\"Write Entry\") \{" $out
                    odfi::common::printlnIndent
                    odfi::common::println "println(\"Select Entry:\")" $out
                    odfi::common::println "var entry = Menu.getUserInput()\n" $out
                    ## error checking
                    odfi::common::println "while (entry < 0 || entry >= [$it depth]) \{" $out
                    odfi::common::printlnIndent
                    odfi::common::println "println(\"Specified entry does not exist for RamBlock [$it name] (size [$it depth]). Select Entry:\")" $out
                    odfi::common::println "entry = Menu.getUserInput()" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "\}\n" $out
                    odfi::common::println "println(\"Set value:\")" $out
                    odfi::common::println "val value = hexToLong(Menu.getUserInputString())" $out
                    odfi::common::println "Device.writeRegister(0,[getHexAddress $it]+(8*entry),value)" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "\}\n" $out
                    odfi::common::printlnOutdent

                    odfi::common::println "\}\n" $out
                
                ## RegisterFile/Group
                } elseif {[$it isa osys::rfg::Group]} {
                    if {[needsHexConversions $it]} {
                        odfi::common::println "class [getFullName $it]_menu extends MenuTrait with HexConversions \{\n" $out
                    } else {
                        odfi::common::println "class [getFullName $it]_menu extends MenuTrait \{\n" $out
                    }
                    odfi::common::printlnIndent
                    odfi::common::println "registerMenuHeader(\"[$it name] Menu\")\n" $out
                    
                    ## instantiate components within top registerFile
                    $it onEachComponent {
                        if {[$it isa osys::rfg::Register]} {
                            odfi::common::println "registerMenuItem(() => s\"Write [$it name] (current $\{Device.readRegister(0,[getHexAddress $it])\})\") \{" $out

                            odfi::common::printlnIndent
                            odfi::common::println "println(\"Enter new value:\")" $out
                            odfi::common::println "val value = hexToLong(Menu.getUserInputString())" $out
                            odfi::common::println "Device.writeRegister(0,[getHexAddress $it],value)" $out
                            odfi::common::printlnOutdent

                            odfi::common::println "\}\n" $out

                        } elseif {[$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Group]} {
                            odfi::common::println "registerMenuItem(\"[$it name]\") \{" $out

                            odfi::common::printlnIndent
                            odfi::common::println "(new [getFullName $it]_menu).runMenu()" $out
                            odfi::common::printlnOutdent

                            odfi::common::println "\}\n" $out
                        }
                    }
                    odfi::common::printlnOutdent
                    odfi::common::println "\}\n" $out
                }

                return true
            }

            flush $out
            set res [read $out]
            close $out
            return $res
        
        }
    }
}
