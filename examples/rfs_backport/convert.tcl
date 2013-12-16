#!/usr/bin/env tclsh 


package require osys::rfg::generator::rfsbackport
package require odfi::files



set res [osys::rfg::generator::rfsbackport::convertFileToRFS ./rfs_backport.rf]

odfi::files::writeToFile ./rfs_backport.xml $res
