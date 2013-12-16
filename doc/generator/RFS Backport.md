RFS Backport
=========================

To ease progressive porting to RFG whilst no Verilog generator is available, 
there is a RFS backport generate that produces an old XML format.

This is the RFS backport flow:

- Write/Convert the Register File definitions to the new RFG format
- Prepare/Use the old RFS flow as usual (bash script)
    - Include the RFG registerfiles as XML files, even if those don't already exist
- Write a TCL script driving the Register File Generation
    - First use RFG API to convert the RFG format register files to old rfs ``<regroot>...`` format, and write out the XML files where the old format would expect them
    - Run RFS using bash script
    - Use RFG API to convert Annotated XML back to RFG
    - Run some new Generators like new XML format or Documentation

# Driving Script example

First Source the ODFI libraries:

[http://webserver.ziti.uni-heidelberg.de/wiki/index.php/ODFI_Tools](http://webserver.ziti.uni-heidelberg.de/wiki/index.php/ODFI_Tools)




~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/usr/bin/env tclsh

package require osys::rfg::generator::rfsbackport
package require osys::rfg::xmlgenerator
package require odfi::files

################################
## Convert RFG back to RFS
##############################

## Declare the variables that are needed, for example the converted Defines
## Example, if HMC_NUM_LANES was used as a define, it gets converted to $HMC_

## Do this multiple multiple times if multiple RFG registerfiles must be converted back
osys::rfg::generator::rfsbackport::convertFileToRFS /path/to/rfg/file.rf /path/to/rfs/file.xml


################################
## Run RFS
################################

## If this driving script is located in the same folder as the RFS generate bash script
catch {puts [exec ./generate.sh]}


################################
## Read RFS output
################################

## If RFS output is located under output/extoll_rf.anot.xml

## Convert to RFG
set rfScript [exec rfs_to_rfg output/extoll_rf.anot.xml]

## Write result to file, this is not required, only intereseting to see a large output in RFG format
odfi::files::writeToFile ./extoll_rf.rf $rfScript

## Read RFS output back
set registerFile [eval $rfScript]

###################################
## Call Some generators
###################################

## Generate HTML Doc
#################
set htmlGenerator [osys::rfg::getGenerator HTMLBrowser $registerFile]

$htmlGenerator produceToFile  ./extoll_rf.html

## Generate XML 
########################

set xmlgenerator [::new osys::rfg::xmlgenerator::XMLGenerator #auto $registerFile]
set res [$xmlgenerator produce]

odfi::files::writeToFile ./extoll_rf.xml $res


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
