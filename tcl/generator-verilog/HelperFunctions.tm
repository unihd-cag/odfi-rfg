package provide HelperFunctions 1.0.0

proc getSoftAccess {object} {
    set readable false
    set writeable false
    
    if {[$object isa osys::rfg::RamBlock]} {
        
        $object onWrite {software} {
            set writeable true
        }

        $object onRead {software} {
            set readable true
        }
    }

    if {[$object isa osys::rfg::Register]} {
        $object onAttributes {hardware.osys::rfg::rreinit_source} {
            set writeable true
        }

        $object onEachField {
            
            $it onWrite {software} {
                set writeable true
            }

            $it onRead {software} {
                set readable true
            }
        }

    }
 
    if {($writeable == true) && ($readable == true)} {
        return "1'b0"
    }

    if {($writeable == true) && ($readable == false)} {
        return "read_en"
    }

    if {($writeable == false) && ($readable == true)} {
        return "write_en"
    }

    if {($writable == false) && ($readable == false)} {
        return "write_en || read_en"
    }
}


set rb_save ""
proc hasRamBlock {rf} {
    global rb_save 
    if {$rb_save == ""} {
        set rb_save false
        $rf walkDepthFirst {
            if {[$it isa osys::rfg::RamBlock]} {
                if {![$it hasAttribute hardware.osys::rfg::external]} {
                    set rb_save true
                }
            }

            if {[$it isa osys::rfg::RegisterFile]} {
                return false	
            } else {
                return true
            }
        }
        return $rb_save
    } else {
        return $rb_save
    }
}

proc getRBAddrssDecode {object rf} {
    set dontCare [string repeat x [expr [ld [$object depth]] + [$object getAttributeValue software.osys::rfg::address_shift]]]
    set dontCare_width [expr [ld [$object depth]] + [$object getAttributeValue software.osys::rfg::address_shift]]
    set care [expr ([$object getAttributeValue software.osys::rfg::relative_address]/([$object depth]*[$rf register_size]/8)) >> [$object getAttributeValue software.osys::rfg::address_shift]] 
    set care [format %x $care]
    set care_width [expr [getAddrBits $rf] - [ld [$object depth]] - 3 - [$object getAttributeValue software.osys::rfg::address_shift]]
    if {$care_width == 0} {
        return "$dontCare_width'b$dontCare"
    } else {
        return "$care_width'h$care,$dontCare_width'b$dontCare"
    }
}

proc getRFAddrOffset {object} {
    return [ld [expr [$object register_size]/8]]
}
set AddrBits ""
set addr_object ""

proc getRFAddrWidth {object} {
    global AddrBits
    global addr_object
    if {$AddrBits == "" || $addr_object != $object} {
        set AddrBits [expr [getAddrBits $object]-[getRFAddrOffset $object]]
        set addr_object $object
    }
    return $AddrBits
}

proc getFirstSharedBusObject {object} {
    set obj ""
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::shared_bus} {
                set obj $it
            }
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            return false	
        } else {
            return true
        }

    }
    return $obj

}

proc needDelay {object} {
    set obj ""
    $object walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            if {![$it hasAttribute hardware.osys::rfg::external]} {
                set obj $it
            }
        }

        if {[$it isa osys::rfg::RegisterFile]} {
            return false	
        } else {
            return true
        }
    }

    return $obj

}

proc CheckForRegBlock {object} {
    set return_value false
    if {[$object isa osys::rfg::RamBlock]} {
        $object onWrite {software} {
            set return_value true
        }

        $object onRead {software} {
            set return_value true
        }

    } else {
        $object onAttributes {hardware.osys::rfg::rreinit_source} {
            set return_value true
        } otherwise {
            $object onEachField {
                $it onWrite {software} {
                    set return_value true
                }
                $it onWrite {hardware} {
                    set return_value true
                }
                $it onAttributes {hardware.osys::rfg::counter} {
                    if {[$it hasAttribute hardware.osys::rfg::wo] ||\
                        [$it hasAttribute hardware.osys::rfg::rw] ||\
                        [$it hasAttribute software.osys::rfg::wo] ||\
                        [$it hasAttribute software.osys::rfg::rw]} {
                        set return_value true
                    }
                } otherwise {
                   if {[$it reset] != ""} {
                        set return_value true
                    }
                }
            }
        }
    }

    return $return_value

}

proc hasReset {object} {
    set return_value false
    $object onAttributes {hardware.osys::rfg::rreinit_source} {
        set return_value true
    }
    $object onEachField {
       if {[$it reset] != ""} {
            set return_value true 
       }
    }
    return $return_value
}

proc getRelAddress {object} {
    return [$object getAttributeValue software.osys::rfg::relative_address]
}

proc hasWrite {interface object} {
    set return_value false
    $object onEachField {
        $it onWrite $interface {
            set return_value true
        }
    }
    return $return_value
}
# logarithmus dualis function for address bit calculation
proc ld x {
    expr {wide(ceil(log($x)/[expr log(2)]))}
}

## this functions finds a parent registerfile which is a internal RF 
## for this it uses an offset until which it searches
proc find_internalRF {it offset} {
    set val 0
    set delete_index [lsearch [$it parents] $offset]
    if {$delete_index >= 0} {
        set parents_list [lreplace [$it parents] 0 $delete_index]
    }
    foreach parent $parents_list {
        if {[$parent isa osys::rfg::RegisterFile]} {
            $parent onAttributes {hardware.osys::rfg::internal} {
                set val 1
            }
        }
    }
    if {$val == 0} {
        return reg
    } else {
        return wire
    }
}

# function to getRFmaxWidth
proc getRFmaxWidth {registerfile} {
 	set maxwidth 0
 	##::puts "RegisterFile: $registerfile"
 	$registerfile walkDepthFirst {
 		if {[$it isa osys::rfg::RamBlock]} {
 			if {$maxwidth < [$it width]} {
 				set maxwidth [$it width]
 			}
 		}
 		if {[$it isa osys::rfg::Register]} {
 			set tmp 0
 			$it onEachField {
 				incr tmp [$it width]
 			}
 			if {$maxwidth < $tmp} {
 				set maxwidth $tmp
 			}
 		}
 		return true
 	}
 	return $maxwidth
} 

# function to get the address Bits for the register file 
proc getRFsize {registerfile} {
    return [$registerfile getAttributeValue software.osys::rfg::size]
}

proc getAddrBits {registerfile} {
	return [ld [getRFsize $registerfile]]
}

# function which returns the Name with all parents
proc getName {object} {
	set name {}
	set list [lreplace [$object parents] 0 0]
	set i 0
	set deleteIndex 0
	
	foreach element $list {
		if {[$element isa osys::rfg::RegisterFile] && [$element hasAttribute hardware.osys::rfg::external]} {
			set deleteIndex [expr $i+1]
		}

		incr i 1
	}

	if {$deleteIndex == [llength $list]} {
		foreach element $list {
			lappend name [$element name]
		}
	} else {
		set i 0
		foreach element $list {
			if {$i >= $deleteIndex} { 
				lappend	name [$element name]
			}
			incr i 1		
		}
	}

	return [join $name "_"]	
}
