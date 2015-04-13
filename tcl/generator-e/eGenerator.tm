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
package require Itcl 3.4
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
                return [getEnclosingRF {[$instance parent]}]
            }
        }

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            ::puts "eGenerator processing ${destinationPath}[$registerFile name].e"
            set res [produce_RegisterFile ]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].e $res
        }

        public method produce_RegisterFile args {
            set out [odfi::common::newStringChannel]
        
            odfi::common::println "<'" $out
            odfi::common::println "reg_file_def [string toupper [$registerFile name]];" $out
            odfi::common::println "" $out

            $registerFile walkDepthFirst {
                if {[$it isa osys::rfg::RamBlock]} {
	    			odfi::common::println "ram_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] [$it width] [$it depth] {" $out
                    odfi::common::println "};" $out
                    odfi::common::println "" $out
			    } elseif {[$it isa osys::rfg::Register]} {
                    odfi::common::println "reg_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] {" $out
                    $it onEachField {
                    odfi::common::println "    [$it name] : uint(bits:[$it width]) : [$it reset];" $out
                    }
                    odfi::common::println "};" $out
                    odfi::common::println "" $out
                } elseif {[$it isa osys::rfg::RegisterFile]} {
                    odfi::common::println "reg_file_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]];" $out
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
