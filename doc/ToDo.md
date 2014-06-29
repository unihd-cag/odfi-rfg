## ToDo:

### RAMs

- different RAMs
- RAM read/write rights
- external RAM

### Verilog Generator 

- create ASIC dependet hardware on generation and not with defines in verilog
- Trigger
- internal RFs
- registerfile_template Registerfunction function divide by counter register and "normal" register
- aligner are not working
	- add aligner as class in the rfg.tm
	- add aligner in the addressing scheme
- rewrite checker
- add hw_clear in RF Wrapper

### Unit Tests 

- add unit-test for RF_Wrapper
- add unit-test for RF.rf
- unit-test enviroment

### HTML Generator 

- html-generator rreinit source register not working 

### rfs_to_rfg Tool 

- hw_clr correct name in old script
- sw_write_clr correct name in old script
- te ? in ht3_rf.xml
- aligner to bits?
- external RAM 
- check correct working for empty elements
- check conversion for ramBlocks

### Generation Script 

- modify rfg script for simple usage
	- test a huge registerfile with the example script

### Documentation/ Presentation

- write presentation
- write Getting Started and HowTo's
- find place for this and the project (github.io?, redmine) 
- clean github repository
- add V0.8 for RFG to odfi-tools