
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

proc attributeFunction {fname} {

    set attributeName [string trimleft $fname ::]

    ## Category 
    ##  1. Namespace of attributeFunction call location without leading ::
    ##  2. Add :: to name
    #################
    set category [string trimleft [uplevel namespace current] ::]

    set attributeName ${category}::$attributeName

    set res "proc $fname args {
        uplevel 1 addAttribute $attributeName \$args 
    }"
    uplevel 1 $res 

}  

proc attributeGroup {fname} {
    set res "proc $fname args {
        uplevel 1 attributes [string trimleft $fname ::] \$args
    }"
    uplevel 1 $res
}

