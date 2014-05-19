## Provides the base API interface for OSYS Register File Generator
package provide osys::rfg 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::rfg {


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
            set generatorName "::${packageName}::$name"
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
  
    ## This class contains the base informations for a RF modelisation like name etc...
    itcl::class Common {

        odfi::common::classField public name ""

        odfi::common::classField public description ""
        
        odfi::common::classField public parent ""

        constructor {cName} {

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

            #puts "Has attribute $groupName $attributeName"

            #puts "Available attributes: $attributes"
            
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

        public method OnAttributes {attributeList closure1 {keyword ""} {closure2 ""}} {
            set scoreList {}
            #puts "OnAttributes"
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
                if {$keyword == "otherwise"} {
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

        public method attributes {fName closure} {
            ## Create 
            ## puts "[namespace parent]::Attributes [lindex [split $this ::] end].$fName"
            set newAttribute [::new [namespace parent]::Attributes [lindex [split $this ::] end].$fName $fName $closure]


            ##puts "Created field: $newField"

            ## Add to list
            lappend attributes $newAttribute 

            ## Return 
            return $newAttribute
        }  

        ## Execute closure on each Attributes, with variable name: $attrs
        public method onEachAttributes closure {

            foreach attrs $attributes {
                odfi::closures::doClosure $closure 1
            }
            #odfi::list::each $attributes {

            #    odfi::closures::doClosure $closure 1


            #}
        }

        ## Execute closure on each Attributes, with variable name: $attrs
        public method onEachAttributes2 closure {

            odfi::list::each $attributes {

               odfi::closures::doClosure $closure 1


            }
        }

    }


    #####################
    ## Attribute
    #####################
    itcl::class Attributes {
        inherit Common 

        ## List format: { {name value?}}
        odfi::common::classField public attr_list {}

        constructor {cName cClosure} {Common::constructor $cName} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
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

        public method addAttribute {fname args} {
            if { [llength $args] == 0} {
                lappend attr_list $fname
            } else {
                lappend attr_list [list $fname [lindex $args 0]]
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
            #odfi::list::each $attributes {

            #    odfi::closures::doClosure $closure 1


            #}
        } 

        ## Execute closure on each Attribute value, with variable names: $attr $value
        public method onEachAttribute2 closure {

            odfi::list::each $attr_list {

                odfi::closures::doClosure $closure 1


            }
        } 


    }

    #####################
    ## Address
    #####################
    itcl::class Address {
        inherit Common

        odfi::common::classField public address 0
        odfi::common::classField public absoluteAddress -1
        odfi::common::classField public size 0


        ## Resolve Absolute address by parent calling, return result if already defined
        public method getAbsoluteAddress args {     
            if {$absoluteAddress!=-1} {
                ## Already defined 
                return $absoluteAddress
            } else {
                ## Not Defined
                if {[$this parent] != ""} {
                    ## Resolve using parent
                    return [expr [[$this parent] getAbsoluteAddress]+$address]

                } else {

                    ## No parent -> 0
                    return 0
                }
            }
        }

        public method getAbsoluteAddress2 args {
            if {$absoluteAddress != -1} {
                return $absoluteAddress
            } else {
                [lindex [$this parents] 0] walk {
                    if {![$item isa osys::rfg::RegisterFile] && ![$item isa osys::rfg::Field]} {
                        if {[$item isa osys::rfg::RamBlock]} {
                            if {[$item address] > [[$item parent] address]} {
                                $item absoluteAddress [$item address]    
                            } else {
                                $item absoluteAddress [expr "[$item address] * int(ceil(double([[$item parent] address])/double([$item address]))) "]
                            }
                        } else {
                            $item absoluteAddress [expr [[$item parent] address] + [$item address]]
                        }
                    }
                }
                return $absoluteAddress
            }
        }

        public method setAbsoluteAddressFromHex args {

            if {$args !=""} {
                set absoluteAddress [scan $args 0x%x]

            }
            
        }

        ## Returns the absolute Adress as HEX string
        public method getAbsoluteAddressHex args {
            format "%X" [getAbsoluteAddress]
        }

        ## Returns the absolute Adress as HEX string
        public method getAbsoluteAddressHex2 args {
            format "%X" [getAbsoluteAddress2]
        }
    } 
   
    ######################
    ## Group 
    ######################
    itcl::class Group {       
        inherit Address
        
        ## maximal allowed register size                 
        odfi::common::classField public register_size 64
        
        ## Components
         odfi::common::classField public components {}        
        
        public variable address_counter 0
        constructor {cName cClosure} {Common::constructor $cName} {
            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }


        ## external Method
        ####################
        ## Sources an external RegisterFile 
        public method external {rf_filename} {
            puts itcl::find objects
            set RF_list_old {}
            set RF_list_new {}
            foreach object [itcl::find objects] {
                if {[$object isa osys::rfg::RegisterFile]} {
                    lappend RF_list_old $object   
                }
            }
            source $rf_filename
            foreach object [itcl::find objects] {
                
            }
            puts itcl::find objects
        }

        public method registerFile {gName closure} {
            set newregisterFile [::new [namespace parent]::RegisterFile $name.$gName.#auto $gName $closure]
            lappend components $newregisterFile

            $newregisterFile address $size
            incr size [$newregisterFile size]
            $newregisterFile parent $this                            
            ## Return
            return $newregisterFile 
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
                
            $newGroup address $size
            incr size [$newGroup size]
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
            set newRegister [::new [namespace parent]::Register $name.$rName.#auto $rName $closure]
            
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
            
            ## calculate address
            $newRegister address $size
            $newRegister size [expr "$register_size/8"]            
            incr size [expr "$register_size/8"]

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
            
            ## calculate address
            if {[expr "$size%([$newRamBlock depth]*$register_size/8)"] != 0} {
                set offset [expr "int(floor($size/([$newRamBlock depth]*$register_size/8)))*[$newRamBlock depth]* $register_size/8"]
                set size [expr "[$newRamBlock depth]* $register_size/8 + $offset"]
            }
            
            if {$size == 0} {
                set offset [expr "int(floor($size/([$newRamBlock depth]*$register_size/8)))*[$newRamBlock depth]* $register_size/8"]
                set size [expr "[$newRamBlock depth]* $register_size/8 + $offset"]
            }

            $newRamBlock address $size
            $newRamBlock size [expr "[$newRamBlock depth] * $register_size/8"]
            ## + floor($size/[$newRamBlock depth])*[$newRamBlock depth]"] 
            
            incr size [expr "[$newRamBlock depth] * $register_size/8"]       
            ## + floor($size/[$newRamBlock depth])*[$newRamBlock depth]"] 

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

            ## First call -> this with no parent 
            #########
            #set parent ""
            #set node $this 
            #odfi::closures::doClosure $closure 

            #set parent $this

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
    }

    ############################
    ## Register 
    ############################
    itcl::class Register {
        inherit Address
        
        ## List of fields
       odfi::common::classField public fields {}

        constructor {cName cClosure} {Common::constructor $cName} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

        ## Fields 
        ######################

        ## Add a new Register with configuration closure 
        ## @return the register instance
        public method field {fName closure} {

            ## Create 
            set newField [::new [namespace parent]::Field $this.$fName.#auto $fName $closure]


            ##puts "Created field: $newField"

            ## Add to list
            lappend fields $newField 

            ## Set parent
            $newField parent $this

            ## Return 
            return $newField 


        }

        public method reserved {reserved_width} {

            field Reserved {width $reserved_width}
        }

        public method onEachField closure {

            odfi::list::each $fields {

                odfi::closures::doClosure $closure 1


            }

        }

    }

    ############################
    ## RamBlock 
    ############################
    itcl::class RamBlock {
        inherit Register
        odfi::common::classField public depth 1
        odfi::common::classField public width 64
        constructor {cName cClosure} {Register::constructor $cName {}} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }
    }

    ###########################
    ## Reserved
    ###########################
    # itcl::class Reserved {
    #     inherit Field
    #     ## Width Always in bits
    #     odfi::common::classField public width 0

    #     constructor {cName cClosure} {Common::constructor $cName} {

    #         ## Execute closure 
    #         odfi::closures::doClosure $cClosure
    #     }
    # }

    

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

    proc attributeFunction {fname} {
  
        set attributeName [string trimleft $fname ::]

        ## If name is not categorized using xx.xxx.attributeName, set it to global.attributeName
        if {![string match *.* $attributeName]} {
            set attributeName "global.$attributeName"
        }

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

    itcl::class RegisterFile {
        inherit Group
        ## Constructor
        ## Call the parent Group constructor with empty closure, otherwise code won't see this registerfile special functions
        constructor {cName cClosure} {Group::constructor $cName {}} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }
    }

    source [file dirname [info script]]/globalfunctions.tcl
}