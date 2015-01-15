package require osys::rfg 1.0.0
package require osys::generator 1.0.0

readRF "ExampleRF.rf"
    
generator verilog {

    destinationPath "verilog/"

    extra {
        reset async
    }

}

generator htmlbrowser {

    destinationPath "doc/"

}

generator xmlgenerator {

    destinationPath "xml/"

}

generator rfsbackport {

    destinationPath "xml/"

}

generator rfgheader {

    destinationPath "verilog_header/"

}
