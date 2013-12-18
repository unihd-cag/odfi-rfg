source ../../tcl/rfg.tm
source ../../verilog-generator/VerilogGenerator.tm

catch {source regfile.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/verilog_output.v"

$veriloggenerator produce $destinationFile