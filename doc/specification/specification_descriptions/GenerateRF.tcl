package require osys::rfg 1.0.0
package require osys::generator 1.0.0

readRF [lindex $argv 0]
    
generator verilog {
    destinationPath "verilog/"
    options {
        reset sync
    }
}
