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
