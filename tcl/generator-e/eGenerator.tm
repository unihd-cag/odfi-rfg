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
    
        public method getEnclosingRF {instance} {}
        public method getNextGroupsName {instance} {}
        public method getGroupsName {instance} {}
        public method produceSwRfModel args {}
        public method produceHwTopFile args {}
        public method produceHwTb args {}

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            ::puts "eGenerator processing $registerFile > ${destinationPath}[$registerFile name].e"
            set res [produceSwRfModel ]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].e $res
            ::puts "eGenerator processing $registerFile > ${destinationPath}top.e"
            set res [produceHwTopFile ]
            odfi::files::writeToFile ${destinationPath}top.e $res
            ::puts "eGenerator processing $registerFile > ${destinationPath}tb_top.sv"
            set res [produceHwTb ]
            odfi::files::writeToFile ${destinationPath}tb_top.sv $res
        }
    }
    source [file dirname [file normalize [info script]]]/swRfModel.tm
    source [file dirname [file normalize [info script]]]/hwTopFile.tm
    source [file dirname [file normalize [info script]]]/hwTb.tm
}
