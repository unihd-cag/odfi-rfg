# Features

## Elements

### registerFiles

A registerFile can be seen as the main entity.

	osys::rfg::registerFile test_rf {
 	    description "Test registerfile"

	}

Real example:

	osys::rfg::registerFile test_rf {
	    description "Test registerfile"

	}

### group

A group can be used in a registerfile to group elements inside a registerFile

	group test_group {
	    description "Test group"

	}

Real example:

	osys::rfg::registerFile test_rf {
	    description "Test registerfile"
	    group test_group {
	        description "Test group"

	    }
	}

### register

A register can be used in registerfile or group. The register describes a physical unit  with a defined with (default 64 bit) inside the registerfile.

	register test_register {
	    description "Test register"
	}

Real example:

	osys::rfg::registerFile test_rf {
	    description "Test registerfile"
	    group test_group {
	        description "Test group"
	        register test_register {
	            description "Test register"
	            
	        }
	    }
	}	

### field

A field is used inside a register and describes a part of the physical unit of the register.

	field test_field {
	    description "Test field"
	    width 16
	    hardware rw
	    software rw
	}

Real example:

	osys::rfg::registerFile test_rf {
	    description "Test registerfile"
	    group test_group {
	        description "Test group"
	        register test_register {
	            description "Test register"
	            field test_field {
	                description "Test field"
	                width 16
	                hardware rw
	                software rw
	            }
	        }
	    }
	}

### ramBlock

A ramBlock can be used in a registerfile or a group. The ramBlock will be implemented as a RAM inside the registerfile

	ramBlock test_ram {
	    description "Test ram"
	    width 16
	    depth 32
	    hardware rw
	    software rw	
	}

Real example:

	osys::rfg::registerFile test_rf {
	    group test_group {
	        ramBlock test_ram {
	            width 16
	            depth 32 
	            software rw
	            hardware rw
	        }
	    }
	}

### aligner

Aligners can be used inside registerfiles to allign the next element to a new address offset.

	aligner 12

This examples alignes the next object to the next 2**12 address

Real example:

	osys::rfg::registerFile test_rf {

	    group test_group1 {
	        register test_register {
	            description "Test register"
	            field test_field {
	                description "Test field"
	                width 32
	                hardware rw
	                software rw
	            }
	        }
	    }

	    aligner 12

	    group test_group2 {
	        register test_register {
	            description "Test register"
	            field test_field {
	                description "Test field"
	                width 64
	                hardware rw
	                software rw
	            }
	        }
	    }

	}



### checker

A checker can be used to check the addresses in the address space, should be used when aligners are used.

	checker 12 {

	}

Real example:

	osys::rfg::registerFile test_rf {

	    checker 12 {
	        group test_group1 {
	            register test_register {
	                description "Test register"
	                field test_field {
	                    description "Test field"
	                    width 32
	                    hardware rw
	                    software rw
	                }
	            }
	        }
	    }

	    aligner 12

	    group test_group2 {
	        register test_register {
	            description "Test register"
	            field test_field {
	                description "Test field"
	                width 64
	                hardware rw
	                software rw
	            }
	        }
	    }

	}

## Attributes

### ramBlock Attributes

A ramBlock has diffirent attributes which describe some properties of the generated RAM.
<br>
<br>

<table border="1">
	<tr>
		<th> Attribute </th>
		<th> Description </th>
	</tr>
	<tr>
		<td> description </td>
		<td> short description of the element </td>
	</tr>
	<tr>
		<td> width </td>
		<td> data width of the RAM </td>
	</tr>
	<tr>
		<td> depth </td>
		<td> number of entries </td>
	</tr>
	<tr>
		<td> hardware </td>
		<td> hardware properties </td>
	</tr>
	<tr>
		<td> software </td>
		<td> software properties </td>
	</tr>

</table>

### field Attributes

A field can also have some Attributes which are listed here.
<br>
<br>

<table border="1">
	<tr>
		<th> Attribute </th>
		<th> Description </th>
	</tr>
	<tr>
		<td> description </td>
		<td> short description of the element </td>
	</tr>
	<tr>
		<td> width </td>
		<td> data widht of the RAM </td>
	</tr>
	<tr>
		<td> reset </td>
		<td> reset value of the register </td>
	</tr>
	<tr>
		<td> hardware </td>
		<td> hardware properties </td>
	</tr>
	<tr>
		<td> software </td>
		<td> software properties </td>
	</tr>

</table>

## Attribute properties

### software

This are the properties of the software interface to the register.
<br>
<br>

<table border="1">
	<tr>
		<th> Attribute property </th>
		<th> Description </th>
	</tr>
	<tr>
		<td> ro </td>
		<td> read only permission </td>
	</tr>
	<tr>
		<td> wo </td>
		<td> write only permission </td>
	</tr>
	<tr>
		<td> rw </td>
		<td> read and write permission </td>
	</tr>
</table>

### hardware

This are properties of the hardware interface to the register.
<br>
<br>

<table border="1">
	<tr>
		<th> Attribute property </th>
		<th> Description </th>
	</tr>
	<tr>
		<td> ro </td>
		<td> read only permission </td>
	</tr>
	<tr>
		<td> wo </td>
		<td> write only permission </td>
	</tr>
	<tr>
		<td> rw </td>
		<td> read and write permission </td>
	</tr>
	<tr>
		<td> software_written </td>
		<td> adds a software written signal to the field (1 written, 2 written and reset) </td>
	</tr>
	<tr>
		<td> hardware_wen </td>
		<td> adds a hardware write enable signal to the field </td>
	</tr>
	<tr>
		<td> counter </td>
		<td> adds counter function to field </td>
	</tr>
	<tr>
		<td> sticky </td>
		<td> if the value is set to high the hardware interface is not able to reset it to zero. </td>
	</tr>
	<tr>
		<td> software_write_xor </td>
		<td> does an xor on the software interface with the old value in the register. </td>
	</tr>
</table>

## A bigger Example

	osys::rfg::registerFile RF {
    
	    checker 8 {

	        group info_Group {
            
	            register info_register {
                
	                field ID {
	                    description "unique ID"
	                    width 32
	                    reset 32'h12abcd
	                    software ro
	                }

	                field GUID {
	                    description "generic user ID"
	                    width 32
	                    reset 32'h0
	                    software ro
	                    hardware wo
	                }

	            }

	        }

	    }

	    aligner 8

	    group GPR_Group {
	        ::repeat 16 {
	            register GPR_$i {
	                field GPF {
	                    description "General purpose field"
	                    width 64
	                    reset 64'h0
	                    software rw
	                    hardware {
	                        rw
	                        software_written 1
	                        hardware_wen
	                    } 
	                }
	            }
	        }
	    }

	    group RAM_Group {
	        ramBlock RAM {
	            width 16
	            depth 256 
	            software rw
	            hardware rw
	        }
	    }
	}


