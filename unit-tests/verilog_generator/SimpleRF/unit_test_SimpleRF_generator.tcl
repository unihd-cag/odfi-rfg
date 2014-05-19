source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm
source ../../../tcl/address-hierarchical/address-hierarchical.tm

catch {source SimpleRF.rf} result

puts $result

osys::rfg::address::hierarchical::calculate $result
osys::rfg::address::hierarchical::printTable $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/SimpleRF.v"

$veriloggenerator produce_RegisterFile $destinationFile

catch {exec sh "iverilog_run.sh"} result
if {$result != "VCD info: dumpfile SimpleRF.vcd opened for output."} {
	error "Test failed result of the iverilog_run was:\n $result"
} else {
	puts "Test sucessfull..."
}