package provide HelperFunctions 1.0.0

# logarithmus dualis function for address bit calculation
proc ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"

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
	set size 0
	set offset [$registerfile getAttributeValue software.osys::rfg::absolute_address]
	$registerfile walk {
		if {![$item isa osys::rfg::Group]} {
		 	if {[string is integer [$item getAttributeValue software.osys::rfg::absolute_address]]} {
		 		if {$size <= [$item getAttributeValue software.osys::rfg::absolute_address]} {
		 			set size [expr [$item getAttributeValue software.osys::rfg::absolute_address]+[$item getAttributeValue software.osys::rfg::size]]
		 		}
		 	}
		}
	}
	return [expr $size - $offset]
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