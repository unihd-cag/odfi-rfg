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

package provide osys::rfg::address::linear 1.0.0
package require odfi::scenegraph::svg 1.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::address::linear {

    osys::rfg::attributeFunction absolute_address_start
    osys::rfg::attributeFunction absolute_address_stop

    ## Calculate addresses and mark them on the objects
    ##  
    proc calculate rf {

        set current_address 0 

        $rf walkDepthFirst {

            ## Ignore groups 
            if {[$it isa osys::rfg::Group]} {
                return true
            }

            ## Mark
            $it attributes sw {
               
                osys::rfg::address::linear::absolute_address_start $current_address

            }

            ## Increment
            if {[$it isa osys::rfg::Register]} {
            
                incr current_address [expr $osys::rfg::registerSize/8]
            
            } elseif {[$it isa osys::rfg::RamBlock]} {

                 incr current_address [expr [$it depth] * $osys::rfg::registerSize/8]
            }

            return true

        }

    }

    proc svgToFile {rf file} {

        ## Create 
        odfi::scenegraph::svg::createSvg svg with {

            $rf walkDepthFirst {

                    ## Ignore groups 
                    if {[$it isa osys::rfg::Group]} {
                        return true
                    }

                    ## Name 
                    text "[$it name]" {

                    }

                    ## Box 
                    ## - Reg : Simple
                    ## - Ram : Multiple
                    if {[$it isa osys::rfg::Register]} {
                        rect {
                            width 200
                            height 20
                            fill lightgray
                        }
                    } elseif {[$it isa osys::rfg::RamBlock]} {
                        group {
                            repeat 4 {
                                rect {
                                    width 200
                                    height 5
                                    fill gray
                                }
                            }
                            layout column {
                                spacing 2
                            }
                        }
                    }
                    

                    ## Address
                    set addressText [format 0x%lx [$it getAttributeValue sw.osys::rfg::address::linear::absolute_address_start]]
                    text "$addressText" {

                    }

            }

            # grid 
            layout flowGrid {
                columns 3
                spacing 5
                alignHeight true
            }
            #layout column

        } 

        ## To String 
        odfi::files::writeToFile  $file [$svg toString]


    }


}
