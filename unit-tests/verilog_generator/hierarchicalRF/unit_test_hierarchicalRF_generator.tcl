package require osys::rfg 1.0.0
package require osys::generator 1.0.0

readRF hierarchicalRF.rf

generator verilog {
    destinationPath "compare_data/"
}

catch {exec sh "iverilog_run.sh"} result
if {$result != "VCD info: dumpfile hierarchicalRF.vcd opened for output."} {
	error "Test failed result of the iverilog_run was:\n $result"
} else {
	puts "Test sucessfull..."
}
