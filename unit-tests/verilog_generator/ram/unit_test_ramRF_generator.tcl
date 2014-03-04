source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm

catch {source ramRF.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/ramRF.v"

$veriloggenerator produce $destinationFile