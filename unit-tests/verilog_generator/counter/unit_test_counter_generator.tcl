source ../../../tcl/rfg.tm
source ../../../verilog-generator/VerilogGenerator.tm

catch {source counter.rf} result

puts $result

set veriloggenerator [::new osys::rfg::veriloggenerator::VerilogGenerator #auto $result]

set destinationFile "compare_data/counter_RF.v"

$veriloggenerator produce_RegisterFile $destinationFile

catch {exec sh "iverilog_run.sh"} result
if {$result != "VCD info: dumpfile counter_RF.vcd opened for output."} {
	error "Test failed result of the iverilog_run was:\n $result"
} else {
	puts "Test sucessfull..."
}