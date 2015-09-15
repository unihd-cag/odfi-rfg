itcl::body Egenerator::produceHwTb args {
    set out [odfi::common::newStringChannel]
    set signalList {}

    odfi::common::println "module tb_top;\n" $out
    odfi::common::println "\tlogic clk;" $out
    odfi::common::println "\tlogic res_n;\n" $out
    odfi::common::println "\tinitial begin" $out
    odfi::common::println "\t\tclk <= 1'b0;" $out
    odfi::common::println "\t\tres_n <= 1'b0;" $out
    odfi::common::println "\t\t#31ns;" $out
    odfi::common::println "\t\tres_n <= 1'b1;" $out
    odfi::common::println "\t\t#1us;" $out
    odfi::common::println "\tend\n" $out
    odfi::common::println "\talways #5ns clk <= !clk;\n" $out
    odfi::common::println "//--------------------------------------------------" $out
    odfi::common::println "//-- DUT -------------------------------------------" $out
    odfi::common::println "//--------------------------------------------------\n" $out
    odfi::common::println "\tlogic address;" $out
    odfi::common::println "\tlogic read_data;" $out
    odfi::common::println "\tlogic read_en;" $out
    odfi::common::println "\tlogic write_en;" $out
    odfi::common::println "\tlogic write_data;" $out
    odfi::common::println "\tlogic invalid_address;" $out
    odfi::common::println "\tlogic access_complete;\n" $out
    $registerFile walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            $it onAttributes {hardware.osys::rfg::rw} {
                odfi::common::println "\tlogic [getName $it]_addr;" $out
                odfi::common::println "\tlogic [getName $it]_ren;" $out
                odfi::common::println "\tlogic [getName $it]_rdata;" $out
                odfi::common::println "\tlogic [getName $it]_wen;" $out
                odfi::common::println "\tlogic [getName $it]_wdata;" $out
            }
            $it onAttributes {hardware.osys::rfg::ro} {
                odfi::common::println "\tlogic [getName $it]_addr;" $out
                odfi::common::println "\tlogic [getName $it]_ren;" $out
                odfi::common::println "\tlogic [getName $it]_rdata;" $out
            }
            $it onAttributes {hardware.osys::rfg::wo} {
                odfi::common::println "\tlogic [getName $it]_addr;" $out
                odfi::common::println "\tlogic [getName $it]_wen;" $out
                odfi::common::println "\tlogic [getName $it]_wdata;" $out
            }
            odfi::common::println "" $out
        } elseif {[$it isa osys::rfg::Register]} {
            $it onEachField {
                if {[$it name] != "Reserved"} {
                    if {![$it hasAttribute hardware.osys::rfg::no_wen] && ([$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo])} {
                        odfi::common::println "\tlogic [getName $it]_wen;" $out
                    }
                    if {[$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo]} {
                        odfi::common::println "\tlogic [getName $it]_next;" $out
                    }
                    if {[$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::ro]} {
                        odfi::common::println "\tlogic [getName $it];" $out
                    }
                    $it onAttributes {hardware.osys::rfg::software_written} {
                        odfi::common::println "\tlogic [getName $it]_written;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::clear} {
                        odfi::common::println "\tlogic [getName $it]_clear;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::counter} {
                        odfi::common::println "\tlogic [getName $it]_countup;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::changed} {
                        odfi::common::println "\tlogic [getName $it]_changed;" $out
                    }
                    odfi::common::println "" $out
                }
            }
        }
        return true
    }

	odfi::common::println "\t[$registerFile name] [$registerFile name]_I (" $out
	lappend signalList "\t\t.res_n(res_n)"
	lappend signalList "\t\t.clk(clk)"
	lappend signalList "\t\t.address(address)"
	lappend signalList "\t\t.read_data(read_data)"
	lappend signalList "\t\t.invalid_address(invalid_address)"
	lappend signalList "\t\t.access_complete(access_complete)"
	lappend signalList "\t\t.read_en(read_en)"
	lappend signalList "\t\t.write_en(write_en)"
	lappend signalList "\t\t.write_data(write_data)"

    odfi::common::println [join $signalList ",\n"] $out
    odfi::common::println "\t);\n" $out
	odfi::common::println "endmodule : tb_top" $out
    flush $out
    set res [read $out]
    close $out
    return $res
}
