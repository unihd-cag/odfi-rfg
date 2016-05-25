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

package provide osys::rfg::generator::sv 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::generator::sv {

    itcl::class Sv {

        public variable registerFile 

        constructor cRegisterFile {
            set registerFile $cRegisterFile
        }

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            ::puts "svGenerator processing $registerFile > ${destinationPath}[$registerFile name].sv"
            set res [produce_RegisterFile ]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].sv $res
        }

        public method getEnclosingRF {instance} {
            if {[[$instance parent] isa osys::rfg::RegisterFile]} {
                return [$instance parent]
            } else {
                return [getEnclosingRF [$instance parent]]
            }
        }

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

        public method getFullName instance {
            if {[$instance isa osys::rfg::RamBlock]} {
                return "ram_[[getEnclosingRF $instance] name]_[getGroupsName $instance][$instance name]_c"
            } elseif {[$instance isa osys::rfg::Register]} {
                return "reg_[[getEnclosingRF $instance] name]_[getGroupsName $instance][$instance name]_c"
            } elseif {[$instance isa osys::rfg::Group]} {
                if {[$instance isa osys::rfg::RegisterFile]} {
                    return "rf_[$instance name]_c"
                } else {
                    return "grp_[[getEnclosingRF $instance] name]_[getGroupsName $instance][$instance name]_c"
                }
            }
        }

        public method ld  x {
            return [expr {int(ceil(log($x)/[expr log(2)]))}]
        }

        public method produce_RegisterFile args {
            set out [odfi::common::newStringChannel]
            set comp [list]
            set comp_name [list]
            $registerFile walkDepthFirst {
                lappend comp $it
                lappend comp_name [getFullName $it]
                return true
            }

            foreach item $comp_name {
                #-- while there are dublicates in comp
                while {[llength [lsearch -all $comp_name $item]] > 1} {
                    #-- delete the first dublicate
                    set index [lsearch $comp_name $item]
                    set comp [lreplace $comp $index $index]
                    set comp_name [lreplace $comp_name $index $index]
                }
            }
            #-- reverse list so classes are declared before use
            set comp [lreverse $comp]

            foreach item $comp {
                if {[$item isa osys::rfg::RamBlock]} {
                    odfi::common::println "class [getFullName $item] extends cag_rgm_ramblock #(.WIDTH([$item width]), .ADDR_SIZE([ld [$item depth]]));\n" $out
                    odfi::common::printlnIndent
                    odfi::common::println "`uvm_component_utils([getFullName $item])\n" $out
                    odfi::common::println "function new(string name=\"[getFullName $item]\", uvm_component parent);" $out
                    odfi::common::printlnIndent
                    odfi::common::println "super.new(name, parent);" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "endfunction : new\n" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "endclass : [getFullName $item]\n" $out

	        } elseif {[$item isa osys::rfg::Register]} {
                    odfi::common::println "class [getFullName $item] extends cag_rgm_register;\n" $out
                    odfi::common::printlnIndent
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "bit \[[expr {[$it width] - 1}]:0\] [$it name]_;" $out
                        }
                    }
                    odfi::common::println "" $out
                    odfi::common::println "`uvm_component_utils_begin([getFullName $item])" $out
                    odfi::common::printlnIndent
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "`uvm_field_int([$it name]_,UVM_ALL_ON | UVM_NOPACK)" $out
                        }
                    }
                    odfi::common::printlnOutdent
                    odfi::common::println "`uvm_component_utils_end\n" $out
                    odfi::common::println "function new(string name=\"[getFullName $item]\", uvm_component parent);" $out
                    odfi::common::printlnIndent
                    odfi::common::println "super.new(name, parent);" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "endfunction : new\n" $out
                    odfi::common::println "function void do_pack(uvm_packer packer);" $out
                    odfi::common::printlnIndent
                    odfi::common::println "super.do_pack(packer);" $out
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "packer.pack_field([$it name]_,[$it width]);" $out
                        } else {
                            if {[$it width] != 0} {
                                odfi::common::println "packer.pack_field([$it width]'b0,[$it width]);" $out
                            }
                        }
                    }
                    odfi::common::printlnOutdent
                    odfi::common::println "endfunction : do_pack\n" $out
                    odfi::common::println "function void do_unpack(uvm_packer packer);" $out
                    odfi::common::printlnIndent
                    odfi::common::println "super.do_unpack(packer);" $out
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "[$it name]_ = packer.unpack_field([$it width]);" $out
                        } else {
                            if {[$it width] != 0} {
                                odfi::common::println "void'(packer.unpack_field([$it width]));" $out
                            }
                        }
                    }
                    odfi::common::printlnOutdent
                    odfi::common::println "endfunction : do_unpack\n" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "endclass : [getFullName $item]\n" $out
                } elseif {[$item isa osys::rfg::Group]} {
                    if {[$item isa osys::rfg::RegisterFile]} {
                        odfi::common::println "class [getFullName $item] extends cag_rgm_register_file;\n" $out
                    } else {
                        odfi::common::println "class [getFullName $item] extends cag_rgm_container;\n" $out
                    }
                    odfi::common::printlnIndent
                    $item onEachComponent {
                        if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Register]} {
                            odfi::common::println "rand [getFullName $it] [$it name];" $out
                        }
                    }
                    odfi::common::println "" $out
                    odfi::common::println "`uvm_component_utils([getFullName $item])\n" $out
                    odfi::common::println "function new(string name=\"[getFullName $item]\", uvm_component parent);" $out
                    odfi::common::printlnIndent
                    odfi::common::println "super.new(name, parent);" $out
                    if {[$item isa osys::rfg::RegisterFile]} {
                    } else {
                    }
                    $item onEachComponent {
                        if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Register]} {
                            odfi::common::println "[$it name] = [getFullName $it]::type_id::create(\"[$it name]\", this);" $out
                            if {[$it isa osys::rfg::Group]} {
                                if {[$it isa osys::rfg::RegisterFile]} {
                                    odfi::common::println "[$it name].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                                } else {
                                    odfi::common::println "set_relative_address('h0);" $out
                                }
                            } else {
                                if { [$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Register]} {
                                    odfi::common::println "[$it name].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                                }
                            }
                            if {[$it isa osys::rfg::RamBlock]} {
                                odfi::common::println "add_ramblock([$it name]);" $out
                            } elseif {[$it isa osys::rfg::Register]} {
                                odfi::common::println "add_register([$it name]);" $out
                            } elseif {[$it isa osys::rfg::Group]} {
                                if {[$it isa osys::rfg::RegisterFile]} {
                                    odfi::common::println "add_register_file([$it name]);" $out
                                } else {
                                    odfi::common::println "add_group([$it name]);" $out
                                }
                            }
                        }
                    }
                    odfi::common::printlnOutdent
                    odfi::common::println "endfunction : new\n" $out
                    odfi::common::printlnOutdent
                    odfi::common::println "endclass : [getFullName $item]\n" $out
                }
            }

            if {[$registerFile isa osys::rfg::RegisterFile]} {
                odfi::common::println "class [getFullName $registerFile] extends cag_rgm_register_file;\n" $out
                odfi::common::printlnIndent
                $registerFile onEachComponent {
                    ## TODO concept for groups
                    if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Register]} {
                        odfi::common::println "rand [getFullName $it] [$it name];" $out
                    }
                }
                    odfi::common::println "" $out
                odfi::common::println "`uvm_component_utils([getFullName $registerFile])\n" $out
                odfi::common::println "function new(string name=\"[getFullName $registerFile]\", uvm_component parent);" $out
                odfi::common::printlnIndent
                odfi::common::println "super.new(name, parent);" $out
                odfi::common::println "set_relative_address('h[format %x [$registerFile getAttributeValue software.osys::rfg::relative_address]]);" $out
                $registerFile onEachComponent {
                     ## TODO concept for groups
                    if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::Register]} {
                        odfi::common::println "[$it name] = [getFullName $it]::type_id::create(\"[$it name]\", this);" $out
                  
                        if {[$it isa osys::rfg::Group]} {
                            if {[$it isa osys::rfg::RegisterFile]} {
                                odfi::common::println "[$it name].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                            } else {
			    	## Check this Groups would now have relative addresses but they are just helpers for hierarchies
                                odfi::common::println "set_relative_address('h0);" $out
                            }
                        } else {
			    if {[$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
                        	odfi::common::println "[$it name].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
			    }
                        }
                        if {[$it isa osys::rfg::RamBlock]} {
                            odfi::common::println "add_ramblock([$it name]);" $out
                        } elseif {[$it isa osys::rfg::Register]} {
                            odfi::common::println "add_register([$it name]);" $out
                        } elseif {[$it isa osys::rfg::Group]} {
                            if {[$it isa osys::rfg::RegisterFile]} {
                                odfi::common::println "add_register_file([$it name]);" $out
                            } else {
                                odfi::common::println "add_group([$it name]);" $out
                            }
                       }
                   }
                }
                odfi::common::printlnOutdent
                odfi::common::println "endfunction : new\n" $out
                odfi::common::printlnOutdent
                odfi::common::println "endclass : [getFullName $registerFile]\n" $out
            }

            flush $out
            set res [read $out]
            close $out
            return $res
        
        }
    }
}
