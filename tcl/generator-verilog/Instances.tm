# write counter instance
proc writeCounterModule {register field} {
	puts "	counter48 #("
	puts "		.DATASIZE([$field width])"
	puts "	) [getName $register]_I ("
	puts "		.clk(clk),"
	puts "		.res_n(res_n),"
	puts "		.increment([getName $field]_countup),"
	if {[$field hasAttribute hardware.osys::rfg::rw] || [$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw] || [$field hasAttribute software.osys::rfg::wo]} {
		puts "		.load([getName $field]_load_value),"	
	} else {
		puts " 		.load([$field width]'b0),"
	}
	$field onAttributes {hardware.osys::rfg::rreinit} {
		if {[$field hasAttribute hardware.osys::rfg::rw] || [$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw] || [$field hasAttribute software.osys::rfg::wo]} {
			puts "		.load_enable(rreinit || [getName $field]_load_enable),"
		} else {
			puts "		.load_enable(rreinit),"
		}				
	} otherwise {
		if {[$field hasAttribute hardware.osys::rfg::rw] || [$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw] || [$field hasAttribute software.osys::rfg::wo]} {
			puts "		.load_enable([getName $field]_load_enable),"
		} else {
			puts "		.load_enable(1'b0),"
		}
		
	}
	puts "		.value([getName $field])"
	puts "	);"
	puts ""
}

# write Ram Instance
proc writeRamModule {ramBlock} {
	
	## 2rw 2w1r
	if {([$ramBlock hasAttribute hardware.osys::rfg::rw] && [$ramBlock hasAttribute software.osys::rfg::rw]) ||\
		([$ramBlock hasAttribute hardware.osys::rfg::rw] && [$ramBlock hasAttribute software.osys::rfg::wo]) ||\
		([$ramBlock hasAttribute hardware.osys::rfg::wo] && [$ramBlock hasAttribute software.osys::rfg::rw])} {
		puts "	ram_2rw_1c #("
		puts "		.DATASIZE([$ramBlock width]),"
		puts "		.ADDRSIZE([ld [$ramBlock depth]]),"
		puts "		.PIPELINED(0)"
		puts "	) [getName $ramBlock] ("
		puts "		.clk(clk)," 
		$ramBlock onAttributes {software.osys::rfg::wo} {
			puts "		.wen_a([getName $ramBlock]_rf_wen),"
			puts "		.ren_a(1'b0),"
			puts "		.addr_a([getName $ramBlock]_rf_addr),"
			puts "		.wdata_a([getName $ramBlock]_rf_wdata),"
			puts "		.wen_b([getName $ramBlock]_wen),"
			puts "		.ren_b([getName $ramBlock]_ren),"
			puts "		.addr_b([getName $ramBlock]_addr),"
			puts "		.wdata_b([getName $ramBlock]_wdata),"
			puts "		.rdata_b([getName $ramBlock]_rdata)"
			puts "	);"
			puts ""
		} otherwise {
			$ramBlock onAttributes {hardware.osys::rfg::wo} {
				puts "		.wen_a([getName $ramBlock]_rf_wen),"
				puts "		.ren_a([getName $ramBlock]_rf_ren),"
				puts "		.addr_a([getName $ramBlock]_rf_addr),"
				puts "		.wdata_a([getName $ramBlock]_rf_wdata),"
				puts "		.rdata_a([getName $ramBlock]_rf_rdata),"
				puts "		.wen_b([getName $ramBlock]_wen),"
				puts "		.ren_b(1'b0),"
				puts "		.addr_b([getName $ramBlock]_addr),"
				puts "		.wdata_b([getName $ramBlock]_wdata)"
				puts "	);"
				puts ""
			} otherwise {
				puts "		.wen_a([getName $ramBlock]_rf_wen),"
				puts "		.ren_a([getName $ramBlock]_rf_ren),"
				puts "		.addr_a([getName $ramBlock]_rf_addr),"
				puts "		.wdata_a([getName $ramBlock]_rf_wdata),"
				puts "		.rdata_a([getName $ramBlock]_rf_rdata),"
				puts "		.wen_b([getName $ramBlock]_wen),"
				puts "		.ren_b([getName $ramBlock]_ren),"
				puts "		.addr_b([getName $ramBlock]_addr),"
				puts "		.wdata_b([getName $ramBlock]_wdata),"
				puts "		.rdata_b([getName $ramBlock]_rdata)"
				puts "	);"
				puts ""
			}
		}

	} else {
	
		## 2r1w
		if {([$ramBlock hasAttribute hardware.osys::rfg::rw] && [$ramBlock hasAttribute software.osys::rfg::ro]) ||\
			([$ramBlock hasAttribute hardware.osys::rfg::ro] && [$ramBlock hasAttribute software.osys::rfg::rw])} {
			
			puts "	ram_1w2r_1c #("
			puts "		.DATASIZE([$ramBlock width]),"
			puts "		.ADDRSIZE([ld [$ramBlock depth]]),"
			puts "		.INIT_RAM(1'b0),"
			puts "		.PIPELINED(0)"
			puts "	) [getName $ramBlock] ("
			puts "		.clk(clk),"				
			$ramBlock onAttributes {software.osys::rfg::ro} {
				puts "		.wen([getName $ramBlock]_wen),"
				puts "		.waddr([getName $ramBlock]_addr),"
				puts "		.wdata([getName	$ramBlock]_wdata),"
				puts "		.ren1([getName $ramBlock]_ren),"
				puts "		.raddr1([getName $ramBlock]_addr),"
				puts "		.rdata1([getName $ramBlock]_rdata),"
				puts "		.ren2([getName $ramBlock]_rf_ren),"
				puts "		.raddr2([getName $ramBlock]_rf_addr),"
				puts "		.rdata2([getName $ramBlock]_rf_rdata)"
				puts "	);"
				puts ""
			}

			$ramBlock onAttributes {hardware.osys::rfg::ro} {
				puts "		.wen([getName $ramBlock]_rf_wen),"
				puts "		.waddr([getName $ramBlock]_rf_addr),"
				puts "		.wdata([getName	$ramBlock]_rf_wdata),"
				puts "		.ren1([getName $ramBlock]_ren),"
				puts "		.raddr1([getName $ramBlock]_addr),"
				puts "		.rdata1([getName $ramBlock]_rdata),"
				puts "		.ren2([getName $ramBlock]_rf_ren),"
				puts "		.raddr2([getName $ramBlock]_rf_addr),"
				puts "		.rdata2([getName $ramBlock]_rf_rdata)"
				puts "	);"
				puts ""					
			}

		} else {

			## 1r1w
			if {([$ramBlock hasAttribute hardware.osys::rfg::wo] && [$ramBlock hasAttribute software.osys::rfg::ro]) ||\
				([$ramBlock hasAttribute hardware.osys::rfg::ro] && [$ramBlock hasAttribute software.osys::rfg::wo]) ||\
				[$ramBlock hasAttribute hardware.osys::rfg::rw] || [$ramBlock hasAttribute software.osys::rfg::rw]} {
				
				puts "	ram_1w1r_1c #("
				puts "		.DATASIZE([$ramBlock width]),"
				puts "		.ADDRSIZE([ld [$ramBlock depth]]),"
				puts "		.INIT_RAM(1'b0),"
				puts "		.PIPELINED(0),"
				puts "		.REG_LIMIT(1)"
				puts "	) [getName $ramBlock] ("
				puts "		.clk(clk),"	
				
				$ramBlock onAttributes {hardware.osys::rfg::wo} {
					puts "		.wen([getName $ramBlock]_wen),"
					puts "		.wdata([getName $ramBlock]_wdata),"
					puts "		.waddr([getName $ramBlock]_addr),"
					puts "		.ren([getName $ramBlock]_rf_ren),"
					puts "		.raddr([getName $ramBlock]_rf_addr),"
					puts "		.rdata([getName $ramBlock]_rf_rdata)"
					puts "	);"
					puts ""
				}

				$ramBlock onAttributes {hardware.osys::rfg::ro} {
					puts "		.wen([getName $ramBlock]_rf_wen),"
					puts "		.wdata([getName $ramBlock]_rf_wdata),"
					puts "		.waddr([getName $ramBlock]_rf_addr),"
					puts "		.ren([getName $ramBlock]_ren),"
					puts "		.raddr([getName $ramBlock]_addr),"
					puts "		.rdata([getName $ramBlock]_rdata)"
					puts "	);"
					puts ""
				}

				$ramBlock onAttributes {hardware.osys::rfg::rw} {
					puts "		.wen([getName $ramBlock]_wen),"
					puts "		.wdata([getName $ramBlock]_wdata),"
					puts "		.waddr([getName $ramBlock]_addr),"
					puts "		.ren([getName $ramBlock]_ren),"
					puts "		.raddr([getName $ramBlock]_addr),"
					puts "		.rdata([getName $ramBlock]_rdata)"
					puts "	);"
					puts ""
				}

				$ramBlock onAttributes {software.osys::rfg::rw} {
					puts "		.wen([getName $ramBlock]_wen),"
					puts "		.wdata([getName $ramBlock]_wdata),"
					puts "		.waddr([getName $ramBlock]_addr),"
					puts "		.ren([getName $ramBlock]_ren),"
					puts "		.raddr([getName $ramBlock]_addr),"
					puts "		.rdata([getName $ramBlock]_rdata)"
					puts "	);"
					puts ""
				}

			}
		}
	}
	
}

# write RF instance
proc writeRFModule {registerfile} {
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
