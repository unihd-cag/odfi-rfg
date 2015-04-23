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

package provide osys::rfg::address 1.0.0
package require odfi::files 1.0.0

proc ld x {
    expr {wide(ceil(log($x)/[expr log(2)]))}
}

namespace eval osys::rfg::address {
    
    set RF_List {}

    proc calculate rf {
        lappend RF_List $rf
        ## Setting the size of the primitives (Register and RamBlocks)
        ## and creating a RegisterFile list
        $rf walkDepthFirst {
            
            if {[$it isa osys::rfg::RegisterFile]} {
                lappend RF_List $it
            }

            if {[$it isa osys::rfg::Register]} {
                $it attributes software {
                    size [expr [$rf register_size]/8]
                }
            }

            if {[$it isa osys::rfg::RamBlock]} {
                $it attributes software {
                    size [expr [$it depth]*[$rf register_size]/8]
                }
            }
            return true
        }


        $rf walkDepthFirst {
            return true
        }

        ## Walkin through the RF list in reverse to first set the size and relative address
        ## for the rfs with only primitives
        foreach regfile [lreverse $RF_List] {
            set relative_address 0
            set size 0
            set auto_align [$rf register_size]
            $regfile walkDepthFirst {
                if {[$it isa osys::rfg::Register]} {
                    set relative_address [expr wide(ceil(double($relative_address)/double($auto_align)))*$auto_align]
                    $it attributes software {
                        relative_address $relative_address
                    }
                    set auto_align [$it getAttributeValue software.osys::rfg::size]
                    set size [expr $relative_address + [$it getAttributeValue software.osys::rfg::size]]
                    incr relative_address [$it getAttributeValue software.osys::rfg::size]
                }

                if {[$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::RegisterFile]} {
                    if {$auto_align < [$it getAttributeValue software.osys::rfg::size]} {
                        set auto_align [$it getAttributeValue software.osys::rfg::size]
                    }
                    set relative_address [expr wide(ceil(double($relative_address)/double($auto_align)))*$auto_align]
                    $it attributes software {
                        relative_address $relative_address
                    }
                    set auto_align [$it getAttributeValue software.osys::rfg::size]
                    set size [expr $relative_address + [$it getAttributeValue software.osys::rfg::size]]
                    incr relative_address [$it getAttributeValue software.osys::rfg::size]
                }

                if {[$it isa osys::rfg::RegisterFile]} {
                    return false
                }
                return true
            }
            $regfile attributes software {
                size [expr 2**[ld $size]]
            }
        }
        ::puts "$rf Rel: [$rf getAttributeValue software.osys::rfg::relative_address] Size: [$rf getAttributeValue software.osys::rfg::size]"
        $rf walkDepthFirst {
            ::puts "$it Rel: [$it getAttributeValue software.osys::rfg::relative_address]  Size: [$it getAttributeValue software.osys::rfg::size]"
            return true
        }


    }

}
