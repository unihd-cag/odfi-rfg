---
layout: default
title: Getting Started
---

# Getting Started

This section will give you a starting point on working with the RFG Tool and provides a minimal example.

## The RFG Tool

If you have installed the executable like recommanded you now have the possiblity to execute the tool in this way:

    RFG-Vx.x.x Generate.tcl

To create a RegisterFile with the RFG tool two files are needed. First the .rf file which contains the register file description. And the Generator script which calls the different generators on this description.

## Example

In the First step we create our register file description MyFirstRF.rf

    registerFile MyFirstRF {
      
      ::repeat 16 {
        register GPR_$i {
          field GPF {
            description "General purpose field"
            width 32
            reset 32'h0
            software rw
            hardware {
              rw
              software_written 1
            }
          }
        }
      }
      
      ramBlock RAM {
        width 16
        depth 256 
        software rw
        hardware rw
      }
     
    }
    
This describes a Register with 16 General Porpuse Register GPR0-GPR15 with each a 32 bit wide field, which have read and wirte permissions on both hardware and software interface. An also have a software_written signal in the hardware interface. It also implements the RAM as a ramBlock into the registerfile with the width 16 and 256 entries.

In the second step we have to create the Generator script to describe which generators should be used on the register file description. For this we have to create the Generate.tcl script with the following content:

    readRF "MyFirstRF.rf"
    
    generator verilog {
      destinationPath "verilog/"
    }
    
    generator xmlgenerator {
      destinationPath "xml/"
    }
    
With the readRF command the register file description is read in and the addresses are calculated. After that the two verilog generator and xmlgenerator are applied. on the register file. This ouptus a verilog description at verilog/MyFirstRF.v and a xml description at xml/MyFirstRF.xml

Now in the last step we have to run RFG with the Generator script and the regiter file description:
For this run the RFG command in your project folder:

    RFG-Vx.x.x Generate.tcl
