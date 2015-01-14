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
package require Itcl 3.4
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

        public method copyDependenciesTo destination {

            odfi::common::copy $osys::rfg::generator::htmlbrowser::location $destination/bs/ *.css
            odfi::common::copy $osys::rfg::generator::htmlbrowser::location $destination/bs/ *.js
            odfi::common::copy $osys::rfg::generator::htmlbrowser::location/fonts $destination/fonts *

        }

        public method produce destinationPath {
            
            file mkdir $destinationPath
            ::puts "Htmlbrowser processing $registerFile > ${destinationPath}[$registerFile name].html"
            set html [odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/htmlbrowser_template.html]
            odfi::files::writeToFile ${destinationPath}[$registerFile name].html $html
            copyDependenciesTo $destinationPath

        }

#           public method produce args {
#   
#   
#               ## Create Special Stream 
#               #set out [odfi::common::newStringChannel]
#   
#               odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/htmlbrowser_template.html
#   
#           }


    }

}
