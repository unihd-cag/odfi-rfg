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

package require odfi::common
package require odfi::files 1.0.0
package require odfi::list 2.0.0
source [file dirname [file normalize [info script]]]/VerilogInterface.tm
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

        public method produce {destinationPath {generator}} {
            set ::dP $destinationPath
            file mkdir $destinationPath
            set ::options $generator
            set registerfiles $registerFile
            set file_list [$registerFile getAttributeValue rfg.osys::rfg::file]
           	## Read and parse Verilog Template

            $registerFile walkDepthFirst {
                if {[$it isa osys::rfg::RegisterFile]} {
                    if {[lsearch $file_list [$it getAttributeValue rfg.osys::rfg::file]] == -1} {
                        lappend file_list [$it getAttributeValue rfg.osys::rfg::file]
                        lappend registerfiles $it
                        ::puts "This is the file name:"
                        ::puts [$it getAttributeValue rfg.osys::rfg::file]
                    }
                }
                return true
            }
            
            foreach ::rf $registerfiles {
                ::puts "VerilogGenerator processing: $::rf > ${destinationPath}[$::rf name].v"
                namespace eval :: {
                    catch {source ${::osys::rfg::generator::verilog::location}/registerfile_template.tcl} result
                    set name [lindex [split [file tail [$rf getAttributeValue rfg.osys::rfg::file]] "."] -1]
                    ::puts $name
                    ## Something is wrong here !!! ToDo`
                    $result generate ${dP}${name}.v
                }
            }

        }

    }

}
