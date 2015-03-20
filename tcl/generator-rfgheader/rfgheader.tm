## RFG Register File Generator
## Copyright (C) 2014  University of Heidelberg - Computer Architecture Group
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

package provide osys::rfg::generator::rfgheader 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0
package require odfi::files

package require odfi::ewww::webdata 1.0.0

# function to getRFmaxWidth
proc getRFmaxWidth {registerfile} {
    set maxwidth 0
    ::puts "RegisterFile: $registerfile"
    $registerfile walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            if {$maxwidth < [$it width]} {
                set maxwidth [$it width]
            }
        }
        if {[$it isa osys::rfg::Register]} {
            set tmp 0
            $it onEachField {
                incr tmp [$it width]
            }
            if {$maxwidth < $tmp} {
                set maxwidth $tmp
            }
        }
        return true
    }
    return $maxwidth
} 

namespace eval osys::rfg::generator::rfgheader {

    ##############################
    ## Implementation of generator
    ##############################
    itcl::class Rfgheader {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

        public method ld  x {
            return [expr {int(ceil(log($x)/[expr log(2)]))}]
        }

        # function to get the address Bits for the register file 
        public method getRFsize {registerfile} {
            set size 0
            set offset [$registerfile getAttributeValue software.osys::rfg::absolute_address]
            $registerfile walk {
                if {![$item isa osys::rfg::Group]} {
                    if {[string is integer [$item getAttributeValue software.osys::rfg::absolute_address]]} {
                        if {$size <= [$item getAttributeValue software.osys::rfg::absolute_address]} {
                            set size [expr [$item getAttributeValue software.osys::rfg::absolute_address]+[$item getAttributeValue software.osys::rfg::size]]
                        }
                    }
                }
            }
            return [expr $size - $offset]
        }

        public method getAddrBits {registerfile} {
            return [ld [getRFsize $registerfile]]
        }

        public method produce {destinationPath {generator ""}} {

            file mkdir $destinationPath 
            puts "Rfgheader processing $registerFile > ${destinationPath}[$registerFile name].h"
            
            ## Create Special Stream 
            set out [odfi::common::newStringChannel]
            
            odfi::common::println "`ifndef RFS_DEFINES" $out
            odfi::common::println "`define RFS_DEFINES" $out
            odfi::common::println "`define RFS_DATA_WIDTH [getRFmaxWidth $registerFile]" $out
            
            if {[expr [getAddrBits $registerFile]-3] == 0} {
                odfi::common::println "`define RFS_[string toupper [$registerFile name]]_AWIDTH 1" $out
            } else {
                odfi::common::println "`define RFS_[string toupper [$registerFile name]]_AWIDTH [expr [getAddrBits $registerFile]-3]" $out
            }
            
            odfi::common::println "`define RFS_[string toupper [$registerFile name]]_RWIDTH [getRFmaxWidth $registerFile]" $out
            odfi::common::println "`define RFS_[string toupper [$registerFile name]]_WWIDTH [getRFmaxWidth $registerFile]" $out
            
            $registerFile walkDepthFirst {

                if {[$it isa osys::rfg::RegisterFile]} {
                    if {[expr [getAddrBits $it]-3] == 0} {
                        odfi::common::println "`define RFS_[string toupper [$it name]]_AWIDTH 1" $out
                    } else {
                        odfi::common::println "`define RFS_[string toupper [$it name]]_AWIDTH [expr [getAddrBits $it]-3]" $out
                    }
                    odfi::common::println "`define RFS_[string toupper [$it name]]_RWIDTH [getRFmaxWidth $it]" $out
                    odfi::common::println "`define RFS_[string toupper [$it name]]_WWIDTH [getRFmaxWidth $it]" $out
                }
                return true
            }
            
            odfi::common::println "`endif /* RFS_DEFINES */" $out

            flush $out
            set res [read $out]
            close $out
            odfi::files::writeToFile ${destinationPath}[$registerFile name].h $res
        }
    }
}
