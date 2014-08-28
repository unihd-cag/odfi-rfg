
package ifneeded osys::rfg 1.0.0  [list source [file join $dir rfg.tm]]

package ifneeded osys::rfg::generator::xmlgenerator 1.0.0 [list source [file join $dir generator-xml XMLGenerator.tm]]
package ifneeded osys::rfg::generator::htmlbrowser 1.0.0 [list source [file join $dir generator-htmlbrowser htmlbrowser.tm]]
package ifneeded osys::rfg::generator::rfsbackport 1.0.0 [list source [file join $dir generator-rfsbackport rfsbackport.tm]]
package ifneeded osys::rfg::generator::veriloggenerator 1.0.0 [list source [file join $dir generator-verilog VerilogGenerator.tm]]
package ifneeded osys::rfg::generator::rfgheader 1.0.0 [list source [file join $dir generator-rfgheader rfgheader.tm]]

package ifneeded osys::rfg::address::linear 1.0.0        [list source [file join $dir address-linear address-linear.tm]]
package ifneeded osys::rfg::address::hierarchical 1.0.0   [list source [file join $dir address-hierarchical address-hierarchical.tm]]
package ifneeded osys::rfg::address::hierarchical-full 1.0.0   [list source [file join $dir address-hierarchical-full address-hierarchical-full.tm]]
package ifneeded HelperFunctions 1.0.0 [list source [file join $dir generator-verilog HelperFunctions.tm]]