source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm

catch {source testing.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/testing.v"

$veriloggenerator produce $destinationFile