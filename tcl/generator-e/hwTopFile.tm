itcl::body Egenerator::produceHwTopFile args {
    set out [odfi::common::newStringChannel]

    odfi::common::println "<'" $out
    odfi::common::println "import ../e/rfg_hw_inf_top.e;\n" $out
    odfi::common::println "extend sys {" $out

    $registerFile walkDepthFirst {
        if {[$it isa osys::rfg::RamBlock]} {
            odfi::common::println "\t[getName $it]_env : rfg_hw_inf_env_u is instance;" $out
            odfi::common::println "\t\tkeep soft [getName $it]_env.smp.hdl_path() == \"~/tb_top\";" $out
            $it onAttributes {hardware.osys::rfg::rw} {
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(RAM rfg_hw_inf_signal_map_u).addr_p.hdl_path() == \"[getName $it]_addr\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'ren RAM rfg_hw_inf_signal_map_u).ren_p.hdl_path() == \"[getName $it]_ren\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'rdata RAM rfg_hw_inf_signal_map_u).rdata_p.hdl_path() == \"[getName $it]_rdata\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'wen rfg_hw_inf_signal_map_u).wen_p.hdl_path() == \"[getName $it]_wen\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'wdata RAM rfg_hw_inf_signal_map_u).wdata_p.hdl_path() == \"[getName $it]_wdata\";" $out
            }
            $it onAttributes {hardware.osys::rfg::ro} {
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(RAM rfg_hw_inf_signal_map_u).addr_p.hdl_path() == \"[getName $it]_addr\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'ren RAM rfg_hw_inf_signal_map_u).ren_p.hdl_path() == \"[getName $it]_ren\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'rdata RAM rfg_hw_inf_signal_map_u).rdata_p.hdl_path() == \"[getName $it]_rdata\";" $out
            }
            $it onAttributes {hardware.osys::rfg::wo} {
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(RAM rfg_hw_inf_signal_map_u).addr_p.hdl_path() == \"[getName $it]_addr\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'wen rfg_hw_inf_signal_map_u).wen_p.hdl_path() == \"[getName $it]_wen\";" $out
                odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'wdata RAM rfg_hw_inf_signal_map_u).wdata_p.hdl_path() == \"[getName $it]_wdata\";" $out
            }
            odfi::common::println "\t\tkeep [getName $it]_env.cfg == read_only([getName $it]_cfg);" $out
            odfi::common::println "\t[getName $it]_cfg : rfg_hw_inf_config_s;" $out
            odfi::common::println "\t\tkeep cfg.inst_kind == RAM;" $out
            odfi::common::println "\t\tkeep cfg.inst_name == \"[getName $it]\";" $out
            $it onAttributes {hardware.osys::rfg::rw} {
                odfi::common::println "\t\tkeep cfg.rw_permission == RW;" $out
            }
            $it onAttributes {hardware.osys::rfg::ro} {
                odfi::common::println "\t\tkeep cfg.rw_permission == RO;" $out
            }
            $it onAttributes {hardware.osys::rfg::wo} {
                odfi::common::println "\t\tkeep cfg.rw_permission == WO;" $out
            }
            odfi::common::println "" $out
        } elseif {[$it isa osys::rfg::Register]} {
            $it onEachField {
                if {[$it name] != "Reserved"} {
                    odfi::common::println "\t[getName $it]_env : rfg_hw_inf_env_u is instance;" $out
                    odfi::common::println "\t\tkeep soft [getName $it]_env.smp.hdl_path() == \"~/tb_top\";" $out
                    if {![$it hasAttribute hardware.osys::rfg::no_wen] && ([$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo])} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'wen rfg_hw_inf_signal_map_u).wen_p.hdl_path() == \"[getName $it]_wen\";" $out
                    }
                    if {[$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo]} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'next REG_FIELD rfg_hw_inf_signal_map_u).next_p.hdl_path() == \"[getName $it]_next\";" $out
                    }
                    if {[$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::ro]} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'data REG_FIELD rfg_hw_inf_signal_map_u).data_p.hdl_path() == \"[getName $it]\";" $out
                    }
                    $it onAttributes {hardware.osys::rfg::software_written} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'written REG_FIELD rfg_hw_inf_signal_map_u).written_p.hdl_path() == \"[getName $it]_written\";" $out
                    }
                    $it onAttributes {hardware.osys::rfg::hclear} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'hclear REG_FIELD rfg_hw_inf_signal_map_u).hclear_p.hdl_path() == \"[getName $it]_hclear\";" $out
                    }
                    $it onAttributes {hardware.osys::rfg::counter} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'countup REG_FIELD rfg_hw_inf_signal_map_u).countup_p.hdl_path() == \"[getName $it]_countup\";" $out
                    }
                    $it onAttributes {hardware.osys::rfg::changed} {
                        odfi::common::println "\t\tkeep [getName $it]_env.smp.as_a(TRUE'changed REG_FIELD rfg_hw_inf_signal_map_u).changed_p.hdl_path() == \"[getName $it]_changed\";" $out
                    }
                    odfi::common::println "\t\tkeep [getName $it]_env.cfg == read_only([getName $it]_cfg);" $out
                    odfi::common::println "\t[getName $it]_cfg : rfg_hw_inf_config_s;" $out
                    odfi::common::println "\t\tkeep cfg.inst_kind == REG_FIELD;" $out
                    odfi::common::println "\t\tkeep cfg.inst_name == \"[getName $it]\";" $out
                    $it onAttributes {hardware.osys::rfg::rw} {
                        odfi::common::println "\t\tkeep cfg.rw_permission == RW;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::ro} {
                        odfi::common::println "\t\tkeep cfg.rw_permission == RO;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::wo} {
                        odfi::common::println "\t\tkeep cfg.rw_permission == WO;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::no_wen} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).no_wen == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::software_written} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).software_written == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::sticky} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).sticky == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::clear} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).clear == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::counter} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).counter == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::rreinit_source} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).rreinit_source == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::rreinit} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).rreinit == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::edge_trigger} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).edge_trigger == TRUE;" $out
                    }
                    $it onAttributes {hardware.osys::rfg::changed} {
                        odfi::common::println "\t\tkeep cfg.as_a(REG_FIELD rfg_hw_inf_config_s).changed == TRUE;" $out
                    }
                    odfi::common::println "" $out
                }
            }
        }

        return true
    }
    
    odfi::common::println "\tsetup() is also {" $out
    odfi::common::println "\t\tset_config(ies, sync_reset, pre_run);" $out
    odfi::common::println "\t\tset_config(run, tick_max, 100000);" $out
    odfi::common::println "\t\tset_config(cover, write_model, ucm);" $out
    odfi::common::println "\t\tset_config(cover, mode, on);" $out
    odfi::common::println "\t};" $out
    odfi::common::println "};" $out
    odfi::common::println "'>" $out

    flush $out
    set res [read $out]
    close $out
    return $res
}
