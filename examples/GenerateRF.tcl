package require osys::rfg 1.0.0
package require osys::generator 1.0.0

readRF "$argv"
    
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

generator egenerator {

    destinationPath "e/"

}

generator sv {

    destinationPath "sv/"

}
