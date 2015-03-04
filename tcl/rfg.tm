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


## Provides the base API interface for OSYS Register File Generator
package provide osys::rfg 1.0.0
package require Itcl  3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::rfg {


    variable registerSize 64

    #############################
    ## Generator Search
    ##############################

    ## Tries to instanciate a generator using provided full name class
    ## If not found, tries to load a package using: package require $name
    proc getGenerator {name registerFile} {

        ## Search for class 
        set generators [itcl::find classes $name]

        if {[llength $generators]==0} {

            ## Not Found, try to load package 
            #########
            set packageName "osys::rfg::generator::[string tolower $name]"
            set generatorName "::${packageName}::[string toupper $name 0 0]"
            if {[catch "package require $packageName"]} {
                
                ## Error 
                error "Generator class $name was not found, and no package having conventional name $packageName could be found"

            } else {

                ## Research and fail if not found
                set generators [itcl::find classes $generatorName]
                if {[llength $generators]==0} {

                    ## Error
                    error "After loading conventionally named package $packageName, conventional generator $generatorName could not be found "

                } else {

                    return [::new $generatorName #auto $registerFile]
                }
            }
        } else {

            ## Found -> instanciate 
            ############
            return [::new $name #auto $registerFile]
        }

    }

    

    ##########################
    ## Common Types
    #########################
  
    itcl::class Region {

         odfi::common::classField public size 0

    }

    ## This class contains the base informations for a RF modelisation like name etc...
    itcl::class Common {

        odfi::common::classField public name ""

        odfi::common::classField public description ""
        
        odfi::common::classField public parent ""

        constructor {cName} {

            ## Set location 
            #puts "----------------- LOC of $cName --------------------"
            attributes rfg {

                set location  [odfi::common::findUserCodeLocation]
                osys::rfg::file [lindex $location 0]
                osys::rfg::line [lindex $location 1]
            }

            set name $cName
        }

        ## Returns a list of the parents, from top to this (first is top)
        public method parents args {

            set parents {}
            set current $this
            while {$current!=""} {
                lappend parents $current
                set current [$current parent]
            }
            set parents [lreverse $parents]
            return $parents

        }

        ## Returns a . separated list per default with the names up to top
        public method fullName {{sep .}} {

            return [join [odfi::list::transform [parents] {return [$it name]}] $sep]

        }

        #################################
        ## Attributes Interface 
        #################################

        ## Attributes
        public variable attributes {}


        ## name format: attributeGroupName.attributeQualified name 
        ## Example: hardware.rw
        public method hasAttribute qname {

            set components [split $qname .]

            ## Look for attribute 
            set groupName [lindex $components 0]
            set attributeName [join [lrange $components 1 end] .]
            
            set foundAttributes [lsearch -glob -inline $attributes *$groupName]

            if {$foundAttributes!=""} {
                ## Found attributes group, look for attribute 
                if {[$foundAttributes contains $attributeName]} {
                    return 1
                } else {
                    return 0
                }

            } else {
                return 0
            }



        }

        public method onRead {group closure1 {keyword ""} {closure2 ""}} {
    
            if {[hasAttribute ${group}.osys::rfg::ro] || [hasAttribute ${group}.osys::rfg::rw]} {
                odfi::closures::doClosure $closure1 1
            } else {

                if {$closure2 != ""} {
                    odfi::closures::doClosure $closure2 1
                }
            }
        }

        public method onWrite {group closure1 {keyword ""} {closure2 ""}} {
            if {[hasAttribute ${group}.osys::rfg::wo] || [hasAttribute ${group}.osys::rfg::rw]} {
                odfi::closures::doClosure $closure1 1
            } else {
                if {$closure2 != ""} {
                    odfi::closures::doClosure $closure2 1
                }
            }
        }

        public method onAttributes {attributeList closure1 {keyword ""} {closure2 ""}} {
            set scoreList {}

            foreach element $attributeList {
                if {[hasAttribute $element]} {
                    lappend scoreList "true"
                } else {
                    lappend scoreList "false"
                } 
            }
            if {[lsearch -exact $scoreList "false"] == -1} {
                odfi::closures::doClosure $closure1 1
            } else {
                if {$closure2 != ""} {
                    odfi::closures::doClosure $closure2 1
                }
            }
        }

        ## name format: attributeGroupName.attributeQualified name 
        ## Example: hardaware.software_written
        public method getAttributeValue qname {
            
            set components [split $qname .]
            set groupName [lindex $components 0]
            set attributeName [join [lrange $components 1 end] .]
            set foundAttributes [lsearch -glob -inline $attributes *$groupName]

            if {$foundAttributes!=""} {
                return [$foundAttributes getValue $attributeName]
            }
            return false
        }

        public method attributes {groupName closure} {

            ## Create if not existing already 
            #############
            set foundAttributes [lsearch -glob -inline $attributes *$groupName]

            if {$foundAttributes!=""} {
               
               ## Apply Closure 
               $foundAttributes apply $closure

            } else {
                set foundAttributes [::new [namespace parent]::Attributes [lindex [split $this ::] end].$groupName $groupName $closure]

                ## Add to list
                lappend attributes $foundAttributes 

        
            }

            ## Return 
            return $foundAttributes
        }  

        ## Execute closure on each Attributes, with variable name: $attrs
        public method onEachAttributes closure {

            foreach attrs $attributes {
                odfi::closures::doClosure $closure 1
            }
        }

    }


    #####################
    ## Attribute
    #####################
    itcl::class Attributes {

        odfi::common::classField public name ""

        odfi::common::classField public description ""
        
        odfi::common::classField public parent ""

        ## List format: { {name value?}}
        odfi::common::classField public attr_list {}

        constructor {cName cClosure} {

            set name $cName

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }
        
        public method apply closure {
            odfi::closures::doClosure $closure
        }

        public method contains name {

            #puts "Looking for : $name"
            foreach {pair} $attr_list {
                
                ##puts "Available $pair"    
                
                if {[lindex $pair 0]==$name} {
                    return true
                }
            }
            return false
        }

        public method getValue name {
            foreach {pair} $attr_list {
                if {[lindex $pair 0]==$name} {
                    return [lindex $pair 1]
                }
            }
            return false
        }

        public method addAttribute {attributeName args} {

            set attributeHasValue [expr [llength $args] == 0 ? false : true ]

            ## If attribute is present:
            ##   - Replace if value is provided 
            ##   - Leave untouched if no value 
            ## If attribute is not present, add 
            set attributeIndex [lsearch -index 0 -exact  $attr_list  $attributeName]

            if {$attributeIndex==-1} {

                ## Not present, add 
                if {$attributeHasValue} {
                   lappend attr_list [list $attributeName [lindex $args 0]]
                } else {
                    lappend attr_list [list $attributeName]
                }

            } else {

                ## Present, update only if value 
                if {$attributeHasValue} {
                    set attr_list [lreplace $attr_list $attributeIndex $attributeIndex [list $attributeName [lindex $args 0]]]
                }


            }

                          
        }

        ## Execute closure on each Attribute value, with variable names: $attr $value
        public method onEachAttribute closure {

            foreach attrContent $attr_list {

                uplevel "set attr [lindex $attrContent 0]"
                uplevel "set value \"\""
                if {[llength $attrContent]>1} {
                    uplevel "set value [lindex $attrContent 1]"
                }

                odfi::closures::doClosure $closure 1
            }

        } 


    }

    ######################
    ## Group 
    ######################
    itcl::class Group {       
        inherit Common
        
        ## maximal allowed register size                 
        odfi::common::classField public register_size 64
        
        ## Components
        odfi::common::classField public components {}        

        constructor {cName cClosure} {Common::constructor $cName} {
            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

        public method sourceRF {rf_filename attribute name} {
            set RF_list_old {}
            set RF_list_new {}

            foreach object [itcl::find objects] {
                if {[$object isa osys::rfg::RegisterFile]} {
                    lappend RF_list_old $object   
                }
            }
            
            source $rf_filename

            foreach object [itcl::find objects] {
                if {[$object isa osys::rfg::RegisterFile]} {
                    lappend RF_list_new $object
                }
            }

            foreach RF $RF_list_old {
                set index [lsearch -exact $RF_list_new $RF]
                set RF_list_new [lreplace $RF_list_new $index $index]     
            }

            foreach RF $RF_list_new {
                if {[$RF parent] == $this} {
                    if {$name != ""} {
                        $RF name $name 
                    } else {
                        set done 0
                        set old_name [$RF name]
                        set n 0
                        set name_count 0
                        while {!$done} {
                            [$RF parent] onEachComponent {
                                if {[$it name] == [$RF name]} {
                                    incr name_count 
                                }
                                if {$name_count == 2} {
                                    $RF name ${old_name}_$n

                                    incr n
                                    set done 0         
                                } else {
                                    set done 1 
                                }
                            } 
                            set name_count 0
                        }
                        puts "WARNING: Automatic naming was used for [$RF name] in [$RF parent]"
                    }
               $RF attributes hardware {
                        $attribute
                    }
                }
            }
        }

        public method internal {rf_filename {name ""}} {
           
            sourceRF $rf_filename internal $name 
        
        }

        public method external {rf_filename {name ""}} {

            sourceRF $rf_filename external $name 

        }

        public method registerFile {gName closure} {
            set newregisterFile [::new [namespace parent]::RegisterFile $name.$gName.#auto $gName $closure]
            lappend components $newregisterFile
            $newregisterFile parent $this                            
            ## Return
            return $newregisterFile 
        }

        ## Content 
        ################
        public method add ct {
            lappend components $ct
        }

        ## Groups 
        #################

        ## Add a new Group with configuration closure 
        ## @return the group instance
        public method group {gName closure} {

            ## Create 
            set newGroup [::new [namespace current] $name.$gName.#auto $gName $closure]
 
            ## Add to list
            lappend components $newGroup
            ## calculate size
            set size_int 0
            $newGroup parent $this                           
            ## Return
            return $newGroup 

        }
        public method aligner {bits} {
            set size [expr "2**$bits"]
        } 

        public method checker {bits closure} {
            set start_address $size
            odfi::closures::doClosure $closure 1
            set end_address $size
            if {[expr "$end_address-$start_address"]>[expr "2**$bits"]} {
                error "The addresspan within the checker in $this is [expr "$end_address-$start_address"] but only [expr "2**$bits"] addresses are allowed!"
            }  
        }
        public method onEachComponent closure {
            foreach it $components {
                odfi::closures::doClosure $closure 1
            }        
        }

        public method onEachGroup closure {

            foreach it $components {
                #uplevel "set it $it"
                if {[$it isa osys::rfg::Group]} {
                    odfi::closures::doClosure $closure 1
                }
            }

        }

        ## Registers 
        ###################

        ## Add a new Register with configuration closure 
        ## @return the register instance
        public method register {rName closure} {

            ## Create 
            set newRegister [::new [namespace parent]::Register $this.$rName $rName $closure]
            
            ## Add to list
            lappend components $newRegister 
 
            ## Check Registers size
            set register_width 0            
            $newRegister onEachField {
                incr register_width [$it width]
            }
            
            if {$register_width > $register_size} {
                error "The register $newRegister is $register_width wide and exceeds the allowed $register_size bits!"
            }

            ## Return 
            $newRegister parent $this
            return $newRegister 


        }
        public method ramBlock {rName closure} {
            
            ## Create
            set newRamBlock [::new [namespace parent]::RamBlock $name.$rName.#auto $rName $closure]
            
            ## Add to list
            lappend components $newRamBlock

            ## Check RamBlock width
            set ramBlock_width 0
            $newRamBlock onEachField {
                incr ramBlock_width [$it width]
            }

            if {$ramBlock_width > $register_size} {
                error "The ramblock width $newRamBlock is $ramBlock_width wide and exceeds the allowed $register_size bits!"                           
            }

            ## Return 
            $newRamBlock parent $this
            return $newRamBlock                
        }
        public method onEachRegister closure {

            odfi::list::each $components {
                if {[$it isa osys::rfg::Register]} {
                    odfi::closures::doClosure $closure 1
                }

            }

        }

        ## Tree Walking 
        ####################

        ## Runs closure on this subtree providing node/parent variable pairs
        ## Closure parameters: $parent  and $node 
        public method walk closure {

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [list $this]

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifo]>0} {

                set item [lindex $componentsFifo 0]
                set componentsFifo [lreplace $componentsFifo 0 0]


                odfi::closures::doClosure $closure 1

                ## Group -> add all subgroups and registers as next possible Continue 
                ##############
                if {[$item isa [namespace current]]} {
                   
                   #::puts "Gound gorupd"
                   set componentsFifo [concat $componentsFifo [$item components]]
                   
                } elseif {[$item isa [namespace parent]::Register]} {
                    set componentsFifo [concat $componentsFifo [$item fields]]
                }
            }
        }


        public method walkWith closure {

           # puts "-- Walking tree of $this"

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [$this components]

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifo]>0} {

                set it [lindex $componentsFifo 0]
                set componentsFifo [lreplace $componentsFifo 0 0]

                set res [odfi::closures::doClosure $closure 1]


                ## If Decision is true and we have a group -> Go down the tree 
                #################
                if {$res && [$it isa [namespace current]]} {
                    set componentsFifo [concat $componentsFifo [$it components]]
                }

            }
        }

        public method walkDepthFirst closure {

           # puts "-- Walking tree of $this"

            ## Prepare list : Pairs of Parent / node
            ##################
            set componentsFifo [$this components]

            ## Go on FIFO 
            ##################
            while {[llength $componentsFifo]>0} {

                set it [lindex $componentsFifo 0]
                set componentsFifo [lreplace $componentsFifo 0 0]


                #puts "--> Element $it"

                set res [odfi::closures::doClosure $closure 1]

                ##puts "---> Decision: $res"

                ## If Decision is true and we have a group -> Go down the tree 
                #################
                if {([string is boolean $res] && $res) && [$it isa [namespace current]]} {
                    set componentsFifo [concat [$it components] $componentsFifo]
                }

            }
        }

    }

    ################################
    ## Fields 
    ###############################
    itcl::class FieldsSupport {


        ## List of fields
        odfi::common::classField public fields {}

        ## Fields 
        ######################

        ## Add a new Register with configuration closure 
        ## @return the register instance
        public method field {fName closure} {

            ## Create 
            if {$fName == Reserved} {
                set newField [::new [namespace parent]::Field $this.$fName.#auto $fName $closure]
            } else {
                set newField [::new [namespace parent]::Field $this.$fName $fName $closure]
            }

            ##puts "Created field: $newField"

            ## Add to list
            lappend fields $newField 

            ## Set parent
            $newField parent $this

            ## Return 
            return $newField 


        }

        public method reserved {reserved_width} {

            field Reserved {
                name "Reserved"    
                width $reserved_width
            }
        }

        public method onEachField closure {

            odfi::list::each $fields {
                odfi::closures::doClosure $closure 1


            }

        }

    }

    ############################
    ## Register 
    ############################
    itcl::class Register {
        inherit FieldsSupport Common
        
       

        constructor {cName cClosure} {Common::constructor $cName} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

        

    }

    ############################
    ## RamBlock 
    ############################
    itcl::class RamBlock {
        inherit FieldsSupport Common Region 
        odfi::common::classField public depth 1
        odfi::common::classField public width 64

        

        constructor {cName cClosure} {Common::constructor $cName} {
            attributes software {
                address_shift 0
            }
            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

        public method apply closure {
            odfi::closures::doClosure $closure
        }

    }
    ## Update Size upon depth change 
    itcl::configbody RamBlock::depth {

        #puts "CONFIGURING SIZE for $depth in [namespace current]"
        size [expr $osys::rfg::registerSize*$depth]

        #puts "SIZE is now [size]"
    }
    

    #####################
    ## Field
    #####################
    itcl::class Field {
        inherit Common 
        ## Width Always in bits
        odfi::common::classField public width 0

        ## Reset value
        odfi::common::classField public reset 0
        
        constructor {cName cClosure} {Common::constructor $cName} {
            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }
    }

    #######################
    ## Register File : Top Definitions
    #########################

    ## Main Factory  : Object name is the provided name, beware of conflicts
    proc registerFile {name closure} {

        return [::new RegisterFile ::$name $name $closure]

    }

    ## Main Factory  : Object name is the provided name, beware of conflicts
    proc group {name closure} {

        return [::new Group ::$name $name $closure]

    }

    itcl::class RegisterFile {
        inherit Group Region
        ## Constructor
        ## Call the parent Group constructor with empty closure, otherwise code won't see this registerfile special functions
        constructor {cName cClosure} {Group::constructor $cName {}} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

        public method apply closure {
            odfi::closures::doClosure $closure
        }
    }
    source [file dirname [info script]]/globalfunctions.tcl
    source [file dirname [info script]]/rfgfunctions.tcl
}
