source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm

catch {source absAddrRAM.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/absAddrRAM.v"

$veriloggenerator produce $destinationFile