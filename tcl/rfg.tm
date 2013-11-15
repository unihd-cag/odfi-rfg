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


        constructor {cName} {

            set name $cName
        }

    }

    
    ######################
    ## Group 
    ######################
    itcl::class Group {
        inherit Common

        ## Groups : List of subgroups
        public variable groups {}

        ## Registers : List of registers 
        public variable registers {}

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
            lappend groups $newGroup 

            ## Return 
            return $newGroup 

        }

        public method onEachGroup closure {

            foreach it $groups {

                #uplevel "set it $it"
                odfi::closures::doClosure $closure 1
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
            lappend registers $newRegister 

            ## Return 
            return $newRegister 


        }

        public method onEachRegister closure {

            odfi::list::each $registers {

                odfi::closures::doClosure $closure 1


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
        inherit Common 

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
            set newField [::new [namespace parent]::Field $name.$fName.#auto $fName $closure]


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
    ## Field
    ######################
    itcl::class Field {
        inherit Common 

        ## Width Always in bits
        odfi::common::classField public width 0

        ## Reset value
        odfi::common::classField public reset 0

        ## Rights 
        odfi::common::classField public rights {}



        constructor {cName cClosure} {Common::constructor $cName} {

            ## Execute closure 
            odfi::closures::doClosure $cClosure
        }

        ## Rights 
        ######################

        ## Set Software rights 
        public method software args {

            foreach right $args {
                set rights [odfi::list::arrayConcat $rights software $right]
            }

        }

        ## Set hardware rights 
        public method hardware args {
            
            foreach right $args {
                set rights [odfi::list::arrayConcat $rights hardware $right]
            }

        }

        ## Reset 
        #######################


        ## Language
        ######################

        ## Configure the object using a special language, like
        public method it args {

            ## Size
            ###############


            if {[regexp {is\s+([0-9]+)\s+bit(?:s)?\s+wide} "$args" -> nwidth]} {

                ## Size in bits
                #####################

                width $nwidth

            } elseif {[regexp {is\s+([0-9]+)\s+byte(?:s)?\s+wide} "$args" -> nwidth]} {

                ## Size in bytes
                #####################

                width [expr $nwidth*8]

            } elseif {[regexp {is\s+([\w]+)?\s+((?:writable,?)?(?:readable,?)?)} "$args" -> readTarget newRights]} {

                ## Global Rights
                #####################
                foreach right [split $newRights ,] {

                    switch -exact -- $right {
                        readable {
                            set right r
                        }
                        writable {
                            set right w
                        }
                        
                    }
                    set rights [odfi::list::arrayConcat $rights $readTarget $right]
                }
                
           

            } elseif {[regexp {is\s+([\w]+)?\s+readable} "$args" -> readTarget]} {

                ## Readable Rights
                #####################
                set rights [odfi::list::arrayConcat $rights $readTarget r]
           

            } elseif {[regexp {is\s+([\w]+)?\s+writable} "$args" -> readTarget]} {

                ## Readable Rights
                #####################
                set rights [odfi::list::arrayConcat $rights $readTarget w]
           

            } else {

                odfi::common::logWarn "Configuration of field $name using non supported language sentence: it $args"
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
