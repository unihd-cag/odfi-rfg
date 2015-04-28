package require osys::rfg
package require osys::generator

readRF [lindex $argv 0]
    
generator verilog {

    destinationPath "verilog/"

    options {
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

generator wrapper {

    destinationPath "verilog/"

}
