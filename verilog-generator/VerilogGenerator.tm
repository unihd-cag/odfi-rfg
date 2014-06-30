package provide osys::rfg::veriloggenerator 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::files
package require odfi::list 2.0.0

namespace eval osys::rfg::veriloggenerator {

    variable location [file dirname [file normalize [info script]]]
	
	itcl::class VerilogGenerator {
		
		public variable registerFile 

		constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

        public method produce destinationFile {

        	## Read and parse Verilog Template
            set verilog [odfi::closures::embeddedTclFromFileToString $osys::rfg::veriloggenerator::location/registerfile_template.v]
            odfi::files::writeToFile $destinationFile $verilog
        }
	}

}