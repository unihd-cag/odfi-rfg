---
layout: default
title: Osys RFG
---

## Overview

The CAG RegisterFile Generator (RFG) is a TCL-based register file hierarchy description language, which generates hardware (Verilog RTL) and software interfaces for control and status registers to be used in an FPGA or ASIC design.

For example a register file definition with the RFG (Example_RF.rf):

    registerFile Example_RF {
    
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
                        hardware_wen
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

Now the in the RFG available generators can be applied on the description to generate the verilog, xml, and documentation files. For this a little generator script is written. For example to create a verilog description and a xml representation:

    package require osys::rfg 1.0.0
    package require osys::generator 1.0.0
    
    readRF "Example_RF.rf"
    
    generator verilog {
        destinationPath "doc/"
    }

    generator xmlgenerator {
        destinationPath "xml/"
    }

## Available Generators

- Hierarchical Verilog
- HTML Documentation
- Generic XML representation

## Software Interfaces

- Generic Scala API 
