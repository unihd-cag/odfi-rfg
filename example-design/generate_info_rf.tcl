source ../tcl/rfg.tm
source ../verilog-generator/VerilogGenerator.tm

set NUM_VPIDS 42

catch {source info_rf.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationRF "design_files/info_rf.v"
set destinationWrapper "design_files/RF_wrapper.v"

$veriloggenerator produce_RegisterFile $destinationRF
$veriloggenerator produce_RF_Wrapper $destinationWrapper