source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm
source ../../../tcl/address-hierarchical/address-hierarchical.tm

catch {source absAddrRAM.rf} result

puts $result

osys::rfg::address::hierarchical::calculate $result
osys::rfg::address::hierarchical::printTable $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/absAddrRAM.v"

$veriloggenerator produce_RegisterFile $destinationFile