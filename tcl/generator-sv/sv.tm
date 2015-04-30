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

        public method getFullName instance {
            if {[$instance isa osys::rfg::RamBlock]} {
                return "ram_[string tolower [[getEnclosingRF $instance] name]_[$instance name]]"
            } elseif {[$instance isa osys::rfg::Register]} {
                return "reg_[string tolower [[getEnclosingRF $instance] name]_[$instance name]]"
            }
        }

        public method ld  x {
            return [expr {int(ceil(log($x)/[expr log(2)]))}]
        }

        public method produce_RegisterFile args {
            set out [odfi::common::newStringChannel]
        
            $registerFile walkDepthFirst {
                if {[$it isa osys::rfg::RamBlock]} {
                    odfi::common::println "class [getFullName $it] extends cag_rgm_ramblock #(.WIDTH([$it width]), .ADDR_SIZE([ld [$it depth]]));\n" $out
                    odfi::common::println "\t`uvm_object_utils([getFullName $it])\n" $out
                    odfi::common::println "\tfunction new(string name=\"[getFullName $it]\");" $out
                    odfi::common::println "\t\tsuper.new(name);" $out
                    odfi::common::println "\t\tthis.name = name;" $out
                    odfi::common::println "\t\tset_address('h[format %x [$it getAttributeValue software.osys::rfg::absolute_address]]);" $out
                    odfi::common::println "\tendfunction : new\n" $out
                    odfi::common::println "endclass : [getFullName $it]\n" $out

			    } elseif {[$it isa osys::rfg::Register]} {
                    odfi::common::println "class [getFullName $it] extends cag_rgm_register;\n" $out
                    odfi::common::println "\ttypedef struct packed {" $out
                    $it onEachField {
                        odfi::common::println "\t\tbit \[[expr {[$it width] - 1}]:0\] [$it name];" $out
                    }
                    odfi::common::println "\t} pkd_flds_s;\n" $out
                    odfi::common::println "\t`cag_rgm_register_fields(pkd_flds_s)\n" $out
                    odfi::common::println "\t`uvm_object_utils_begin([getFullName $it])" $out
                    odfi::common::println "\t\t`uvm_field_int(fields,UVM_ALL_ON)" $out
                    odfi::common::println "\t`uvm_object_utils_end\n" $out
                    odfi::common::println "\tfunction new(string name=\"[getFullName $it]\");" $out
                    odfi::common::println "\t\tsuper.new(name);" $out
                    odfi::common::println "\t\tthis.name = name;" $out
                    odfi::common::println "\t\tset_address('h[format %x [$it getAttributeValue software.osys::rfg::absolute_address]]);" $out
                    odfi::common::println "\tendfunction : new\n" $out
                    odfi::common::println "endclass : [getFullName $it]" $out
#                    odfi::common::println "reg_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] {" $out
                    $it onEachField {
#                    odfi::common::println "    [$it name] : uint(bits:[$it width]) : [$it reset];" $out
                    }
#                    odfi::common::println "};" $out
#                    odfi::common::println "" $out

                } elseif {[$it isa osys::rfg::Group]} {
                    if {[$it isa osys::rfg::RegisterFile]} {
#                        odfi::common::println "reg_file_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]];" $out
#                    odfi::common::println "" $out

                    } else {
#                        odfi::common::println "group_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it];" $out
#                        odfi::common::println "" $out
                    }
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
