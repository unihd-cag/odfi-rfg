## RFG Register File Genertor
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

## Provides the generator API interface for OSYS Register File Generator

package provide osys::generator 1.0.0
package require osys::rfg 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::generator {
    
    variable registerFile ""

    itcl::class Generator {
     
        odfi::common::classField public name ""
        odfi::common::classField public destinationFile ""
        odfi::common::classField public gen ""

        constructor {cName cClosure} {
            name $cName
            ::puts $name
            odfi::closures::doClosure $cClosure
            generate 
        }

        public method generate {} {
            puts $destinationFile
            ## add the function to address the register file here.
            [osys::rfg::getGenerator $name $::osys::generator::registerFile] produce $destinationFile          
        }   

    }
    
    ## Main factory
    proc generator {name closure} {
        return [::new Generator ::$name $name $closure]
    }
    
    ## Helper function for easy RFG read in
    proc readRF {inputFile} {
        set ::osys::rfg::inputFile $inputFile
        catch {namespace eval ::osys::rfg {
                source $inputFile
            }
        } ::osys::generator::registerFile
        ::puts "RegisterFile: $::osys::generator::registerFile"
    }
    
}
