#!/usr/bin/env tclsh 


package require osys::rfg::generator::rfsbackport
package require odfi::files


## String convert
set res [osys::rfg::generator::rfsbackport::convertFileToRFS ./rfs_backport.rf]

odfi::files::writeToFile ./rfs_backport.xml $res

## File to file 
osys::rfg::generator::rfsbackport::convertFileToRFS ./rfs_backport.rf ./rfs_backport2.xml
