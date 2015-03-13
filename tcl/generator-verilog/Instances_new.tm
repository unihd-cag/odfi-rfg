# write counter instance
odfi::closures::oproc writeCounterModule {register field} {
	odfi::common::println "" $resolve
	odfi::common::println "counter48 #(" $resolve
	odfi::common::println "	.DATASIZE([$field width])" $resolve
	odfi::common::println ") [getName $register]_I (" $resolve
	odfi::common::println "	.clk(clk)," $resolve
	odfi::common::println "	.res_n(res_n)," $resolve
	odfi::common::println "	.increment([getName $field]_countup)," $resolve
	if {[$field hasAttribute hardware.osys::rfg::rw] || [$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw] || [$field hasAttribute software.osys::rfg::wo]} {
		odfi::common::println "	.load([getName $field]_load_value)," $resolve
	} else {
		odfi::common::println " .load([$field width]'b0)," $resolve
	}
	$field onAttributes {hardware.osys::rfg::rreinit} {
		if {[$field hasAttribute hardware.osys::rfg::rw] || [$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw] || [$field hasAttribute software.osys::rfg::wo]} {
			odfi::common::println "	.load_enable(rreinit || [getName $field]_load_enable)," $resolve
		} else {
			odfi::common::println "	.load_enable(rreinit)," $resolve
		}				
	} otherwise {
		if {[$field hasAttribute hardware.osys::rfg::rw] || [$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw] || [$field hasAttribute software.osys::rfg::wo]} {
			odfi::common::println "	.load_enable([getName $field]_load_enable)," $resolve
		} else {
			odfi::common::println "	.load_enable(1'b0)," $resolve
		}
		
	}
	odfi::common::println "	.value([getName $field])" $resolve
	odfi::common::println ");" $resolve
	odfi::common::println "" $resolve
}

# write Ram Instance
odfi::closures::oproc writeRamModule {ramBlock} {
	
	## 2rw 2w1r
	if {([$ramBlock hasAttribute hardware.osys::rfg::rw] && [$ramBlock hasAttribute software.osys::rfg::rw]) ||\
		([$ramBlock hasAttribute hardware.osys::rfg::rw] && [$ramBlock hasAttribute software.osys::rfg::wo]) ||\
		([$ramBlock hasAttribute hardware.osys::rfg::wo] && [$ramBlock hasAttribute software.osys::rfg::rw])} {
		odfi::common::println "" $resolve
	    odfi::common::println "ram_2rw_1c #(" $resolve
		odfi::common::println " .DATASIZE([$ramBlock width])," $resolve
		odfi::common::println " .ADDRSIZE([ld [$ramBlock depth]])," $resolve
		odfi::common::println "	.PIPELINED(0)" $resolve
		odfi::common::println ") [getName $ramBlock] (" $resolve
		odfi::common::println "	.clk(clk)," $resolve
		$ramBlock onAttributes {software.osys::rfg::wo} {
			odfi::common::println " .wen_a([getName $ramBlock]_rf_wen)," $resolve
			odfi::common::println "	.ren_a(1'b0)," $resolve
			odfi::common::println "	.addr_a([getName $ramBlock]_rf_addr)," $resolve
			odfi::common::println "	.wdata_a([getName $ramBlock]_rf_wdata)," $resolve
			odfi::common::println "	.wen_b([getName $ramBlock]_wen)," $resolve
			odfi::common::println "	.ren_b([getName $ramBlock]_ren)," $resolve 
			odfi::common::println "	.addr_b([getName $ramBlock]_addr)," $resolve
			odfi::common::println "	.wdata_b([getName $ramBlock]_wdata)," $resolve
			odfi::common::println "	.rdata_b([getName $ramBlock]_rdata)" $resolve
			odfi::common::println ");" $resolve
			odfi::common::println "" $resolve
		} otherwise {
			$ramBlock onAttributes {hardware.osys::rfg::wo} {
				odfi::common::println "	.wen_a([getName $ramBlock]_rf_wen)," $resolve
				odfi::common::println "	.ren_a([getName $ramBlock]_rf_ren)," $resolve
				odfi::common::println "	.addr_a([getName $ramBlock]_rf_addr)," $resolve
				odfi::common::println "	.wdata_a([getName $ramBlock]_rf_wdata)," $resolve
				odfi::common::println "	.rdata_a([getName $ramBlock]_rf_rdata)," $resolve
				odfi::common::println "	.wen_b([getName $ramBlock]_wen)," $resolve
				odfi::common::println "	.ren_b(1'b0)," $resolve
				odfi::common::println "	.addr_b([getName $ramBlock]_addr)," $resolve
				odfi::common::println "	.wdata_b([getName $ramBlock]_wdata)" $resolve
				odfi::common::println ");" $resolve
				odfi::common::println ""
			} otherwise {
				odfi::common::println "	.wen_a([getName $ramBlock]_rf_wen)," $resolve
				odfi::common::println "	.ren_a([getName $ramBlock]_rf_ren)," $resolve
				odfi::common::println "	.addr_a([getName $ramBlock]_rf_addr)," $resolve
				odfi::common::println "	.wdata_a([getName $ramBlock]_rf_wdata)," $resolve
				odfi::common::println "	.rdata_a([getName $ramBlock]_rf_rdata)," $resolve
				odfi::common::println "	.wen_b([getName $ramBlock]_wen)," $resolve
				odfi::common::println "	.ren_b([getName $ramBlock]_ren)," $resolve
				odfi::common::println "	.addr_b([getName $ramBlock]_addr)," $resolve
				odfi::common::println "	.wdata_b([getName $ramBlock]_wdata)," $resolve
				odfi::common::println "	.rdata_b([getName $ramBlock]_rdata)" $resolve
				odfi::common::println ");" $resolve
				odfi::common::println "" $resolve
			}
		}

	} else {
	
		## 2r1w
		if {([$ramBlock hasAttribute hardware.osys::rfg::rw] && [$ramBlock hasAttribute software.osys::rfg::ro]) ||\
			([$ramBlock hasAttribute hardware.osys::rfg::ro] && [$ramBlock hasAttribute software.osys::rfg::rw])} {
			odfi::common::println "" $resolve
			odfi::common::println "ram_1w2r_1c #(" $resolve
			odfi::common::println "	.DATASIZE([$ramBlock width])," $resolve
			odfi::common::println "	.ADDRSIZE([ld [$ramBlock depth]])," $resolve
			odfi::common::println "	.INIT_RAM(1'b0)," $resolve
			odfi::common::println "	.PIPELINED(0)" $resolve
			odfi::common::println ") [getName $ramBlock] (" $resolve
			odfi::common::println "	.clk(clk),"				 $resolve
			$ramBlock onAttributes {software.osys::rfg::ro} {
				odfi::common::println "	.wen([getName $ramBlock]_wen)," $resolve
				odfi::common::println "	.waddr([getName $ramBlock]_addr)," $resolve
				odfi::common::println "	.wdata([getName	$ramBlock]_wdata)," $resolve
				odfi::common::println "	.ren1([getName $ramBlock]_ren)," $resolve
				odfi::common::println "	.raddr1([getName $ramBlock]_addr)," $resolve
				odfi::common::println "	.rdata1([getName $ramBlock]_rdata)," $resolve
				odfi::common::println "	.ren2([getName $ramBlock]_rf_ren)," $resolve
				odfi::common::println "	.raddr2([getName $ramBlock]_rf_addr)," $resolve
				odfi::common::println "	.rdata2([getName $ramBlock]_rf_rdata)" $resolve
				odfi::common::println ");" $resolve
				odfi::common::println "" $resolve
			}

			$ramBlock onAttributes {hardware.osys::rfg::ro} {
				odfi::common::println "	.wen([getName $ramBlock]_rf_wen)," $resolve
				odfi::common::println "	.waddr([getName $ramBlock]_rf_addr)," $resolve
				odfi::common::println "	.wdata([getName	$ramBlock]_rf_wdata)," $resolve
				odfi::common::println "	.ren1([getName $ramBlock]_ren)," $resolve
				odfi::common::println "	.raddr1([getName $ramBlock]_addr)," $resolve
				odfi::common::println "	.rdata1([getName $ramBlock]_rdata)," $resolve
				odfi::common::println "	.ren2([getName $ramBlock]_rf_ren)," $resolve
				odfi::common::println "	.raddr2([getName $ramBlock]_rf_addr)," $resolve
				odfi::common::println "	.rdata2([getName $ramBlock]_rf_rdata)" $resolve
				odfi::common::println ");" $resolve
				odfi::common::println "" $resolve
			}

		} else {

			## 1r1w
			if {([$ramBlock hasAttribute hardware.osys::rfg::wo] && [$ramBlock hasAttribute software.osys::rfg::ro]) ||\
				([$ramBlock hasAttribute hardware.osys::rfg::ro] && [$ramBlock hasAttribute software.osys::rfg::wo]) ||\
				[$ramBlock hasAttribute hardware.osys::rfg::rw] || [$ramBlock hasAttribute software.osys::rfg::rw]} {
				odfi::common::println "" $resolve
				odfi::common::println "ram_1w1r_1c #(" $resolve
				odfi::common::println "	.DATASIZE([$ramBlock width])," $resolve
				odfi::common::println "	.ADDRSIZE([ld [$ramBlock depth]])," $resolve
				odfi::common::println "	.INIT_RAM(1'b0)," $resolve
				odfi::common::println "	.PIPELINED(0)," $resolve
				odfi::common::println "	.REG_LIMIT(1)" $resolve
				odfi::common::println ") [getName $ramBlock] (" $resolve
				odfi::common::println "	.clk(clk),"	 $resolve
				
				$ramBlock onAttributes {hardware.osys::rfg::wo} {
					odfi::common::println "	.wen([getName $ramBlock]_wen)," $resolve
					odfi::common::println "	.wdata([getName $ramBlock]_wdata)," $resolve
					odfi::common::println "	.waddr([getName $ramBlock]_addr)," $resolve
					odfi::common::println "	.ren([getName $ramBlock]_rf_ren)," $resolve
					odfi::common::println "	.raddr([getName $ramBlock]_rf_addr)," $resolve
					odfi::common::println "	.rdata([getName $ramBlock]_rf_rdata)" $resolve
					odfi::common::println ");" $resolve
					odfi::common::println "" $resolve
				}

				$ramBlock onAttributes {hardware.osys::rfg::ro} {
					odfi::common::println "	.wen([getName $ramBlock]_rf_wen)," $resolve
					odfi::common::println "	.wdata([getName $ramBlock]_rf_wdata)," $resolve
					odfi::common::println "	.waddr([getName $ramBlock]_rf_addr)," $resolve
					odfi::common::println "	.ren([getName $ramBlock]_ren)," $resolve
					odfi::common::println "	.raddr([getName $ramBlock]_addr)," $resolve
					odfi::common::println "	.rdata([getName $ramBlock]_rdata)" $resolve
					odfi::common::println ");" $resolve
					odfi::common::println "" $resolve
				}

				$ramBlock onAttributes {hardware.osys::rfg::rw} {
					odfi::common::println "	.wen([getName $ramBlock]_wen)," $resolve
					odfi::common::println "	.wdata([getName $ramBlock]_wdata)," $resolve
					odfi::common::println "	.waddr([getName $ramBlock]_addr)," $resolve
					odfi::common::println "	.ren([getName $ramBlock]_ren)," $resolve
					odfi::common::println "	.raddr([getName $ramBlock]_addr)," $resolve
					odfi::common::println "	.rdata([getName $ramBlock]_rdata)" $resolve
					odfi::common::println ");" $resolve
					odfi::common::println "" $resolve
				}

				$ramBlock onAttributes {software.osys::rfg::rw} {
					odfi::common::println "	.wen([getName $ramBlock]_wen)," $resolve
					odfi::common::println "	.wdata([getName $ramBlock]_wdata)," $resolve
					odfi::common::println "	.waddr([getName $ramBlock]_addr)," $resolve
					odfi::common::println "	.ren([getName $ramBlock]_ren)," $resolve
					odfi::common::println "	.raddr([getName $ramBlock]_addr)," $resolve
					odfi::common::println "	.rdata([getName $ramBlock]_rdata)" $resolve
					odfi::common::println ");" $resolve
					odfi::common::println "" $resolve
				}

			}
		}
	}
	
}

# write RF instance
odfi::closures::oproc writeRFModule {registerfile} {
	puts "	[$registerfile name] [$registerfile name]_I ("
	puts "		.res_n(res_n),"
	puts "		.clk(clk),"
	puts "		.address([$registerfile name]_address),"
	puts "		.read_data([$registerfile name]_read_data),"
	puts "		.invalid_address([$registerfile name]_invalid_address),"
	puts "		.access_complete([$registerfile name]_access_complete),"
	puts "		.read_en([$registerfile name]_read_en),"
	puts "		.write_en([$registerfile name]_write_en),"
	puts "		.write_data([$registerfile name]_write_data),"

		set signalList {}
	$registerfile walkDepthFirst {
		if {[$it isa osys::rfg::RamBlock]} {
			
			$it onAttributes {hardware.osys::rfg::rw} { 
				lappend signalList "		.[getName $it]_addr([getName $it]_addr)"
				lappend signalList "		.[getName $it]_ren([getName $it]_ren)"
				lappend signalList "		.[getName $it]_rdata([getName $it]_rdata)"
				lappend signalList "		.[getName $it]_wen([getName $it]_wen)"
				lappend signalList "		.[getName $it]_wdata([getName $it]_wdata)"
			}

		} elseif {[$it isa osys::rfg::Register]} {

			$it onEachField {
				if {[$it name] != "Reserved"} {
					$it onAttributes {hardware.osys::rfg::counter} {
						
						$it onAttributes {hardware.osys::rfg::rw} {
							lappend signalList "		.[getName $it]_next([getName $it]_next)"
							lappend signalList "		.[getName $it]([getName $it])"
							lappend signalList "		.[getName $it]_wen([getName $it]_wen)"
						}
						
						$it onAttributes {hardware.osys::rfg::wo} {
							lappend signalList "		.[getName $it]_next([getName $it]_next)"
							lappend signalList "		.[getName $it]_wen([getName $it]_wen)"
						}

						$it onAttributes {hardware.osys::rfg::ro} {
							lappend signalList "		.[getName $it]([getName $it])"
						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							lappend signalList "		.[getName $it]_written([getName $it]_written)"
						}

						lappend signalList "		.[getName $it]_countup([getName $it]_countup)"

					} otherwise {

						$it onAttributes {hardware.osys::rfg::rw} {
							lappend signalList "		.[getName $it]_next([getName $it]_next)"
							lappend signalList "		.[getName $it]([getName $it])"
							
							$it onAttributes {hardware.osys::rfg::hardware_wen} {
								lappend signalList "		.[getName $it]_wen([getName $it]_wen)"
							}
						}
						
						$it onAttributes {hardware.osys::rfg::wo} {
							lappend signalList "		.[getName $it]_next([getName $it]_next)"
							
							$it onAttributes {hardware.osys::rfg::hardware_wen} {
								lappend signalList "		.[getName $it]_wen([getName $it]_wen)"
							}
						}

						$it onAttributes {hardware.osys::rfg::ro} {
							lappend signalList "		.[getName $it]([getName $it])"
						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							lappend signalList "		.[getName $it]_written([getName $it]_written)"
						}

					}

				}
			}
		}

		if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
			return false
		} else {
			return true
		}

	}

	puts [join $signalList ",\n"]

		puts "	);"
	puts ""
}
