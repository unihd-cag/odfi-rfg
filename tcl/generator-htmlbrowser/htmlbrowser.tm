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

package provide osys::rfg::generator::htmlbrowser 1.0.0
package require osys::rfg

package require odfi::common
package require odfi::files
package require odfi::list 2.0.0

#package require odfi::ewww::webdata 1.0.0


namespace eval osys::rfg::generator::htmlbrowser {

    variable location [file dirname [file normalize [info script]]]

    itcl::class Htmlbrowser {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

        ## returns a string composed of the name of the item and the names of its parents up to the top register file seperated by "seperator"
        public method getAbsoluteName_m {item {seperator " "}} {
            set result {}
            if {[string compare [$item parent] ""]} {
                set current [$item parent]
                set parents {}
                while {[string compare $current ""]} {
                    lappend parents $current
                    set current [$current parent]
                }
                foreach p $parents {
                    set result "[$p name]$seperator$result"
                }
            }
            return "$result[$item name]"
        }

        public method copyDependenciesTo destination {

            odfi::common::copy $osys::rfg::generator::htmlbrowser::location/css $destination/css *.css
            odfi::common::copy $osys::rfg::generator::htmlbrowser::location/js $destination/js *.js
            odfi::common::copy $osys::rfg::generator::htmlbrowser::location/fonts $destination/fonts *

        }

        public method produce {destinationPath {generator ""}} {
            file mkdir $destinationPath
            file mkdir [file join $destinationPath html]
            file mkdir [file join $destinationPath js]
            ::puts "Htmlbrowser processing $registerFile > [file join ${destinationPath} [$registerFile name].html]"
            set html [odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/htmlbrowser_template.tcl $registerFile]
            odfi::files::writeToFile [file join ${destinationPath} [$registerFile name].html] $html
            $registerFile walkDepthFirst {
                ::puts "Htmlbrowser processing $registerFile > [file join [file join ${destinationPath} html] [getAbsoluteName_m $it _].html]"
                set html [odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/htmlbrowser_template.tcl $it]
                odfi::files::writeToFile [file join [file join ${destinationPath} html] [getAbsoluteName_m $it _].html] $html
                return true
            }
            ::puts "Htmlbrowser processing $registerFile > [file join [file join ${destinationPath} js] user_defined.js]"
            set js [odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/js_template.tcl $registerFile]
            odfi::files::writeToFile [file join [file join ${destinationPath} js] user_defined.js] $js
            copyDependenciesTo $destinationPath
        }
    }
}
