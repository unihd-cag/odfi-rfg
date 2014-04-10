source ../tcl/rfg.tm
source ../verilog-generator/VerilogGenerator.tm

set NUM_VPIDS 42

catch {source info_rf.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "design_files/info_rf.v"

$veriloggenerator produce $destinationFile