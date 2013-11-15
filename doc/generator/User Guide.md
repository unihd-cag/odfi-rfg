RFG User guide
==========================

RFG is the new port of old RFS
The goal is to define a cleaner interface, that nicely integrates with other existing tools, like the Driver Generator, or upcoming ones

# Register File Definition syntax

## Old RFS Format

In RFS, an XML input file was used, because the Register file is a hierarchical model
However, XML is only a static descriptive language, which does not support constructions like loops, if else etc...

    <regroot name="info_rf">   

        ...

        <reg64 name="driver">                                              
            <hwreg name="ver" width="32" sw="ro" hw="" reset="32'd18253" />
        </reg64>
        
        ...

        <reg64 name="tsc_global_load_value" desc="This register specifies the value the TSC register will be loaded with, in case of an global interrupt.">
    #ifdef ASIC
                <hwreg name="tsc_data" width="64" sw="rw" hw="ro"/>
    #else
                <hwreg name="tsc_data" width="48" sw="rw" hw="ro"/>
    #endif
        </reg64>

        ...

        <repeat loop="8" name="scratchpad">
            <reg64 name="scratchpad" desc="This register is one entry of the 64 byte scratchpad space offered by EXTOLL.">
                <hwreg name="data" width="64" sw="rw" hw="" reset="64'h0" desc="Scratchpad data."/>
            </reg64>
        </repeat>

    </regroot>

To leverage this issue, RFS was using following strategies:

- `<repeat>` elements to describe loops
- C preprocessor definitions like #ifdef and usage of macros, which were resolved by calls the to the C preprocessor to transform the file(s) before actual processing

## TCL model script format

A cleaner and more user friendly way to specify a Register File would be to avoid writing the XML directly, and use an API instead.

Normal classical script languages (compiled languages are not really convienient here) don't natively support a user friendly way to write code that would mirror the hierarchy of the Register File (it is possible, but that would make XML writing easier)

Using a Domain Specific Language that would be parsed to produce data structures then exported to XML is a possibility, however it imposes to have a language parser, which would need maintenance.

However, our TCL libraries allow us to solve this problem **Without using a Domain Specific Language**

This means that we can write hierarchical code, that simply is executed code, without any kind of parser

This is very advantageous, because we only need to specify an API, the user writes simple code as scripts, and the tool just loads the scripts (in TCL, simply: source file like a bash script)

## Simple Example

Let's have a look at this simple example, showing an extract of the info_rf registerfile:

    registerFile "extoll_rf" {

        group "info_rf" {

            register driver {

                field ver {


                    description "Driver version for software"
                    width        32
                    reset        32'd18253
                    software     ro  
                    hardware      r
                }
            }
        

        }

    }

This syntax stays quite clean, and the imbrication of the code blocks exactly mirrors the final structure:

> an **info_rf** registers group, with a **driver** register, containing a 32 bits wide field named **ver**

## XML Output

An XML format will still be offered by the tool, as it is very convenient in order to integrate the Register file definition with other languages, and other tools.
This format will then, like in RFS, be a fully descriptive and expanded format

Preview of the first tests (info_rf as register file, converted using rfs to rfg tool):

    <RegisterFile name="info_rf">
        <Register name="driver">
            <Field name="ver"  width="32" reset="32'd18253" software="ro"/>
        </Register>
        <Register name="node">
            <Field name="guid"  width="24" reset="24'h12abcd" software="rw" hardware="ro"/>
            <Field name="id"  width="16" reset="16'h0" software="rw" hardware="ro"/>
            <Field name="vpids"  width="16" reset="10" software="ro"/>
        </Register>
        <Register name="management_sw">
            <Field name="cfg_ip"  width="32" reset="32'h0" software="rw"/>
            <Field name="enum_cnt"  width="8" reset="8'h0" software="rw"/>
            <Field name="cfg_count"  width="8" reset="8'h0" software="rw"/>
            <Field name="backend"  width="1" reset="1'h0" software="rw"/>
        </Register>
        <Register name="ip_addresses">
            <Field name="primary_ip_address"  width="32" reset="32'h0" software="rw"/>
            <Field name="extoll_ip_address"  width="32" reset="32'h0" software="rw"/>
        </Register>
        <Register name="mgt_ip_addresses">
            <Field name="primary_mgt_ip_address"  width="32" reset="32'h0" software="rw"/>
            <Field name="extoll_mgt_ip_address"  width="32" reset="32'h0" software="rw"/>
        </Register>
        <Register name="tsc">
            <Field name="tsc"  width="48" reset="0" software="rw" hardware="rw"/>
        </Register>
        <Register name="tsc_global_load_value">
            <Field name="tsc_data"  width="48" reset="0" software="rw" hardware="ro"/>
        </Register>
        <Register name="scratchpad_0">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_1">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_2">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_3">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_4">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_5">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_6">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="scratchpad_7">
            <Field name="data"  width="64" reset="64'h0" software="rw"/>
        </Register>
        <Register name="tsc_global_load_enable">
            <Field name="tsc_load_en_irq0"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="tsc_load_en_irq1"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="tsc_load_en_irq2"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="tsc_load_en_irq3"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="global_irq_reinit_en0"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="global_irq_reinit_en1"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="global_irq_reinit_en2"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="global_irq_reinit_en3"  width="1" reset="0" software="rw" hardware="ro"/>
        </Register>
        <Register name="timer_interrupt">
            <Field name="timer_interrupt_period"  width="48" reset="0" software="rw" hardware="ro"/>
            <Field name="timer_interrupt_enable"  width="1" reset="0" software="rw" hardware="rw"/>
            <Field name="timer_interrupt_one_shot"  width="1" reset="0" software="rw" hardware="ro"/>
            <Field name="timer_interrupt_toggle"  width="1" reset="0" software="ro" hardware="wo"/>
        </Register>
    </RegisterFile>




# Usage

[TODO] Usage flow of RFG

- Write the register file scripts
- Write a top script with top registerfile definition, and add in it (for example by sourcing other scripts) the actual definition
- Call on the generators to create the outputs

# Porting From RFS XML

As mentioned in previous chapter, the RFS XML files contains some `<repeat>` elements to modelize loops, and some C style `#ifdef ... #else ... #endif` to define if-else control structures.

Using the new syntax, the user can simply call normal TCL control structures, makind the need of such special modelisations obsolete

## Repeat 

RFS:

    <repeat loop="8">
        <reg64 name="test"></reg64>
    </repeat>

RFG:
    
    ## Pure basic TCL
    for {set i 0} {$i < 8} {incr $i} {

        register "test_$i" {

        }

    }

    ## Alternative: This ::repeat function is not standard TCL, but convenient because the for loop syntax is not so great
    ::repeat 8 {

        # $i variable is implicit, and contains the actual offset
        register "test_$i" {

        }
    }

## #ifdef .. #else .. #endif

RFS:
    

    <reg64 name="tsc_global_load_value" desc="This register specifies the value the TSC register will be loaded with, in case of an global interrupt.">
    #ifdef ASIC
            <hwreg name="tsc_data" width="64" sw="rw" hw="ro"/>
    #else
            <hwreg name="tsc_data" width="48" sw="rw" hw="ro"/>
    #endif
    </reg64>

RFG:

    register "tsc_global_load_value" {
 
        field "tsc_data" {

            description "This register specifies the value the TSC register will be loaded with, in case of an global interrupt."

            ## Test if a variable is defined using info exists command
            if {[info exists ASIC]} {
                width 64
            } else {
                width 48
            }

            software r w 
            hardware r
            reset    0

        }

    }



## Automatic Conversion

Considering that the RFS format is an XML tree, and that the new RFG scripts are also structured like a tree, it is possible to transform a RFS XML tree to a RFG code tree.

This is easily achievable using a XML Transformation Stylesheet (XSLT)

### RFS XML preparation

Before conversion, the user MUST clean the RFS XML, because a very few things a preventing correct XML parsing:

- `reset=DEFINE` must be converted to `reset="DEFINE"`

### Usage 
    
    // Usage:
    $ rfs_to_rfg <standard Input RFS> <standard Output RFG>

    // Input file to output file :
    $ rfs_to_rfg < info_rf.xml > info_rf.rfg

    // Standard input paste :
    $ rfs_to_rfg

      paste some RFS here
      CTRL + D to send End of File

      The RFG Script gets written to stdout

### Supported Constructs

- `<repeat>` -> ::repeat
- #ifdef .. #else .. #endif ->  if {} else {}
- reset="DEFINE" -> reset $DEFINE

