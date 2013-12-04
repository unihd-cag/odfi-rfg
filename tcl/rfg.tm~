## Provides the base API interface for OSYS Register File Generator
package provide osys::rfg 1.0.0
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

namespace eval osys::rfg {

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

    }

    #####################
    ## Address
    #####################
    itcl::class Address {
        
        odfi::common::classField public address 0
        odfi::common::classField public absolute_address 0
        odfi::common::classField public size 0

        public method addOffset {object} {
            $object onEachComponent {
                $it absolute_address [expr "[$it address] + [$object absolute_address]"]
                if {[$it isa osys::rfg::Group]} {
                    addOffset $it 
                }          
            }
        }
        public method getAbsoluteAddress {} {           
            ## if parent is Register file calculate absolute addresses
            if {[$this parent] == ""} {
                addOffset $this               
            }
        }
    } 
   
    ######################
    ## Group 
    ######################
    itcl::class Group {       
        inherit Common Address
        
        ## maximal allowed register size                 
        odfi::common::classField public register_size 64
        
        ## Components
         odfi::common::classField public components {}        
        
        public variable address_counter 0
        constructor {cName cClosure} {Common::constructor $cName} {
            ## Execute closure 
            odfi::closures::doClosure $cClosure
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
            ##puts $newRegister
            $newRegister parent $this
            return $newRegister 


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
            set groupsFifo [list "" $this]

            ## First call -> this with no parent 
            #########
            #set parent ""
            #set node $this 
            #odfi::closures::doClosure $closure 

            #set parent $this

            ## Go on FIFO 
            ##################
            foreach {parent node} $groupsFifo {

                odfi::closures::doClosure $closure 

                ## Group -> add all subgroups and registers as next possible Continue 
                ##############
                if {[odfi::common::isClass $node [namespace current]]} {
                   
                    $node onEachGroup {
                        lappend groupsFifo $node $it
                    }

                    $node onEachRegister {
                        lappend groupsFifo $node $it
                    }
                   
                }
            }
        }
    }

    ############################
    ## Register 
    #############################
    itcl::class Register {
        inherit Common Address
        
        ## List of fields
        public variable fields {}

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

            ## Return 
            return $newField 


        }


        public method onEachField closure {

            odfi::list::each $fields {

                odfi::closures::doClosure $closure 1


            }

        }

    }

    #####################
    ## Attribute
    #####################
    itcl::class Attributes {
        inherit Common 
        odfi::common::classField public attr_list {}
        constructor {cName cClosure} {Common::constructor $cName} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }
        
        public method addAttribute {fname args} {
            if { [llength $args] == 0} {
                lappend attr_list $fname
            } else {
                lappend attr_list [list $fname [lindex $args 0]]
            }                
        }
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

        ## Attributes
        
        ## List of fields
        public variable attributes {}
        
        constructor {cName cClosure} {Common::constructor $cName} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

   	    public method attributes {fName closure} {
            ## Create 
            set newAttribute [::new [namespace parent]::Attributes $name.$fName.#auto $fName $closure]


            ##puts "Created field: $newField"

            ## Add to list
            lappend attributes $newAttribute 

            ## Return 
            return $newAttribute
	    }  

        public method onEachAttributes closure {

            odfi::list::each $attributes {

                odfi::closures::doClosure $closure 1


            }
        }
    }

    #######################
    ## Register File : Top Definition
    #########################

    ## Main Factory  : Object name is the provided name, beware of conflicts
    proc registerFile {name closure} {

        return [::new RegisterFile ::$name $name $closure]

    }

    proc attributeFunction {fname} {
  
        set res "proc $fname args {
            uplevel 1 addAttribute [string trimleft $fname ::] \$args 
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
}
