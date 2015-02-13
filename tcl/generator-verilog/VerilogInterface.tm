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

    itcl::class Common {

        odfi::common::classField private resolve [odfi::common::newStringChannel]
        
        public method getResolve {} {
            flush $resolve
            return [read $resolve]
        }

    }
    
    itcl::class ModuleInterface  {
        
        odfi::common::classField private in_out_list {}

        constructor {cClosure} {
            odfi::closures::doClosure $cClosure
        }
        
        public method input {name type {width 1} {offset 0}} {
            ::if {[expr $width] == 1} {
                lappend in_out_list "input $type $name"
            } else {
                lappend in_out_list "input $type\[[expr $width -1+$offset]:$offset\] $name"
            }
        }

        public method output {name type {width 1} {offset 0}} {
            ::if {[expr $width] == 1} {
                lappend in_out_list "output $type $name"
            } else {
                lappend in_out_list "output $type\[[expr $width -1+$offset]:$offset\] $name"
            }

        }

        public method inout {name type {width 1} {offset 0}} {
            ::if {[expr $width] == 1} {
                lappend in_out_list "inout $type $name"
            } else {
                lappend in_out_list "inout $type\[[expr $width -1+$offset]:$offset\] $name"
            }

        }

        public method getResolve {} {
            return [join $in_out_list ",\n    "]
        }

    }
    
    itcl::class Always {
        
        inherit Common

        constructor {cClosure} {
            odfi::closures::doClosure $cClosure
        }

        public method if {condition body} {
            odfi::common::println "if($condition)" $resolve
            odfi::common::println "begin" $resolve
            odfi::common::printlnIndent
            odfi::closures::doClosure $body
            odfi::common::printlnOutdent
            odfi::common::println "end" $resolve
        }

        public method else {body} {
            odfi::common::println "else" $resolve
            odfi::common::println "begin" $resolve
            odfi::common::printlnIndent
            odff::closures::doClosure $body
            odfi::common::printlnOutdent
            odfi::common::println "end" $resolve
        }

        public method case {selector closure} {
            odfi::common::println "casex($selector)"
            odfi::common::printlnIndent
            set case_object [::new [namespace parent]::Case #auto $closure]
            odfi::common::println [case_object getResolve] $resolve
            odfi::common::printlnOutdent
            odfi::common::println "endcase"
        }

    }
    
    itcl::class Case {
        
        inherit Always

        constructor {cClosure} {
            odfi::closures::doClosure $cClosure
        }
        
        public method case_select {condition body} {
            odfi::common::println "$condition:" $resolve
            odfi::common::println "begin" $resolve
            odfi::common::printlnIndent
            odfi::closures::doClosure $cClosure
            odfi::common::printlnOutdent
            odfi::common::println "end" $resolve
        }

    }

    itcl::class ModuleBody {
        
        inherit Common

        constructor {cClosure} {
            odfi::closures::doClosure $cClosure
        }

        public method assign {$lvalue $rvalue} {
            odfi::common::println "assign $lvalue = $rvalue;" $resolve
        }

        public method reg {name width {offset 0}} {
            odfi::common::println "reg\[[expr $width-1+$offset]:$offset\] $name;" $resolve
        }

        public method wire {name width {offset 0}} {
            odfi::common::println "wire\[[expr $width-1+$offset]:$offset\] $name;" $resolve
        }

        public method logic {name widht {offset 0}} {
            odfi::common::println "logic\[[expr $width-1+$offset]:$offset\] $name;" $resolve
        }

        public method always {condition closure} {
            odfi::common::println "always" $resolve
            odfi::common::println "begin" $resolve
            odfi::common::printlnIndent
            ## Create always object
            set always_object [::new [namespace parent]::Always #auto $closure]
            odfi::common::println [always_object getResolve] $resolve
            odfi::common::printlnOutdent
            odfi::common::println "end"
        }
    }

    itcl::class Module {
        
        inherit Common

        constructor {cName cClosure1 cClosure2} {
            ## Module Blackbox definitions start
            odfi::common::println "module $cName (" $resolve
            odfi::common::printlnIndent
            set module_interface [::new [namespace parent]::ModuleInterface ::${cName}_Interface $cClosure1]
            odfi::common::println [$module_interface getResolve] $resolve
            odfi::common::printlnOutdent
            odfi::common::println ");" $resolve
            ## Module Blackbox definitions end
            ## Module body start
            odfi::common::printlnIndent
            set module_body [::new [namespace parent]::ModuleBody ::${cName}_Body $cClosure2]
            odfi::common::println [$module_body getResolve] $resolve
            odfi::common::printlnOutdent
            ## Module body end
            ::puts [getResolve]
        }

    }
    
    proc module {cName cClosure1 keyword cClosure2} {
        ::if {$keyword == "body"} {
            return [::new Module ::${cName}_Module $cName $cClosure1 $cClosure2]
        } else {
            error "No body defined!
        }
    }
}
