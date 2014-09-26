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

package provide osys::rfg::address::hierarchical-full 1.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::address::hierarchical-full {


    osys::rfg::attributeFunction absolute_address
    osys::rfg::attributeFunction size
    osys::rfg::attributeFunction aligner

    itcl::class RegistersRegion {
        inherit osys::rfg::Group osys::rfg::Region 

        constructor args {osys::rfg::Group::constructor "" ""} {

        }

        public method add ct {
            osys::rfg::Group::add $ct


            attributes sw {
                osys::rfg::address::hierarchical-full::size [expr [llength $components]*[expr $::osys::rfg::registerSize/8]]
            }

            puts "Updating Register region size [getAttributeValue sw.osys::rfg::address::hierarchical-full::size]"

        }

    }


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


        ## Reducing Contents to produce Regions only 
        ############################
        puts "-- RegisterRegions Reduce --"
        set regionsMap {}
        odfi::list::arrayEach $map {
            puts "-- Reducing: $key"

            set currentRegisterRegion false 
            set result {}
            foreach elt $value {

                ## Cases 
                ## - Find register and no regions -> create region and add to result, add reg to region 
                ## - Find register and region -> add to region 
                ## - Find non register -> forget region, add to result 
                if {![$elt isa osys::rfg::Register]} {
                    set currentRegisterRegion false 

                    set regionsMap [odfi::list::arrayConcat $regionsMap $key $elt]

                } elseif {[$elt isa osys::rfg::Register]} {

                    if {$currentRegisterRegion=="false"} {
                        set currentRegisterRegion [::new [namespace current]::RegistersRegion #auto]
                        set regionsMap [odfi::list::arrayConcat $regionsMap $key $currentRegisterRegion] 
                    }
                    $currentRegisterRegion add $elt 

                }

            }

        }

        odfi::list::arrayEach $regionsMap {
            puts "RegionsMap: $key\t -> $value"
        }

     

        ## Reduce Bottom UP The Map List for sizes 
        ## Key: Region , Value: content 
        ## Reduction: go through content, and increment the local address counter, including attributes for shifts and so on
        ############################
        puts "-- Size Reduce --"
        set sizeMap {}


        proc sizeOf operator {
            odfi::closures::doClosure {


            if {[string is integer "$operator"]} {
                return $operator
            } elseif {[$operator hasAttribute sw.osys::rfg::address::hierarchical-full::size]} {

                return [$operator getAttributeValue sw.osys::rfg::address::hierarchical-full::size]

            } else {
                return [expr [$operator size]*[expr $::osys::rfg::registerSize/8]]
            }

        }

        }

        set ns [namespace current]
        odfi::list::arrayEach [lreverse $regionsMap] {
            puts "-- Reducing: $key"

            set size [odfi::list::reduce $value {

                puts "----- $left ([sizeOf $left ]) + $right ([sizeOf $right])"

                switch -exact -- $right {
                    "" {
                      return [sizeOf $left ]
                    }
                    default {

                        ## Right Element size 
                        set rightSize [sizeOf $right]
                        

                        return [expr [sizeOf $left] + $rightSize ]
                    }
                }

            }]
            #$key size $size 
            set sizeMap  [odfi::list::arrayConcat $sizeMap $key $size]

            $key attributes sw {
                    ${ns}::size $size
            }

        }


        odfi::list::arrayEach $sizeMap {
            puts "S: $key\t -> $value"
        }

  

        ## Distribute
        ## Go again top down, and assign addresses 
        ###################

        puts "--------- Distribute Abs -----------------------------------------"
        set ad 0 
        set previousSize 0
        odfi::list::arrayEach  $regionsMap {

            foreach it $value {

                ## Update Current address For address shifting and so on 
                ###############

                puts "For $it, size is  [sizeOf $it] and previous is $previousSize"

                ## Get the number of Bits required for this region space 
                #set regionBits [expr int(floor(log([$it size])/log(2)))]

                ## If the size of the region + the accumulated elements size is still within the MSB space of the address space, don't go to the next power of two
                set adSize [expr $ad == 0 ? 0 : 2**(int(floor(log($ad)/log(2))))] 
                set itSize [sizeOf $it]
                set futureSize [expr $previousSize+[sizeOf $it]]

                #### BACKUP DISS WRITING ##########
                #if {$ad==0 || ($futureSize < $adSize)} 
                if {$ad==0 || ($previousSize <= $itSize)} {
                #### BACKUP DISS WRITING ##########
                    
                    ## Take the next power of two for the Region, and OR it with ad 
                    set nextPowerofTwo [expr 2**(int(floor(log([sizeOf $it])/log(2))))] 
                    set ad [expr (($ad-$previousSize) | $nextPowerofTwo) ]
                    

                } else {

                    set num_addr_bits [expr int(floor(log($itSize)/log(2)))]
                    set c_num_addr_bits [expr int(floor(log($ad)/log(2)))]
                    puts "For $it, Region is larger than available size in Address space, needed: $itSize bytes, which are $num_addr_bits, current: $c_num_addr_bits"

                   
                    ## Go to the next power of two after size increment of address
                    incr ad $itSize
                    set nextPowerofTwo [expr 2**(int(floor(log([expr $ad])/log(2))+1))] 
                    set ad $nextPowerofTwo 
                    

                }
            

                ## Aligner 
                ## This is totally wrong
                if {[$it hasAttribute hw.osys::rfg::address::hierarchical::aligner]} {

                    set cumulated 0
                    set ad [expr 1 << [$it getAttributeValue hw.osys::rfg::address::hierarchical::aligner]]

                }

                ## Address assign 
                set bla $it
                $it attributes sw {

                        osys::rfg::address::hierarchical-full::absolute_address $ad 
                        puts "Setting attributes $this for $it -> $attr_list, c addr $ad"
                }


                ## Go to next power of two: do log2 to get the number of bits, then power of two +1 for the next    
                set current_address_bits  [expr int(floor(log($ad)/log(2)))]

              #  puts "For $bla, going to next power of two (our address bits count is $current_address_bits) "

                set nextPowerofTwo [expr 2**(int(floor(log($ad)/log(2)))+1)] 
                set ad [expr $nextPowerofTwo]

                puts "--> After region $bla, reset ad to $ad"

                set previousSize [sizeOf $bla]
                  
                #set ad [expr $ad << 1]
                #set ad [expr $nextPowerofTwo]
                    

                ## Dispatch register addresses 
                ###################
                if {[$bla isa osys::rfg::address::hierarchical-full::RegistersRegion]} {
                    set count 0 
                    $bla onEachRegister {
                        $it attributes sw {
                            osys::rfg::address::hierarchical-full::absolute_address [expr $ad + [expr $count * $::osys::rfg::registerSize/8]]
                        }

                        incr count
                    }
                }
            



            }


        }


        return 

        set ad 0 
        set cumulated 0 
        $rf walkDepthFirst {

            ## Update Current address For address shifting and so on 
            ###############
            if {[$it isa ::osys::rfg::Region]} {

                puts "For $it, size is  [sizeOf $it] and accumulated is $cumulated"

                ## Get the number of Bits required for this region space 
                #set regionBits [expr int(floor(log([$it size])/log(2)))]

                ## If the size of the region + the accumulated elements size is still within the MSB space of the address space, don't go to the next power of two
                set adSize [expr $ad == 0 ? 0 : 2**(int(floor(log($ad)/log(2))))] 
                set itSize [sizeOf $it]
                set futureSize [expr $cumulated+[sizeOf $it]]

                #### BACKUP DISS WRITING ##########
                #if {$ad==0 || ($futureSize < $adSize)} 
                if {$ad==0 || ($cumulated <= $itSize)} {
                #### BACKUP DISS WRITING ##########
                    
                    ## Take the next power of two for the Region, and OR it with ad 
                    set nextPowerofTwo [expr 2**(int(floor(log([sizeOf $it])/log(2))))] 
                    set ad [expr (($ad-$cumulated) | $nextPowerofTwo) ]
                    

                } else {

                    set num_addr_bits [expr int(floor(log($itSize)/log(2)))]
                    set c_num_addr_bits [expr int(floor(log($ad)/log(2)))]
                    puts "For $it, Region is larger than available size in Address space, needed: $itSize bytes, which are $num_addr_bits, current: $c_num_addr_bits"

                   
                    ## Go to the next power of two after size increment of address
                    incr ad $itSize
                    set nextPowerofTwo [expr 2**(int(floor(log([expr $ad])/log(2))+1))] 
                    set ad $nextPowerofTwo 
                    

                }
               # incr ad [$it size]
                #set nextPowerofTwo [expr 2**(int(floor(log($ad)/log(2)))+1)] 

                #set ad $nextPowerofTwo
               # set cumulated 0 
                #set num_addr_bits [expr int(floor(log([$it size])/log(2)))]

               # puts "For region of [$it size] addresses, we need -> $num_addr_bits bits "
                #set ad [expr $ad | (1 << $num_addr_bits)]
                #
            }

            ## Aligner 
            if {[$it hasAttribute hw.osys::rfg::address::hierarchical::aligner]} {

                set cumulated 0
                set ad [expr 1 << [$it getAttributeValue hw.osys::rfg::address::hierarchical::aligner]]

            }

            ## Address assign 
            set bla $it
            $it attributes sw {

                    osys::rfg::address::hierarchical-full::absolute_address $ad 
                    puts "Setting attributes $this for $it -> $attr_list, c addr $ad"
            }

             if {[$bla isa ::osys::rfg::Region]} {

                ## Go to next power of two: do log2 to get the number of bits, then power of two +1 for the next
                if {$cumulated!=0} {
                    
                    set current_address_bits  [expr int(floor(log($ad)/log(2)))]

                  #  puts "For $bla, going to next power of two (our address bits count is $current_address_bits) "

                    set nextPowerofTwo [expr 2**(int(floor(log($ad)/log(2)))+1)] 
                    set ad [expr $nextPowerofTwo]

                    puts "--> After region $bla, reset ad to $ad"

                    set cumulated 0 
                } else {
                    set ad [expr $ad << 1]
                }
                #set ad [expr $ad << 1]
                #set ad [expr $nextPowerofTwo]
                

            } else {

                ## Not a region, accumulate, and increment ad by the same
                incr ad [sizeOf $bla]
                incr cumulated [sizeOf $bla]
            }

        #    incr ad [sizeOf $bla]
            #set ad [expr $ad+1]

            return true
        }

     

        return [list  $map $sizeMap]


    }

    proc printTable rf {

        puts "|---------------------------|-------------|"
        puts "|    Name                   | Address     |"
        puts "|---------------------------|-------------|"

        $rf walkDepthFirst {

        puts "| [$it fullName]\t    |  [format %#0-20b [$it getAttributeValue sw.osys::rfg::address::hierarchical-full::absolute_address]]"


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

        puts "[$it fullName],[format %#0-20b [$it getAttributeValue sw.osys::rfg::address::hierarchical-full::absolute_address]]"


            return true
        }
%>
}]
    odfi::files::writeToFile  $file $r


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

        puts "<tr><td>[$it fullName]</td><td>[format %#0-20b [$it getAttributeValue sw.osys::rfg::address::hierarchical::absolute_address]]</td>"


            return true
        }
    %>
    </tbody>
</table>
}]

        puts $r
        return

   

    }



}
