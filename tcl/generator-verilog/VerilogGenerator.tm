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

package provide osys::rfg::generator::verilog 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::files 1.0.0
package require odfi::list 2.0.0

namespace eval osys::rfg::generator::verilog {

    variable location [file dirname [file normalize [info script]]]
	
	itcl::class Verilog {
		
		public variable registerFile 

		constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

        public method produce destinationPath {
            
            file mkdir $destinationPath

            set registerfiles $registerFile
           	## Read and parse Verilog Template

            $registerFile walkDepthFirst {
                if {[$it isa osys::rfg::RegisterFile]} {
                    lappend registerfiles $it
                }
                return true
            }
            
            foreach rf $registerfiles {
                set registerFile $rf
                if {[$registerFile parent] == "" || [$registerFile hasAttribute hardware.osys::rfg::external]} {
                    ::puts "VerilogGenerator processing: $rf > ${destinationPath}[$registerFile name].v"
                    
                    set verilog [odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::verilog::location/registerfile_template.v.tcl]
                    odfi::files::writeToFile ${destinationPath}[$registerFile name].v $verilog
                }
            }

        }

    }

}
