itcl::body Egenerator::getEnclosingRF {instance} {
    if {[[$instance parent] isa osys::rfg::RegisterFile]} {
        return [$instance parent]
    } else {
        return [getEnclosingRF [$instance parent]]
    }
}

itcl::body Egenerator::getNextGroupsName {instance} {
    if {[[$instance parent] isa osys::rfg::Group]} {
        if {[[$instance parent] isa osys::rfg::RegisterFile]} {
            return ""
        } else {
            return "[getNextGroupsName [$instance parent]][[$instance parent] name]_"
        }
    } else {
        return [getNextGroupsName [$instance parent]]
    }
}

itcl::body Egenerator::getGroupsName {instance} {
    if {[[$instance parent] isa osys::rfg::Group]} {
        if {[[$instance parent] isa osys::rfg::RegisterFile]} {
            return ""
        } else {
            return " [getNextGroupsName [$instance parent]][[$instance parent] name]"
        }
    } else {
        return [getGroupsName [$instance parent]]
    }
}

itcl::body Egenerator::produceSwRfModel args {
    set out [odfi::common::newStringChannel]

    odfi::common::println "<'" $out
    odfi::common::println "reg_file_def [string toupper [$registerFile name]];" $out
    odfi::common::println "" $out

    $registerFile walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
			odfi::common::println "ram_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] [$it width] [$it depth] {" $out
            odfi::common::println "};" $out
            odfi::common::println "" $out
	    } elseif {[$it isa osys::rfg::Register]} {
            odfi::common::println "reg_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]] {" $out
            $it onEachField {
            odfi::common::println "    [$it name] : uint(bits:[$it width]) : [$it reset];" $out
            }
            odfi::common::println "};" $out
            odfi::common::println "" $out
        } elseif {[$it isa osys::rfg::Group]} {
            if {[$it isa osys::rfg::RegisterFile]} {
                odfi::common::println "reg_file_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it] 0x[format %x [$it getAttributeValue software.osys::rfg::relative_address]];" $out
            odfi::common::println "" $out
            } else {
                odfi::common::println "group_def [string toupper [$it name]] [string toupper [[getEnclosingRF $it] name]][getGroupsName $it];" $out
                odfi::common::println "" $out
            }
        }
        return true
    }

    odfi::common::println "'>" $out

    flush $out
    set res [read $out]
    close $out
    return $res
}
