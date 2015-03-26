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

package provide osys::rfg::address::hierarchical 1.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::address::hierarchical {

    proc calculate rf {

        ##################################################
        ## Map -> All Regions to their physical contents (Stop at region boundary)
        ## Reduce -> Region content to relative addressing
        ## Distribute Addresses
        ##################################################


        set map {}
        set processingStack [list $rf]

        ## Map
        #############
        while {[llength $processingStack] > 0 } {

            ## Get current element
            ###############
            set current [lindex $processingStack 0]
            set processingStack [lreplace $processingStack 0 0]

            ## For non groups: Stop there, and add homomorphic entry to content map 
            if {![$current isa osys::rfg::Group]} {
                set map [odfi::list::arrayConcat $map $current $current]
                continue
            }

            ## For Groups: Walk The subtree and stop at regions
            ##########################

            set content {}
            $current walkWith {

                ## Add Element to map (ignore simple groups)
                if {![$it isa osys::rfg::Group] || [$it isa osys::rfg::Region]} {
                    set map [odfi::list::arrayConcat $map $current $it]
                }

                ## Stop At Region (Append region for next map process if it has children)
                if {[$it isa osys::rfg::Region]} {

                    lappend processingStack $it
                    return false
                } else {
                    return true
                }

            }


        }


        ## Debug
        puts "**** MAP Results ****" 
        #puts $map
        #foreach {key content} $map {
        #    puts "$key\t -> $content"
        #}

        odfi::list::arrayEach $map {
            puts "IM: $key\t -> $value"
        }


        ## Reduce Bottom UP The Map List for sizes 
        ## Key: Region , Value: content 
        ## Reduction: go through content, and increment the local address counter, including attributes for shifts and so on
        ############################

        set sizeMap {}


        proc sizeOf operator {
            
            odfi::closures::doClosure {

                if {[string is integer "$operator"]} {
                    return $operator
                } elseif {[$operator isa ::osys::rfg::Register]} {
                    ## ToDo: Fix this it is not always 8
                    return [expr $::osys::rfg::registerSize/8] 

                } elseif {[$operator isa ::osys::rfg::Region] && ![$operator isa ::osys::rfg::Group]} {

                    ## Non grouping regions must have size set
                    ## puts "NGR: [$operator size]"
                    if {[$operator hasAttribute software.osys::rfg::address_shift]} {
                        ## ToDo: Fix this it is not always 8
                        return [expr [$operator size]/8 << [$operator getAttributeValue software.osys::rfg::address_shift]]
                    
                    } else {
                    
                        ## ToDo: Fix this it is not always 8
                        return [expr [$operator size]/8]
                    
                    }

                } elseif {[$operator isa ::osys::rfg::Region]} {

                    ## Search in map (size already in bytes)
                    set size [odfi::list::arrayGet $sizeMap $operator]

                    return $size

                } else {

                    return 0
                }

            }

        }

        odfi::list::arrayEach [lreverse $map] {
            puts "-- Reducing: $key"

            set size [odfi::list::reduce $value {

                #puts "------ Left: $left Right: $right"
                #puts "----- $left ([sizeOf $left ]) + $right ([sizeOf $right])"

                switch -exact -- $right {
                    "{}" -
                    "" {
                        if {![string is integer $left]} {
                            if {[$left isa osys::rfg::Aligner]} {
                                set ls [$left aligment]
                            } else {
                                set ls [sizeOf $left]
                            }
                        } else {
                            set ls [sizeOf $left]
                        }
                  
                      $left attributes software {
                        ::size  $ls
                      }
                      return $ls
                    }
                    default {

                        ## Right Element size
                        if {[$right isa osys::rfg::Aligner]} {
                            set rightSize [expr int([sizeOf $left]/[$right aligment]+1)*[$right aligment]]
                            ::puts "Aligner found..."
                        } else {
                            set rightSize [sizeOf $right]
                        }
                        $right attributes software {
                            ::size  $rightSize
                        }
                        
                        ## Left size 
                         if {![string is integer $left]} {
                            if {[$left isa osys::rfg::Aligner]} {
                                set ls [$left aligment]
                            } else {
                                set ls [sizeOf $left]
                            }
                        } else {
                            set ls [sizeOf $left]
                        }
                      
                        if {![string is integer $left]} {
                            $left attributes software {
                                ::size  $ls
                            }
                        }
                        

                        ##return [expr [sizeOf $left] + $rightSize ]
                        return [expr $ls + $rightSize]
                    }
                }

            }]

            ## Save size to map and set on key 
            $key attributes software {
                ::size   $size
            }
            #$key size $size 
            set sizeMap  [odfi::list::arrayConcat $sizeMap $key $size]

        }


        odfi::list::arrayEach $sizeMap {
            puts "S: $key\t -> $value"
        }


        ## Distribute
        ## Go again top down, and assign addresses 
        ###################

        puts "--------- Distribute Abs -----------------------------------------"
        
        ## Wit hMyles
        ###################
        ## Go Map top down 
        ######################
        ::puts "Debug $map"
        odfi::list::arrayEach $map {
            
            puts "Address Distribution on : $key"
            set start_address 0 
            set ad 0
            set cumulated 0 

            if {[$key hasAttribute software.osys::rfg::absolute_address]} {
                set start_address [$key getAttributeValue software.osys::rfg::absolute_address]
                set ad $start_address
            } 

            $key attributes software {
                ::absolute_address $start_address
            }

            set baseAddress $start_address
            set currentAddress 0
            set blockAddress 0
            foreach it $value {

                if {$it==$key} {
                    continue
                }
                
                ## Get Size of block, rounded up to next power of two size
                set itSize [sizeOf $it]
                if {$itSize == 0} {
                
                    if {$currentAddress == 0} {
                        set blockAddress [$it aligment]
                    } else {
                        set blockAddress [expr int($currentAddress/[$it aligment]+1)*[$it aligment]]
                    }
                    set currentAddress $blockAddress
                
                } else {
                
                    set num_addr_bits [expr int(ceil(log($itSize)/log(2)))]
                    set blockSize [expr 2**$num_addr_bits] 
                    ## The address of current element is:
                    ##   - The current address + the size of the block 
                    set blockAddress [expr (($currentAddress+$blockSize-1)/$blockSize)*$blockSize]
                    set currentAddress [expr $blockAddress+$blockSize]
                
                }

                #puts "[$it name] Block address [format %0-20b $blockAddress], bs=$$blockSize Current Address = $currentAddress, bloc ksize -1:  [format %0-20b [expr $blockSize-1]]"

                ## Address assign 
                ##set bla $it
                $it attributes software {
                    ::relative_address $blockAddress
                    ::absolute_address [expr $baseAddress | $blockAddress]
                }
                ## The next current address is the block address + the size of this block
                ## set currentAddress [expr $blockAddress+$blockSize]
                 

            }
               

        }


        return [list  $map $sizeMap]


    }

    proc printTable rf {

        puts "|---------------------------|-------------|"
        puts "|    Name                   | Address     |"
        puts "|---------------------------|-------------|"

        $rf walkDepthFirst {
        
            if {[$it hasAttribute software.osys::rfg::absolute_address]} {
                puts "| [format "%20s" [$it name]]\t   |  [format %#0-20x [$it getAttributeValue software.osys::rfg::absolute_address]]"
            }


            return true
        }

    }

    proc saveCSV {rf file} {

         set r [odfi::closures::embeddedTclFromStringToString {

<%
puts "Name,Address"
%>
<%
    $rf walkDepthFirst {

        puts "[$it fullName],[format %#0-20x [$it getAttributeValue software.osys::rfg::absolute_address]]"


            return true
        }
%>
}]
    odfi::files::writeToFile  $file $rf


    }

    proc printTableHTML rf {

        set r [odfi::closures::embeddedTclFromStringToString {
<table>
    <thead>
        <tr><th>Name</th><th>Address</th></tr>
    </thead>
    <tbody>
    <%
    $rf walkDepthFirst {

        puts "<tr><td>[$it fullName]</td><td>[format %#0-20x [$it getAttributeValue software.osys::rfg::absolute_address]]</td>"


            return true
        }
    %>
    </tbody>
</table>
}]

        puts $rf
        return

   

    }



}
