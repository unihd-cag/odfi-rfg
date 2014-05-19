
package provide osys::rfg::address::hierarchical 1.0.0
package require odfi::files 1.0.0

namespace eval osys::rfg::address::hierarchical {


    osys::rfg::attributeFunction absolute_address
    osys::rfg::attributeFunction aligner

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



                return [expr $::osys::rfg::registerSize/8]

            } elseif {[$operator isa ::osys::rfg::Region] && ![$operator isa ::osys::rfg::Group]} {

                ## Non grouping regions must have size set
                #puts "NGR: [$operator size]"
                return [expr [$operator size]/8]

            } elseif {[$operator isa ::osys::rfg::Region]} {

                ## Search in map (size already in bytes)
                set size [odfi::list::arrayGet $sizeMap $operator]

                return $size

                ## Regions must have the size as attribute
                #$operator onAttributes hardware.size {

                #    return [expr int([$operator a])]

               # } otherwise {

        #

                #}
                ## Ramblocks can 

            } else {
                return 0
            }

            }

        }

        odfi::list::arrayEach [lreverse $map] {
            puts "-- Reducing: $key"

            set size [odfi::list::reduce $value {

                puts "------ Left: $left Right: $right"
                #puts "----- $left ([sizeOf $left ]) + $right ([sizeOf $right])"

                switch -exact -- $right {
                    "{}" -
                    "" {

                      set ls [sizeOf $left]
                      $left attributes software {
                        ::size  $ls
                      }
                      return $ls
                    }
                    default {

                        ## Right Element size 
                        set rightSize [sizeOf $right]
                        $right attributes software {
                            ::size  $rightSize
                        }
                        
                        ## Left size 
                        set ls [sizeOf $left]
                        if {![string is integer $left]} {
                            $left attributes software {
                                ::size  $ls
                            }
                        }
                        

                        return [expr [sizeOf $left] + $rightSize ]
                    }
                }

            }]
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

                    osys::rfg::address::hierarchical::absolute_address $ad 
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

        puts "| [$it fullName]\t    |  [format %#0-20b [$it getAttributeValue sw.osys::rfg::address::hierarchical::absolute_address]]"


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

        puts "[$it fullName],[format %#0-20b [$it getAttributeValue sw.osys::rfg::address::hierarchical::absolute_address]]"


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
