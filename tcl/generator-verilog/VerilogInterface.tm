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

package provide osys::verilogInterface 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::verilogInterface {
    
    itcl::class ModuleBlackbox {
        
        odfi::common::classField private in_out_list {}

        constructor {cClosure} {
            odfi::closures::doClosure $cClosure
           ## return [join in_out_list ","]
        }
        
        public method input {name type width {offset 0}} {
            ::if {$width == 1} {
                lappend in_out_list "input $type $name"
            } else {
                lappend in_out_list "input $type\[[expr $width -1+$offset]:$offset\] $name"
            }
        }

        public method output {name type width {offset 0}} {
            ::if {$width == 1} {
                lappend in_out_list "output $type $name"
            } else {
                lappend in_out_list "output $type\[[expr $width -1+$offset]:$offset\] $name"
            }

        }

        public method inout {name type width {offset 0}} {
            ::if {$width == 1} {
                lappend in_out_list "inout $type $name"
            } else {
                lappend in_out_list "inout $type\[[expr $width -1+$offset]:$offset\] $name"
            }

        }

        public method getResolve {} {
            return [join $in_out_list ",\n    "]
        }

    }

    itcl::class ModuleBody {

    }

    itcl::class Module {
        
        odfi::common::classField private resolve [odfi::common::newStringChannel]

        constructor {cName cClosure1 cClosure2} {
            ## Module Blackbox definitions start
            odfi::common::println "module $cName (" $resolve
            odfi::common::printlnIndent
            set moduleBlackbox [::new [namespace parent]::ModuleBlackbox ::{$cName}_Blackbox $cClosure1]
            odfi::common::println [$moduleBlackbox getResolve] $resolve
            odfi::common::printlnOutdent
            odfi::common::println ");" $resolve
            ## Module Blackbox definitions end
            ## Module body start
            ## construct ModuleBody
            ## Module body end
            ::puts [getResolve]
        }

        public method getResolve {} {
            flush $resolve
            return [read $resolve]
        }
    }
    
    proc module {cName cClosure1 keyword cClosure2} {
        if {$keyword == "body"} {
            return [::new Module ::$cName $cName $cClosure1 $cClosure2]
        } else {
            error "No body defined!"
        }
    }
}
