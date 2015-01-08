package require osys::rfg 1.0.0
package require osys::generator 1.0.0

    
osys::generator::readRF ExampleRF.rf
    
osys::generator::generator verilog {

    destinationFile "/verilog/output.v"

}


