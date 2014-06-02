<%
	set ramBlockCount 0

	# logarithmus dualis function for address bit calculation
	proc ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"
	
	# function to get the address Bits for the register file 
	proc getRFsize {registerfile} {
		set size 0
		set offset [$registerfile getAttributeValue software.osys::rfg::absolute_address]
		$registerfile walk {
			if {![$item isa osys::rfg::Group]} {
			 	if {[string is integer [$item getAttributeValue software.osys::rfg::absolute_address]]} {
			 		if {$size <= [$item getAttributeValue software.osys::rfg::absolute_address]} {
			 			set size [expr [$item getAttributeValue software.osys::rfg::absolute_address]+[$item getAttributeValue software.osys::rfg::size]]
			 		}
			 	}
			}
		}
		return [expr $size - $offset]
	}

	proc getAddrBits {registerfile} {
		return [ld [getRFsize $registerfile]]
	}

	# function which returns the Name with all parents
	proc getName {object} {
		set name {}
		set list [lreplace [$object parents] 0 0]
		set i 0
		set deleteIndex 0
		foreach element $list {
			if {[$element isa osys::rfg::RegisterFile] && [$element hasAttribute hardware.osys::rfg::external]} {
				set deleteIndex [expr $i+1]
			}
			incr i 1
		}
		set i 0
		foreach element $list {
			if {$i >= $deleteIndex} { 
				lappend	name [$element name]
			}
			incr i 1		
		}
		return [join $name "_"]	
	}

	proc writeAddressMap {object} {
		$object walkDepthFirst {
			if {[$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
				set size [$it getAttributeValue software.osys::rfg::size]
				puts "[getName $it]: base: 0x[format %x [$it getAttributeValue software.osys::rfg::absolute_address]] size: $size"
			}
			if {[$it isa osys::rfg::RegisterFile]} {
				set size [getRFsize $it]
				puts "[$it name]: base: 0x[format %x [$it getAttributeValue software.osys::rfg::absolute_address]] size: $size"
			}
			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				return false	
			} else {
				return true
			}
		}
	}

	# write the verilog template for an easy implementation in a higher level module 
	proc writeTemplate {object context} {
		set signalList {}
		$object walkDepthFirst {
			if {[$it isa osys::rfg::RamBlock]} {
				
				$it onAttributes {hardware.osys::rfg::rw} { 
					lappend signalList "	.${context}[getName $it]_addr()"
					lappend signalList "	.${context}[getName $it]_ren()"
					lappend signalList "	.${context}[getName $it]_rdata()"
					lappend signalList "	.${context}[getName $it]_wen()"
					lappend signalList "	.${context}[getName $it]_wdata()"
				}

			} elseif {[$it isa osys::rfg::Register]} {

				$it onEachField {
					if {[$it name] != "Reserved"} {
						$it onAttributes {hardware.osys::rfg::counter} {
							
							$it onAttributes {hardware.osys::rfg::rw} {
								lappend signalList "	.${context}[getName $it]_next()"
								lappend signalList "	.${context}[getName $it]()"
								lappend signalList "	.${context}[getName $it]_wen()"
							}
							
							$it onAttributes {hardware.osys::rfg::wo} {
								lappend signalList "	.${context}[getName $it]_next()"
								lappend signalList "	.${context}[getName $it]_wen()"
							}

							$it onAttributes {hardware.osys::rfg::ro} {
								lappend signalList "	.${context}[getName $it]()"
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								lappend signalList "	.${context}[getName $it]_written()"
							}

							lappend signalList "	.${context}[getName $it]_countup()"

						} otherwise {

							$it onAttributes {hardware.osys::rfg::rw} {
								lappend signalList "	.${context}[getName $it]_next()"
								lappend signalList "	.${context}[getName $it]()"
								
								$it onAttributes {hardware.osys::rfg::hardware_wen} {
									lappend signalList "	.${context}[getName $it]_wen()"
								}
							}
							
							$it onAttributes {hardware.osys::rfg::wo} {
								lappend signalList "	.${context}[getName $it]_next()"
								
								$it onAttributes {hardware.osys::rfg::hardware_wen} {
									lappend signalList "	.${context}[getName $it]_wen()"
								}
							}

							$it onAttributes {hardware.osys::rfg::ro} {
								lappend signalList "	.${context}[getName $it]()"
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								lappend signalList "	.${context}[getName $it]_written()"
							}

						}

					}
				}
			}

			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				set registerfile $it
				puts "	.[$registerfile name]_address(),"
				puts "	.[$registerfile name]_read_data(),"
				puts "	.[$registerfile name]_invalid_address(),"
				puts "	.[$registerfile name]_access_complete(),"
				puts "	.[$registerfile name]_read_en(),"
				puts "	.[$registerfile name]_write_en(),"
				puts "	.[$registerfile name]_write_data(),"
 				writeTemplate $it "[$registerfile name]_"
				return false
			} else {
				return true
			}

		}

		puts [join $signalList ",\n"]
	
	}
	
	# write Inputs and Outputs
	proc writeBlackbox {object context} {
		set signalList {}
		$object walkDepthFirst {
			if {[$it isa osys::rfg::RamBlock]} {

				$it onAttributes {hardware.osys::rfg::rw} { 
					lappend signalList "	input wire\[[expr [ld [$it depth]]-1]:0\] ${context}[getName $it]_addr"
					lappend signalList "	input wire ${context}[getName $it]_ren"
					lappend signalList "	output wire\[[expr [$it width]-1]:0\] ${context}[getName $it]_rdata"
					lappend signalList "	input wire ${context}[getName $it]_wen"
					lappend signalList "	input wire\[[expr [$it width]-1]:0\] ${context}[getName $it]_wdata"
				}

			} elseif {[$it isa osys::rfg::Register]} {
				$it onEachField {

					$it onAttributes {hardware.osys::rfg::counter} {
							
						$it onAttributes {hardware.osys::rfg::rw} {
							if {[$it width] == 1} {
								lappend signalList "	input wire ${context}[getName $it]_next"
								lappend signalList "	output wire ${context}[getName $it]"			
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
								lappend signalList "	output wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
							}

							lappend signalList "	input wire ${context}[getName $it]_wen"
						}
							
						$it onAttributes {hardware.osys::rfg::wo} {
							if {[$it width] == 1} {
								lappend signalList "	input wire ${context}[getName $it]_next"	
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
							}

							lappend signalList "	input wire ${context}[getName $it]_wen"	
						}

						$it onAttributes {hardware.osys::rfg::ro} {
							if {[$it width] == 1} {
								lappend signalList "	output wire ${context}[getName $it]"		
							} else {
								lappend signalList "	output wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
							}

						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							lappend signalList "	output reg ${context}[getName $it]_written"
						}

						lappend signalList "	input wire ${context}[getName $it]_countup"

					} otherwise {

						$it onAttributes {hardware.osys::rfg::rw} {
							if {[$it width] == 1} {
								lappend signalList "	input wire ${context}[getName $it]_next"
								lappend signalList "	output reg ${context}[getName $it]"	
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
								lappend signalList "	output reg\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
							}	

							$it onAttributes {hardware.osys::rfg::hardware_wen} {
								lappend signalList "	input wire ${context}[getName $it]_wen"
							}
						}
							
						$it onAttributes {hardware.osys::rfg::wo} {
							if {[$it width] == 1} {
								lappend signalList "	input wire ${context}[getName $it]_next"		
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] ${context}[getName $it]_next"
							}	

							$it onAttributes {hardware.osys::rfg::hardware_wen} {
								lappend signalList "	input wire ${context}[getName $it]_wen"	
							}
						}

						$it onAttributes {hardware.osys::rfg::ro} {
							if {[$it width] == 1} {
								lappend signalList "	output reg ${context}[getName $it]"
							} else {
								lappend signalList "	output reg\[[expr {[$it width]-1}]:0\] ${context}[getName $it]"
							}
							
						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							lappend signalList "	output reg ${context}[getName $it]_written"	
						}

					}

				}	
			}
			## ToDo rewrite with wire and reg signals
			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				set registerfile $it
				if {[expr [getAddrBits $registerfile]-1] < [ld [expr [$registerfile register_size]/8]]} {
					puts "	output reg\[[getAddrBits $registerfile]:[ld [expr [$registerFile register_size]/8]]\] [$registerfile name]_address,"
				} else {
					puts "	output reg\[[expr [getAddrBits $registerfile]-1]:[ld [expr [$registerFile register_size]/8]]\] [$registerfile name]_address,"
				}
				puts "	input wire\[[expr [$registerFile register_size] - 1]:0\] [$registerfile name]_read_data(),"
				puts "	input wire [$registerfile name]_invalid_address,"
				puts "	input wire [$registerfile name]_access_complete(),"
				puts "	output reg [$registerfile name]_read_en(),"
				puts "	output reg [$registerfile name]_write_en(),"
				puts "	output reg\[[expr [$registerFile register_size] - 1]:0\] [$registerfile name]_write_data(),"
 				writeBlackbox $it "[$registerfile name]_"
				return false
			} else {
				return true
			}

		}
		puts [join $signalList ",\n"]
	}

	# write needed internal wires and regs
	proc writeRegisternames {object} {
		$object walkDepthFirst {
			if {[$it isa osys::rfg::RamBlock]} {

				$it onAttributes {hardware.osys::rfg::rw} {
					puts "	reg\[[expr [ld [$it depth]]-1]:0\] [getName $it]_rf_addr;"
					puts "	reg [getName $it]_rf_ren;"
					puts "	wire\[[expr [$it width]-1]:0\] [getName $it]_rf_rdata;"
					puts "	reg [getName $it]_rf_wen;"
					puts "	reg\[[expr [$it width]-1]:0\] [getName $it]_rf_wdata;"
					## just for one ram (ToDo: add condition)
					set delays 3
					for {set i 0} {$i < $delays} {incr i} {
						puts "	reg read_en_dly$i;"
					}
				}

			} elseif {[$it isa osys::rfg::Register]} {
				$it onAttributes {hardware.osys::rfg::rreinit_source} {
					puts "	reg rreinit;"
				} otherwise {
					$it onEachField {
						if {[$it name] != "Reserved"} {

							$it onAttributes {hardware.osys::rfg::counter} {
								if {[$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute hardware.osys::rfg::wo] || [$it hasAttribute software.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo]} {
									puts "	reg [getName $it]_load_enable;"
									puts "	reg\[[expr {[$it width]-1}]:0\] [getName $it]_load_value;"
								}

								if {![$it hasAttribute hardware.osys::rfg::ro] && ![$it hasAttribute hardware.osys::rfg::rw]} {
									if {[$it width] == 1} {
										puts "	wire [getName $it];"
									} else {
										puts "	wire\[[expr {[$it width]-1}]:0\] [getName $it];"
									}
								}
								
							} otherwise {
							
								if {![$it hasAttribute hardware.osys::rfg::ro] && ![$it hasAttribute hardware.osys::rfg::rw]} {
									if {[$it width] == 1} {
										puts "	reg [getName $it];"
									} else {
										puts "	reg\[[expr {[$it width]-1}]:0\] [getName $it];"
									}
								}
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								if {[$it getAttributeValue hardware.osys::rfg::software_written]==2} {
									puts "	reg [getName $it]_res_in_last_cycle;"
								}
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
	}

	# write the reset logic
	proc writeReset {register} {
		puts "		if (!res_n)"
		puts "		begin"
		
		$register onAttributes {hardware.osys::rfg::rreinit_source} {
			puts "			rreinit <= 1'b0;"
		} otherwise {

			$register onEachField {
				if {[$it name] != "Reserved"} {

					$it onAttributes {hardware.osys::rfg::counter} {
						if {[$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute hardware.osys::rfg::wo] || [$it hasAttribute software.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo]} { 
							puts "			[getName $it]_load_enable <= 1'b0;"
						}	
					} otherwise {
						puts "			[getName $it] <= [$it reset];"
						
						$it onAttributes {hardware.osys::rfg::software_written} {
							puts "			[getName $it]_written <= 1'b0;"
							if {[$it getAttributeValue hardware.osys::rfg::software_written]==2} {
								puts "			[getName $it]_res_in_last_cycle <= 1'b1;"
							}
						}

					}

				}
			}
		}
		puts "		end"
	}

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
		puts "	ram_2rw_1c #("
		puts "		.DATASIZE([$ramBlock width]),"
		puts "		.ADDRSIZE([ld [$ramBlock depth]]),"
		puts "		.PIPELINED(0)"
		puts "	) [getName $ramBlock] (" 
		puts "		.clk(clk),"
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
					lappend signalList "		.[getName $it]_addr([$registerfile name]_[getName $it]_addr)"
					lappend signalList "		.[getName $it]_ren([$registerfile name]_[getName $it]_ren)"
					lappend signalList "		.[getName $it]_rdata([$registerfile name]_[getName $it]_rdata)"
					lappend signalList "		.[getName $it]_wen([$registerfile name]_[getName $it]_wen)"
					lappend signalList "		.[getName $it]_wdata([$registerfile name]_[getName $it]_wdata)"
				}

			} elseif {[$it isa osys::rfg::Register]} {

				$it onEachField {
					if {[$it name] != "Reserved"} {
						$it onAttributes {hardware.osys::rfg::counter} {
							
							$it onAttributes {hardware.osys::rfg::rw} {
								lappend signalList "		.[getName $it]_next([$registerfile name]_[getName $it]_next)"
								lappend signalList "		.[getName $it]([$registerfile name]_[getName $it])"
								lappend signalList "		.[getName $it]_wen([$registerfile name]_[getName $it]_wen)"
							}
							
							$it onAttributes {hardware.osys::rfg::wo} {
								lappend signalList "		.[getName $it]_next([$registerfile name]_[getName $it]_next)"
								lappend signalList "		.[getName $it]_wen([$registerfile name]_[getName $it]_wen)"
							}

							$it onAttributes {hardware.osys::rfg::ro} {
								lappend signalList "		.[getName $it]([$registerfile name]_[getName $it])"
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								lappend signalList "		.[getName $it]_written([$registerfile name]_[getName $it]_written)"
							}

							lappend signalList "		.[getName $it]_countup([$registerfile name]_[getName $it]_countup)"

						} otherwise {

							$it onAttributes {hardware.osys::rfg::rw} {
								lappend signalList "		.[getName $it]_next([$registerfile name]_[getName $it]_next)"
								lappend signalList "		.[getName $it]([$registerfile name]_[getName $it])"
								
								$it onAttributes {hardware.osys::rfg::hardware_wen} {
									lappend signalList "		.[getName $it]_wen([$registerfile name]_[getName $it]_wen)"
								}
							}
							
							$it onAttributes {hardware.osys::rfg::wo} {
								lappend signalList "		.[getName $it]_next([$registerfile name]_[getName $it]_next)"
								
								$it onAttributes {hardware.osys::rfg::hardware_wen} {
									lappend signalList "		.[getName $it]_wen([$registerfile name]_[getName $it]_wen)"
								}
							}

							$it onAttributes {hardware.osys::rfg::ro} {
								lappend signalList "		.[getName $it]([$registerfile name]_[getName $it])"
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								lappend signalList "		.[getName $it]_written([$registerfile name]_[getName $it]_written)"
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

	# write counter instance 
	proc writeModules {object} {
		$object walkDepthFirst {
			if {[$it isa osys::rfg::RamBlock]} {
				writeRamModule $it
			}
			if {[$it isa osys::rfg::Register]} {
				$it onEachField {
					
					$it onAttributes {hardware.osys::rfg::counter} {
						writeCounterModule $it $it
					}

				}
			}

			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				##writeRFModule $it
				return false
			} else {
				return true
			}

		}
	}

	proc writeRamBlockRegister {registerFile ramBlock} {
		
		$ramBlock onAttributes {hardware.osys::rfg::rw} {
			# Write always block
			puts "	/* RamBlock [getName $ramBlock] */"
			puts "	`ifdef ASYNC_RES"
			puts "	always @(posedge clk or negedge res_n) `else"
			puts "	always @(posedge clk) `endif"
			puts "	begin"
			puts "		if (!res_n)"
			puts "		begin"
			puts "			`ifdef ASIC"
			puts "			[getName $ramBlock]_rf_addr <= [ld [$ramBlock depth]]'b0;"
			puts "			[getName $ramBlock]_rf_wdata  <= [$ramBlock width]'b0;"
			puts "			`endif"
			puts "			[getName $ramBlock]_rf_wen <= 1'b0;"
			puts "			[getName $ramBlock]_rf_ren <= 1'b0;"
			puts "		end"
			puts "		else"
			puts "		begin"
			set equal [expr [$ramBlock getAttributeValue software.osys::rfg::absolute_address]/([$ramBlock depth]*[$registerFile register_size]/8)]
			puts "			if (address\[[expr [getAddrBits $registerFile]-1]:[expr [ld [$ramBlock depth]]+3]\] == $equal)"
			puts "			begin"
			puts "				[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
			puts "				[getName $ramBlock]_rf_wdata <= write_data\[15:0\];"
			puts "				[getName $ramBlock]_rf_wen <= write_en;"
			puts "				[getName $ramBlock]_rf_ren <= read_en;"
			puts "			end"
			puts "		end"
			puts "	end"
			puts ""
		}

	}

	# write the hardware register write
	proc writeRegisterHardwareWrite {register field} {
		$field onAttributes {hardware.osys::rfg::counter} {
			if {[$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute hardware.osys::rfg::rw]} {
				puts "			else if([getName $field]_wen)"
				puts "			begin"
				puts "				[getName $field]_load_value <= [getName $field]_next;"
				puts "				[getName $field]_load_enable <= 1'b1;"
				puts "			end"					
			}

		} otherwise	{
			$register onAttributes {hardware.osys::rfg::rreinit_source} {
					puts "			else"
					puts "			begin"
					puts "				rreinit <= 1'b0"
					puts "			end"
			} otherwise {
				if {[$field hasAttribute hardware.osys::rfg::wo] || [$field hasAttribute hardware.osys::rfg::rw]} {
					$field onAttributes {hardware.osys::rfg::hardware_wen} {
						puts "			else if([getName $field]_wen)"
						puts "			begin"
						$field onAttributes {hardware.osys::rfg::sticky} {
							puts "				[getName $field] <= [getName $field]_next | [getName $field];"	
						} otherwise {
							puts "				[getName $field] <= [getName $field]_next;"
						}
						puts "			end"
					} otherwise {
						if {[$field hasAttribute software.osys::rfg::wo] || [$field hasAttribute software.osys::rfg::rw]} {
							puts "			else"
							puts "			begin"
						
							$field onAttributes {hardware.osys::rfg::sticky} {
								puts "				[getName $field] <= [getName $field]_next | [getName $field];"	
							} otherwise {
								puts "				[getName $field] <= [getName $field]_next;"
							}
						
							puts "			end"
						} else {

							$field onAttributes {hardware.osys::rfg::sticky} {
								puts "				[getName $field] <= [getName $field]_next | [getName $field];"	
							} otherwise {
								puts "				[getName $field] <= [getName $field]_next;"
							}

						}
					}
					
				}
			}
		}
	}

	# write Software register write calls hardware register write
	proc writeRegisterSoftwareWrite {object register} {
		#set reg_size [expr [$object size]/8]
		set lowerBound 0
		$register onAttributes {hardware.osys::rfg::rreinit_source} {
			if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
				puts "			if((address\[[expr [getAddrBits $registerFile]]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
			} else {
				puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
			}
			puts "			begin"
			puts "				rreinit <= 1'b1;"
			puts "			end"
			puts "			else"
			puts "			begin"
			puts "				rreinit <= 1'b0;"
			puts "			end"
		
		} otherwise {
		
			$register onEachField {
				set upperBound [expr $lowerBound+[$it width]]
				$it onAttributes {hardware.osys::rfg::counter} {
					if {[$it hasAttribute software.osys::rfg::wo] || [$it hasAttribute software.osys::rfg::rw]} {
						if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
							puts "			if((address\[[expr [getAddrBits $registerFile]]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
						} else {
							puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
						}
						puts "			begin"
						puts "				[getName $it]_load_enable <= 1'b1;"
						puts "				[getName $it]_load_value <= write_data\[[expr $upperBound-1]:$lowerBound\];"
						puts "			end"
						
						if {[$it hasAttribute hardware.osys::rfg::wo] || [$it hasAttribute hardware.osys::rfg::rw]} {
							writeRegisterHardwareWrite $register $it
						}

						if {[$it hasAttribute hardware.osys::rfg::wo] || [$it hasAttribute hardware.osys::rfg::rw] || [$it hasAttribute software.osys::rfg::wo] || [$it hasAttribute software.osys::rfg::rw]} {
							puts "			else"
							puts "			begin"
							puts "				[getName $it]_load_enable <= 1'b0;"
							puts "				[getName $it]_load_value <= [$it width]'b0;"
							puts "			end"
						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							if {[$it getAttributeValue hardware.osys::rfg::software_written]==2} {
								if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
									puts "			if(((address\[[getAddrBits $registerFile]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en) || [getName $it]_res_in_last_cycle)"
								} else {
									puts "			if(((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en) || [getName $it]_res_in_last_cycle)"
								}
								puts "			begin"
								puts "				[getName $it]_written <= 1'b1;"
								puts "				[getName $it]_res_in_last_cycle <= 1'b0;"
								puts "			end"
								puts "			else"
								puts "			begin"
								puts "				[getName $it]_written <= 1'b0;"
								puts "			end"
								puts ""															
							} else {
								if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
									puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
								} else {
									puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
								}
								puts "			begin"
								puts "				[getName $it]_written <= 1'b1;"
								puts "			end"
								puts "			else"
								puts "			begin"
								puts "				[getName $it]_written <= 1'b0;"
								puts "			end"
								puts ""
							}						
						}
					}
		
				} otherwise {
					if {[$it hasAttribute software.osys::rfg::wo] || [$it hasAttribute software.osys::rfg::rw]} {
						if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
							puts "			if((address\[[expr [getAddrBits $registerFile]]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
						} else {
							puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
						}
						puts "			begin"
						
						$it onAttributes {hardware.osys::rfg::software_write_xor} {
							puts "				[getName $it] <= (write_data\[[expr $upperBound-1]:$lowerBound\] ^ [getName $it]);"
						} otherwise {
							puts "				[getName $it] <= write_data\[[expr $upperBound-1]:$lowerBound\];"
						}
						
						puts "			end"
						
						if {[$it hasAttribute hardware.osys::rfg::wo] || [$it hasAttribute hardware.osys::rfg::rw]} {
							writeRegisterHardwareWrite $register $it
						}
						$it onAttributes {hardware.osys::rfg::software_written} {
							if {[$it getAttributeValue hardware.osys::rfg::software_written]==2} {
								if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
									puts "			if(((address\[[getAddrBits $registerFile]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en) || [getName $it]_res_in_last_cycle)"
								} else {
									puts "			if(((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en) || [getName $it]_res_in_last_cycle)"
								}
								puts "			begin"
								puts "				[getName $it]_written <= 1'b1;"
								puts "				[getName $it]_res_in_last_cycle <= 1'b0;"
								puts "			end"
								puts "			else"
								puts "			begin"
								puts "				[getName $it]_written <= 1'b0;"
								puts "			end"
								puts ""															
							} else {
								if {[expr [getAddrBits $registerFile]-1]<[ld [expr [$registerFile register_size]/8]]} {
									puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
								} else {
									puts "			if((address\[[expr [getAddrBits $registerFile]-1]:[ld [expr [$registerFile register_size]/8]]\]== [expr [$register getAttributeValue software.osys::rfg::absolute_address]/8]) && write_en)"
								}
								puts "			begin"
								puts "				[getName $it]_written <= 1'b1;"
								puts "			end"
								puts "			else"
								puts "			begin"
								puts "				[getName $it]_written <= 1'b0;"
								puts "			end"
								puts ""
							}						
						}

					} else {
						writeRegisterHardwareWrite $register $it
					}

					incr lowerBound [$it width]
				
				}
			}
		}
	}

	proc writeRegisterFile {RF subRF} {
		puts "	/* RegisterFile [$subRF name]*/"
		puts "	`ifdef ASYNC_RES"
		puts "	always @(posedge clk or negedge res_n) `else"
		puts "	always @(posedge clk) `endif"
		puts "	begin"
		puts "	if (!res_n)"
		puts "	begin"
		puts "		[$subRF name]_write_en <= 1'b0;"
		puts "		[$subRF name]_read_en  <= 1'b0;"
		puts "		`ifdef ASIC"
		puts "		[$subRF name]_write_data <= 64'b0;"
		if {[expr [getAddrBits $subRF]-1] < [ld [expr [$subRF register_size]/8]]} {
			puts "		[$subRF name]_address  <= [getAddrBits $subRF]'b0;"
		} else {
			puts "		[$subRF name]_address  <= [expr [getAddrBits $subRF]-1]'b0;"
		}
		
		puts "		`endif"
		puts "	end"
		puts "	else"
		puts "	begin"
		set care [expr [$subRF getAttributeValue software.osys::rfg::absolute_address]/([getRFsize $subRF]*[$RF register_size]/8)]
		set care [format %x $care]
		puts "		if(address\[[expr [getAddrBits $RF]- 1]:[getAddrBits $subRF]\] == [expr [getAddrBits $RF]-[getAddrBits $subRF]]'h$care)"
		puts "		begin"
		puts "			[$subRF name]_address <= address\[[getAddrBits $subRF]:[ld [expr [$subRF register_size]/8]]\];"
		puts "		end"
		puts "		if( (address\[[expr [getAddrBits $RF]- 1]:[getAddrBits $subRF]\] == [expr [getAddrBits $RF]-[getAddrBits $subRF]]'h$care) && write_en)"
		puts "		begin"
		puts "			[$subRF name]_write_data <= write_data\[63:0\];"
		puts "			[$subRF name]_write_en <= 1'b1;"
		puts "		end"
		puts "		else"
		puts "		begin"
		puts "			[$subRF name]_write_en <= 1'b0;"
		puts "		end"
		puts "		if( (address\[[expr [getAddrBits $RF]- 1]:[getAddrBits $subRF]\] == [expr [getAddrBits $RF]-[getAddrBits $subRF]]'h$care) && read_en)"
		puts "		begin"
		puts "			[$subRF name]_read_en <= 1'b1;"
		puts "		end"
		puts "		else"
		puts "		begin"
		puts "			[$subRF name]_read_en <= 1'b0;"
		puts "		end"
		puts "	"
	}

	# write the register function // rewrite this there is with if else constructs...
	proc writeRegister {object} {
		$object walkDepthFirst {
			set item $it
			if {[$item isa osys::rfg::RamBlock]} {
				writeRamBlockRegister $registerFile $item
			} elseif {[$item isa osys::rfg::Register]} {
				# Write always block
				puts "	/* register [$item name] */"
				puts "	`ifdef ASYNC_RES"
				puts "	always @(posedge clk or negedge res_n) `else"
				puts "	always @(posedge clk) `endif"
				puts "	begin"
				
				# Write reset logic
				writeReset $item
				
				# Write register logic
				puts "		else"
				puts "		begin"
				puts ""

				writeRegisterSoftwareWrite $object $item
				
				puts "		end"

				puts "	end"
				puts ""	
			}

			if {[$item isa osys::rfg::RegisterFile] && [$item hasAttribute hardware.osys::rfg::external]} {
				writeRegisterFile $object $item
				return false
			} else {
				return true
			}

		}
	}

	proc RamBlockCheck {object} {

		$object walkDepthFirst {
			if {[$it isa osys::rfg::RamBlock]} {
				incr ramBlockCount 1
			}

			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				return false
			} else {
				return true
			}

		}
	}

	proc writeAddressControlReset {rb_count object} {
		if {$rb_count != 0} {
			set delays 3
			for {set i 0} {$i < $delays} {incr i} {
				puts "			read_en_dly$i <= 1'b0;"
			} 		
		}
	}

	proc writeRamDelay {rb_count object} {
		if {$rb_count != 0} {
			set delays 3
			for {set i 0} {$i < $delays} {incr i} {
				if {$i==0} {
					puts "			read_en_dly$i <= read_en;"
				} else {
					puts "			read_en_dly$i <= read_en_dly[expr $i-1];"
				}
			}	
		}
	}

	#write the address logic for reading and invalid signal 
	proc writeAddressControl {object} {

		$object walkDepthFirst {
			if {[$it isa osys::rfg::RamBlock]} {
				set dontCare [string repeat x [ld [$it depth]]]
				set care [expr [$it getAttributeValue software.osys::rfg::absolute_address]/([$it depth]*[$registerFile register_size]/8)] 
				set care [format %x $care]
				puts "				\{[expr [getAddrBits $registerFile]-[expr [ld [$it depth]]+3]]'h$care,[ld [$it depth]]'b$dontCare\}:"
				puts "				begin"
				puts "					read_data\[[expr "[$it width]-1"]:0\] <= [getName $it]_rf_rdata;"
				if {[$it width] != [$registerFile register_size]} {
					puts "					read_data\[[expr "[$registerFile register_size]-1"]:[$it width]\] <= [expr "[$registerFile register_size]-[$it width]"]'b0;"
				}
				puts "					invalid_address <= 1'b0;"
				set delays 3
				puts "					access_complete <= write_en || read_en_dly[expr $delays-1];"
				puts "				end"
			} elseif {[$it isa osys::rfg::Register]} {
				if {[getAddrBits $registerFile] == [ld [expr [$registerFile register_size]/8]]} {
					puts "				[expr [getAddrBits $registerFile]+1-[ld [expr [$registerFile register_size]/8]]]'h[format %x [expr [$it getAttributeValue software.osys::rfg::absolute_address]/8]]:"
				} else {
					puts "				[expr [getAddrBits $registerFile]-[ld [expr [$registerFile register_size]/8]]]'h[format %x [expr [$it getAttributeValue software.osys::rfg::absolute_address]/8]]:"
				}
				puts "				begin"
				set lowerBound 0
				$it onEachField {
					set upperBound [expr $lowerBound+[$it width]]
					if {[$it hasAttribute software.osys::rfg::ro] || [$it hasAttribute software.osys::rfg::rw]} {		
						puts "					read_data\[[expr $upperBound-1]:$lowerBound\] <= [getName $it];"
					}
					incr lowerBound [$it width]
				}
				if {$lowerBound !=[$registerFile register_size]} {
					puts "					read_data\[[expr [$object register_size]-1]:$lowerBound\] <= [expr [$registerFile register_size]-$lowerBound]'b0;"
				}
				puts "					invalid_address <= 1'b0;"
				puts "					access_complete <= write_en || read_en;"
				puts "				end"
			}
			
			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				set care [expr [$it getAttributeValue software.osys::rfg::absolute_address]/([getRFsize $it]*[$object register_size]/8)]
				set care [format %x $care]
				set dontCare [expr [getAddrBits $object] - 3 - ([getAddrBits $object] - [getAddrBits $it])]
				puts "				{[expr [getAddrBits $object] - [getAddrBits $it]]'h${care},${dontCare}'b[string repeat x $dontCare]}:"
				puts "				begin"
				puts ""
				puts "				end"
				return false
			} else {
				return true
			}

		}
	}
%>

/* auto generated by RFG */
/* address map
<% writeAddressMap $registerFile %>
*/
/* instantiation template
<%puts -nonewline "[$registerFile name] [$registerFile name]"%>_I (
	.res_n(),
	.clk(),
	.address(),
	.read_data(),
	.invalid_address(),
	.access_complete(),
	.read_en(),
	.write_en(),
	.write_data(),
<% writeTemplate $registerFile ""%>);
*/
module <%puts [$registerFile name]%>(
	///\defgroup sys
	///@{ 
	input wire res_n,
	input wire clk,
	///}@ 
	///\defgroup rw_if
	///@{ 
	input wire[<%
	if {[expr [getAddrBits $registerFile]-1] < [ld [expr [$registerFile register_size]/8]]} {
		puts -nonewline "[expr [getAddrBits $registerFile]]"	
	} else {
		puts -nonewline "[expr [getAddrBits $registerFile]-1]"
	}%>:<%puts -nonewline "[ld [expr [$registerFile register_size]/8]]"%>] address,
	output reg[<% puts -nonewline "[expr [$registerFile register_size]-1]"%>:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[<% puts -nonewline "[expr [$registerFile register_size]-1]"%>:0] write_data,
	///}@ 
<% writeBlackbox $registerFile ""%>
);

<% writeRegisternames $registerFile %>
<% writeModules $registerFile %>
<% writeRegister $registerFile %>
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n) `else
	always @(posedge clk) `endif
	begin
		if (!res_n)
		begin
			invalid_address <= 1'b0;
			access_complete <= 1'b0;
			`ifdef ASIC
			read_data   <= <%puts -nonewline "[$registerFile register_size]"%>'b0;
			`endif
<% RamBlockCheck $registerFile %>
<% writeAddressControlReset $ramBlockCount $registerFile %>		end
		else
		begin
<% writeRamDelay $ramBlockCount $registerFile %>
			casex(address[<% 
				if {[expr [getAddrBits $registerFile]-1] < [ld [expr [$registerFile register_size]/8]]} {
					puts -nonewline "[expr [getAddrBits $registerFile]]"	
				} else {
					puts -nonewline "[expr [getAddrBits $registerFile]-1]"
				}%>:<%puts -nonewline "[ld [expr [$registerFile register_size]/8]]"%>])
<% writeAddressControl $registerFile %>				default:
				begin
					invalid_address <= read_en || write_en;
					access_complete <= read_en || write_en;
				end		
			endcase
		end
	end
endmodule