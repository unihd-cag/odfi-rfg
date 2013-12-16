package provide osys::rfg::generator::htmlbrowser 1.0.0
package require osys::rfg
package require Itcl 3.4
package require odfi::common
package require odfi::list 2.0.0

#package require odfi::ewww::webdata 1.0.0


namespace eval osys::rfg::generator::htmlbrowser {

    variable location [file dirname [file normalize [info script]]]

    itcl::class HTMLBrowser {

        public variable registerFile 

        constructor cRegisterFile {
            #########
            ## Init
            #########
            set registerFile $cRegisterFile
        }

        public method copyDependenciesTo destination {

            odfi::common::copy $osys::rfg::generator::htmlbrowser::location $destination/bs/ *.css
            odfi::common::copy $osys::rfg::generator::htmlbrowser::location $destination/bs/ *.js
            odfi::common::copy $osys::rfg::generator::htmlbrowser::location/fonts $destination/fonts *

        }

        public method produceToFile destinationFile {

            set html [odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/htmlbrowser_template.html]
            odfi::files::writeToFile $destinationFile $html
            copyDependenciesTo [file dirname $destinationFile]

        }

        public method produce args {


            ## Create Special Stream 
            #set out [odfi::common::newStringChannel]

            odfi::closures::embeddedTclFromFileToString $osys::rfg::generator::htmlbrowser::location/htmlbrowser_template.html

        }


    }







}
