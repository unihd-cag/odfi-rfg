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

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            ::puts "scalamenu Generator processing $registerFile > ${destinationPath}[$registerFile name].scala"
            set res [produce_RegisterFile ]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].scala $res
        }


        public method produce_RegisterFile args {
            set out [odfi::common::newStringChannel]

            #package declaration
            odfi::common::println "package com.extoll.rfmenu\n" $out

            #imports
            odfi::common::println "import com.extoll.utils.HexConversions"         $out
            odfi::common::println "import com.extoll.utils.menu.{Menu, MenuTrait}" $out
            odfi::common::println "import uni.hd.cag.osys.rfg.rf.device.Device\n"  $out

            flush $out
            set res [read $out]
            close $out
            return $res
        
        }
    }
}
