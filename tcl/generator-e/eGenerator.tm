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

package provide osys::rfg::generator::egenerator 1.0.0
package require osys::rfg

package require odfi::common
package require odfi::list 2.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::generator::egenerator {

    itcl::class Egenerator {

        public variable registerFile 

        constructor cRegisterFile {
            set registerFile $cRegisterFile
        }

        public method getEnclosingRF {instance} {
            if {[[$instance parent] isa osys::rfg::RegisterFile]} {
                return [$instance parent]
            } else {
                return [getEnclosingRF [$instance parent]]
            }
        }

        public method getNextGroupsName {instance} {
            if {[[$instance parent] isa osys::rfg::Group]} {
                if {[[$instance parent] isa osys::rfg::RegisterFile]} {
                    return ""
                } else {
                    return "[getNextGroupsName [$instance parent]][[$instance parent] name]_"
                }
            } else {
                return [getNextGroupsName [$instance parent]]
            }
        }

        public method getGroupsName {instance} {
            if {[[$instance parent] isa osys::rfg::Group]} {
                if {[[$instance parent] isa osys::rfg::RegisterFile]} {
                    return ""
                } else {
                    return " [getNextGroupsName [$instance parent]][[$instance parent] name]"
                }
            } else {
                return [getGroupsName [$instance parent]]
            }
        }

        ## returns if a register file type was read previously
        public method isKnownType {regFileTypes item} {
            if {[$item isa osys::rfg::RegisterFile]} {
                ## was the register file read previously?
                if {[lsearch [$item getAttributeValue rfg.osys::rfg::file] $regFileTypes] == -1} {
                    puts "unknown rf"
                    return false
                } else {
                    puts "known rf"
                    return true
                }
            } else {
                ## was the entire  enclosing register file read previously
                if {[llength [lsearch -all $regFileTypes [[getEnclosingRF $item] getAttributeValue rfg.osys::rfg::file]]] > 1} {
                    puts "known item"
                    return true
                } else {
                    puts "unknown item"
                    return false
                }
            }
        }

        public method getRegFileType {regFile} {
            ##returns file name without extension
            return [lindex [split [file tail [$regFile getAttributeValue rfg.osys::rfg::file]] .] 0]
        }

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            ::puts "eGenerator processing $registerFile > ${destinationPath}[$registerFile name].e"
            set res [produce_RegisterFile ]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].e $res
        }

        public method produce_RegisterFile args {
            set out [odfi::common::newStringChannel]
            set regFileTypes [list]
        
            odfi::common::println "<'" $out
            odfi::common::println "reg_file_type [string toupper [getRegFileType $registerFile]];" $out
            odfi::common::println "" $out

            $registerFile walkDepthFirst {
                if {![isKnownType $regFileTypes $it]} {
                    if {[$it isa osys::rfg::RamBlock]} {
	    			    odfi::common::println "ram_def [string toupper [$it name]] [string toupper [getRegFileType [getEnclosingRF $it]]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] [$it width] [$it depth] {" $out
                        odfi::common::println "};" $out
                        odfi::common::println "" $out
			        } elseif {[$it isa osys::rfg::Register]} {
                        odfi::common::println "reg_def [string toupper [$it name]] [string toupper [getRegFileType [getEnclosingRF $it]]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] {" $out
                        $it onEachField {
                        odfi::common::println "    [$it name] : uint(bits:[$it width]) : [$it reset];" $out
                        }
                        odfi::common::println "};" $out
                        odfi::common::println "" $out
                    } elseif {[$it isa osys::rfg::Group]} {
                        if {[$it isa osys::rfg::RegisterFile]} {
puts [$it getAttributeValue rfg.osys::rfg::file]
                            odfi::common::println "reg_file_type [string toupper [getRegFileType $it]];" $out
                            odfi::common::println "" $out
                        } else {
                            odfi::common::println "group_def [string toupper [$it name]] [string toupper [getRegFileType [getEnclosingRF $it]]][getGroupsName $it];" $out
                            odfi::common::println "" $out
                        }
                    }
                }
                if {[$it isa osys::rfg::RegisterFile]} {
                    lappend regFileTypes [$it getAttributeValue rfg.osys::rfg::file]
                    odfi::common::println "reg_file_inst [$it name] [string toupper [getRegFileType $it]] [string toupper [getRegFileType [getEnclosingRF $it]]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]];" $out
                    odfi::common::println "" $out
                }
                return true
            }

            odfi::common::println "'>" $out

            flush $out
            set res [read $out]
            close $out
            return $res
        
        }
    }
}
