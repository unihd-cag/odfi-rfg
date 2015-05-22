---
layout: default
title: Input Format description
---

# Input Format Description

## Introduction

The input format is just a TCL script, which presents an Embedded Domain Specific Language API.
This means that the presented configuration language is also normal TCL code, leaving convienient control structure (like loops and conditions) to the TCL interpreter.

This section should give an overview of the register file description format.

## registerFile

A register file can be seen as the main entity and it can contain other register files, groups and/or registers.

    registerFile test_rf {
        description "Test register file"
    }

Real example:

    registerFile test_rf {
      description "Test register file"
      ## register file content
    }

## group

A group can be used in a register file to group elements inside the register file. In hardware it will only change the signal name and it is only an element for structuring

    group test_group {
      description "Test group"
    }

Real example:

    registerFile test_rf {
      description "Test registerfile"
      
      group test_group {
        description "Test group"
        ## Group content
      }
      ## other register file content
    }

## register
A register can be used in a register file or group. A register is the smallest addressable unit in the registerFile (by default 64 bit).

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
          ## register content 
        }
        
      }
      ## other register file content
    }

## field

A field is used inside a register and describes a part of the addressable unit of the register. If the sum of all field widths is greater than the register size, the generation will result in an error.

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
            description "Test field software read write, hardware read write permissions"
            width 16
            hardware rw
            software rw
          }
          
          field test_feld2 {
            description "Test field2 software read only, hardware write only"
            width 48
            hardware wo
            software ro
          }
          
        }
        
      }
      
      ## other register file content
      
    }

## ramBlock

A ramBlock can be used in a registerfile or a group. The ramBlock will be implemented as a RAM inside the registerfile.

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
        description "Test group"
        
        ramBlock test_ram {
          description "Test ram"
          width 16
          depth 32 
          software rw
          hardware rw
        }
        
      }
      
    }

## Attributes

Attributes define some Properties of the different objects in a registerfile, like field or ramBlock width, description and software or hardware properties.

### Main Attributes

| Attribute Name| Description    | Objects | 
| ------------- |:--------------:|--------:|
| description   | Description for the Object| group, register,field, ramBlock, registerFile|         
| width         | width of the Object| field, ramBlock|
| depth         | depth of a ramBlock| ramBlock |
| reset         | reset value of a field | field |

### Attribute Groups

### Attribute Properties
