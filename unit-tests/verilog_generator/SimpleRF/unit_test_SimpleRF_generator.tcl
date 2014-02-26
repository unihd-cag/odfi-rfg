source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm

catch {source SimpleRF.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/SimpleRF.v"

$veriloggenerator produce $destinationFile