package provide osys::rfg::veriloggenerator 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::files 1.0.0
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

        public method produce_RegisterFile destinationFile {

        	## Read and parse Verilog Template
            set verilog [odfi::closures::embeddedTclFromFileToString $osys::rfg::veriloggenerator::location/registerfile_template.v]
            odfi::files::writeToFile $destinationFile $verilog
        }

        public method produce_RF_Wrapper destinationFile {

            ## Read and parse Verilog Template
            set verilog [odfi::closures::embeddedTclFromFileToString $osys::rfg::veriloggenerator::location/RF_wrapper_template.v]
            odfi::files::writeToFile $destinationFile $verilog
        }
	}

}