# Features

## Elements

### registerFiles

A registerFile can be seen as the main entity it can contain other registerfiles, groups and registers.

	registerFile test_rf {
 	    description "Test registerfile"

	}

Real example:

	registerFile test_rf {
	    description "Test registerfile"

	}

### group

A group can be used in a registerfile to group elements inside a registerFile

	group test_group {
	    description "Test group"

	}

Real example:

	registerFile test_rf {
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

	registerFile test_rf {
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

	registerFile test_rf {
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

	registerFile test_rf {
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

	registerFile test_rf {

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

	registerFile test_rf {

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

|Attribute|Description|
|---------|-----------|
|description|short description of the element|
|width|data width of the RAM|
|depth|number of entries|
|hardware|hardware properties|
|software|software properties|

### field Attributes

A field can also have some Attributes which are listed here.

|Attribute|Description|
|---------|-----------|
|description|short description of the element|
|width|data width of the RAM|
|reset|reset value of the field|
|hardware|hardware properties|
|software|software properties|

## Attribute properties

### software

This are the properties of the software interface to the register.

|Attribute property|Description|
|---------|-----------|
|ro|read only permission|
|wo|write only permission|
|rw|read and write permission|

### hardware

This are properties of the hardware interface to the register.

|Attribute property|Description|
|---------|-----------|
|ro|read only permission|
|wo|write only permission|
|rw|read write permission|
|software_written| adds software written signal to the field (1 written, 2 written and reset)|
|hardware_wen|adds hardware write enable signal to the field|
|counter|adds counter function to the field|
|sticky|if the value is set to high the hardware interface will not be able to reset it to zero|
|software_write_xor|does an xor on the software interface with the old value in the register|

## Other Features

### Loops

	::repeat 8 {

	}

Real Example:

	registerFile test_rf {
	    description "Test registerfile"
	    group test_group {
	        description "Test group"
		
	        ::repeat 8 {
	            register test_register_$i {
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
	} 

### Variables/Defines


## A bigger Example

### Register file description

In our example we generate a Registerfile with one info_register which is located in the info_Group.
This register has to fields (ID and GUID) with diffirent read and write permissions for software and hardware.

After this first group we have a group of general purpose registers in the GPR_Group these registers are aligned to 2**8.
We generate with the repeat statement 16 general purpose registers with a field which is 64 bit wide, has sotware and hardware read and write permission, a software_written and hardware_wen signal. 

Our last group contains a ramBlock which has 256 entries and is 16 bit wide.

	registerFile RF {

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



	    ##aligner 8

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

### Resulting address map 

Our register size is the default size of 64 bit so each register has a size of 8 Bytes. The info register can be found at base address 0x000 and has a size of 8 Byte. The next register starts with an offset of 2**8 Byte addresses. This is because of the aligner. Now we have a linear addresspace for the next 16 general purpose registers. 

At the end we have our ramBlock with the size of 2048 Byte. The size is this big because of the register size of 8 Bytes. So the size is our 256 entries multiplied by 8. But implemented is a 16 Bit x 256 RAM.  

|Base Address|Element|Size|
|------------|-------|----|
|0x000|info_Group_info_register|8|
|0x008|GPR_Group_GPR_0|8|
|0x010|GPR_Group_GPR_1|8|
|0x018|GPR_Group_GPR_2|8|
|0x020|GPR_Group_GPR_3|8|
|0x028|GPR_Group_GPR_4|8|
|0x030|GPR_Group_GPR_5|8|
|0x038|GPR_Group_GPR_6|8|
|0x040|GPR_Group_GPR_7|8|
|0x048|GPR_Group_GPR_8|8|
|0x050|GPR_Group_GPR_8|8|
|0x058|GPR_Group_GPR_10|8|
|0x060|GPR_Group_GPR_11|8|
|0x068|GPR_Group_GPR_12|8|
|0x070|GPR_Group_GPR_13|8|
|0x078|GPR_Group_GPR_14|8|
|0x080|GPR_Group_GPR_15|8|
|0x800|RAM_Group_RAM|2048|

