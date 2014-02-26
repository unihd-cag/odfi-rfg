source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm

catch {source counter.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/counter_RF.v"

$veriloggenerator produce $destinationFile