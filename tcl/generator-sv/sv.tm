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
                    odfi::common::println "\t`uvm_object_utils([getFullName $item])\n" $out
                    odfi::common::println "\tfunction new(string name=\"[getFullName $item]\");" $out
                    odfi::common::println "\t\tsuper.new(name);" $out
                    odfi::common::println "\t\tthis.name = name;" $out
                    odfi::common::println "\tendfunction : new\n" $out
                    odfi::common::println "endclass : [getFullName $item]\n" $out

			    } elseif {[$item isa osys::rfg::Register]} {
                    odfi::common::println "class [getFullName $item] extends cag_rgm_register;\n" $out
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "\t\tbit \[[expr {[$it width] - 1}]:0\] [$it name]_;" $out
                        }
                    }
                    odfi::common::println "\n\t`uvm_object_utils_begin([getFullName $item])" $out
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "\t\t`uvm_field_int([$it name]_,UVM_ALL_ON | UVM_NOPACK)" $out
                        }
                    }
                    odfi::common::println "\t`uvm_object_utils_end\n" $out
                    odfi::common::println "\tfunction new(string name=\"[getFullName $item]\");" $out
                    odfi::common::println "\t\tsuper.new(name);" $out
                    odfi::common::println "\t\tthis.name = name;" $out
                    odfi::common::println "\tendfunction : new\n" $out
                    odfi::common::println "\tfunction void do_pack(uvm_packer packer);" $out
                    odfi::common::println "\t\tsuper.do_pack(packer);" $out
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "\t\tpacker.pack_field([$it name]_,[$it width]);" $out
                        } else {
                            odfi::common::println "\t\tpacker.pack_field([$it width]'b0,[$it width]);" $out
                        }
                    }
                    odfi::common::println "\tendfunction : do_pack\n" $out
                    odfi::common::println "\tfunction void do_unpack(uvm_packer packer);" $out
                    odfi::common::println "\t\tsuper.do_unpack(packer);" $out
                    $item onEachField {
                        if {[$it name] != "Reserved"} {
                            odfi::common::println "\t\t[$it name]_ = packer.unpack_field([$it width]);" $out
                        } else {
                            odfi::common::println "\t\tvoid'(packer.unpack_field([$it width]));" $out
                        }
                    }
                    odfi::common::println "\tendfunction : do_unpack\n" $out
                    odfi::common::println "endclass : [getFullName $item]\n" $out
                } elseif {[$item isa osys::rfg::Group]} {
                    if {[$item isa osys::rfg::RegisterFile]} {
                        odfi::common::println "class [getFullName $item] extends cag_rgm_register_file;\n" $out
                    } else {
                        odfi::common::println "class [getFullName $item] extends cag_rgm_container;\n" $out
                    }
                    $item onEachComponent {
                        odfi::common::println "\trand [getFullName $it] [string tolower [$it name]];" $out
                    }
                    odfi::common::println "\n\t`uvm_object_utils([getFullName $item])\n" $out
                    odfi::common::println "\tfunction new(string name=\"[getFullName $item]\");" $out
                    odfi::common::println "\t\tsuper.new(name);" $out
                    odfi::common::println "\t\tthis.name = name;" $out
                    if {[$item isa osys::rfg::RegisterFile]} {
                    } else {
                    }
                    $item onEachComponent {
                        odfi::common::println "\t\t[string tolower [$it name]] = [getFullName $it]::type_id::create(\"[string tolower [$it name]]\");" $out
                        odfi::common::println "\t\t[string tolower [$it name]].set_parent(this);" $out
                        if {[$it isa osys::rfg::Group]} {
                            if {[$it isa osys::rfg::RegisterFile]} {
                                odfi::common::println "\t\t[string tolower [$it name]].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                            } else {
                                odfi::common::println "\t\tset_relative_address('h0);" $out
                            }
                        } else {
                            odfi::common::println "\t\t[string tolower [$it name]].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                        }
                        if {[$it isa osys::rfg::RamBlock]} {
                            odfi::common::println "\t\tadd_ramblock([string tolower [$it name]]);" $out
                        } elseif {[$it isa osys::rfg::Register]} {
                            odfi::common::println "\t\tadd_register([string tolower [$it name]]);" $out
                        } elseif {[$it isa osys::rfg::Group]} {
                            if {[$it isa osys::rfg::RegisterFile]} {
                                odfi::common::println "\t\tadd_register_file([string tolower [$it name]]);" $out
                            } else {
                                odfi::common::println "\t\tadd_group([string tolower [$it name]]);" $out
                            }
                        }
                    }
                    odfi::common::println "\tendfunction : new\n" $out
                    odfi::common::println "endclass : [getFullName $item]\n" $out
                }
            }

            if {[$registerFile isa osys::rfg::RegisterFile]} {
                odfi::common::println "class [getFullName $registerFile] extends cag_rgm_register_file;\n" $out
                $registerFile onEachComponent {
                    odfi::common::println "\trand [getFullName $it] [string tolower [$it name]];" $out
                }
                odfi::common::println "\n\t`uvm_object_utils([getFullName $registerFile])\n" $out
                odfi::common::println "\tfunction new(string name=\"[getFullName $registerFile]\");" $out
                odfi::common::println "\t\tsuper.new(name);" $out
                odfi::common::println "\t\tthis.name = name;" $out
                odfi::common::println "\t\tparent = null;" $out
                odfi::common::println "\t\tset_relative_address('h[format %x [$registerFile getAttributeValue software.osys::rfg::relative_address]]);" $out
                $registerFile onEachComponent {
                    odfi::common::println "\t\t[string tolower [$it name]] = [getFullName $it]::type_id::create(\"[string tolower [$it name]]\");" $out
                    odfi::common::println "\t\t[string tolower [$it name]].set_parent(this);" $out
                    if {[$it isa osys::rfg::Group]} {
                        if {[$it isa osys::rfg::RegisterFile]} {
                            odfi::common::println "\t\t[string tolower [$it name]].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                        } else {
                            odfi::common::println "\t\tset_relative_address('h0);" $out
                        }
                    } else {
                        odfi::common::println "\t\t[string tolower [$it name]].set_relative_address('h[format %x [$it getAttributeValue software.osys::rfg::relative_address]]);" $out
                    }
                    if {[$it isa osys::rfg::RamBlock]} {
                        odfi::common::println "\t\tadd_ramblock([string tolower [$it name]]);" $out
                    } elseif {[$it isa osys::rfg::Register]} {
                        odfi::common::println "\t\tadd_register([string tolower [$it name]]);" $out
                    } elseif {[$it isa osys::rfg::Group]} {
                        if {[$it isa osys::rfg::RegisterFile]} {
                            odfi::common::println "\t\tadd_register_file([string tolower [$it name]]);" $out
                        } else {
                            odfi::common::println "\t\tadd_group([string tolower [$it name]]);" $out
                        }
                    }
                }
                odfi::common::println "\tendfunction : new\n" $out
                odfi::common::println "endclass : [getFullName $registerFile]\n" $out
            }

            flush $out
            set res [read $out]
            close $out
            return $res
        
        }
    }
}
