<%
	set ramBlockCount 0

	# logarithmus dualis function for address bit calculation
	proc ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"
	
	# function to get the address Bits for the register file 
	proc getAddrBits {registerfile} {
		set addrBits [ld [expr [$registerfile getAttributeValue software.osys::rfg::absolute_end_address]/8]]
		incr addrBits [ld [expr [$registerfile register_size]/8]]
		return $addrBits
	}

	# function which returns the Name with all parents
	proc getName {object} {
		set name {}
		set list [lreplace [$object parents] 0 0]
		foreach element $list {
			lappend	name [$element name]		
		}
		return [join $name "_"]	
	}

	proc writeAddressMap {object} {
		$object walk {
			if {[$item isa osys::rfg::Register] || [$item isa osys::rfg::RamBlock]} {
				set size [$item getAttributeValue software.osys::rfg::size]
				puts "[getName $item]: base: 0x[$item getAttributeValue software.osys::rfg::absolute_address] size: $size"
			} 
		}
	}

	# write the verilog template for an easy implementation in a higher level module 
	proc writeTemplate {object} {
		set signalList {}
		$object walk {
			if {[$item isa osys::rfg::RamBlock]} {
				
				$item onAttributes {hardware.osys::rfg::rw} { 
					lappend signalList "	.[getName $item]_addr()"
					lappend signalList "	.[getName $item]_ren()"
					lappend signalList "	.[getName $item]_rdata()"
					lappend signalList "	.[getName $item]_wen()"
					lappend signalList "	.[getName $item]_wdata()"
				}

			} elseif {[$item isa osys::rfg::Register]} {

				$item onEachField {
					if {[$it name] != "Reserved"} {
						
						$it onAttributes {hardware.osys::rfg::counter} {
							
							$it onAttributes {hardware.osys::rfg::rw} {
								lappend signalList "	.[getName $it]_next()"
								lappend signalList "	.[getName $it]()"
								lappend signalList "	.[getName $it]_wen()"
							}
							
							$it onAttributes {hardware.osys::rfg::wo} {
								lappend signalList "	.[getName $it]_next()"
								lappend signalList "	.[getName $it]_wen()"
							}

							$it onAttributes {hardware.osys::rfg::ro} {
								lappend signalList "	.[getName $it]()"
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								lappend signalList "	.[getName $it]_written()"
							}

							lappend signalList "	.[getName $it]_countup()"

						} otherwise {

							$it onAttributes {hardware.osys::rfg::rw} {
								lappend signalList "	.[getName $it]_next()"
								lappend signalList "	.[getName $it]()"
								
								$it onAttributes {hardware.osys::rfg::hardware_wen} {
									lappend signalList "	.[getName $it]_wen()"
								}
							}
							
							$it onAttributes {hardware.osys::rfg::wo} {
								lappend signalList "	.[getName $it]_next()"
								
								$it onAttributes {hardware.osys::rfg::hardware_wen} {
									lappend signalList "	.[getName $it]_wen()"
								}
							}

							$it onAttributes {hardware.osys::rfg::ro} {
								lappend signalList "	.[getName $it]()"
							}

							$it onAttributes {hardware.osys::rfg::software_written} {
								lappend signalList "	.[getName $it]_written()"
							}

						}

					}
				}
			}
		}
		puts [join $signalList ",\n"]
	}
	
	# write Inputs and Outputs
	proc writeBlackbox {object} {
		set signalList {}
		$object walk {
			if {[$item isa osys::rfg::RamBlock]} {

				$item onAttributes {hardware.osys::rfg::rw} { 
					lappend signalList "	input wire\[[expr [ld [$item depth]]-1]:0\] [getName $item]_addr"
					lappend signalList "	input wire [getName $item]_ren"
					lappend signalList "	output wire\[[expr [$item width]-1]:0\] [getName $item]_rdata"
					lappend signalList "	input wire [getName $item]_wen"
					lappend signalList "	input wire\[[expr [$item width]-1]:0\] [getName $item]_wdata"
				}

			} elseif {[$item isa osys::rfg::Register]} {
				$item onEachField {

					$it onAttributes {hardware.osys::rfg::counter} {
							
						$it onAttributes {hardware.osys::rfg::rw} {
							if {[$it width] == 1} {
								lappend signalList "	input wire [getName $it]_next"
								lappend signalList "	output wire [getName $it]"			
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] [getName $it]_next"
								lappend signalList "	output wire\[[expr {[$it width]-1}]:0\] [getName $it]"
							}

							lappend signalList "	input wire [getName $it]_wen"
						}
							
						$it onAttributes {hardware.osys::rfg::wo} {
							if {[$it width] == 1} {
								lappend signalList "	input wire [getName $it]_next"	
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] [getName $it]_next"
							}

							lappend signalList "	input wire [getName $it]_wen"	
						}

						$it onAttributes {hardware.osys::rfg::ro} {
							if {[$it width] == 1} {
								lappend signalList "	output wire [getName $it]"		
							} else {
								lappend signalList "	output wire\[[expr {[$it width]-1}]:0\] [getName $it]"
							}

						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							lappend signalList "	output reg [getName $it]_written"
						}

						lappend signalList "	input wire [getName $it]_countup"

					} otherwise {

						$it onAttributes {hardware.osys::rfg::rw} {
							if {[$it width] == 1} {
								lappend signalList "	input wire [getName $it]_next"
								lappend signalList "	output reg [getName $it]"	
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] [getName $it]_next"
								lappend signalList "	output reg\[[expr {[$it width]-1}]:0\] [getName $it]"
							}	

							$it onAttributes {hardware.osys::rfg::hardware_wen} {
								lappend signalList "	input wire [getName $it]_wen"
							}
						}
							
						$it onAttributes {hardware.osys::rfg::wo} {
							if {[$it width] == 1} {
								lappend signalList "	input wire [getName $it]_next"		
							} else {
								lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] [getName $it]_next"
							}	

							$it onAttributes {hardware.osys::rfg::hardware_wen} {
								lappend signalList "	input wire [getName $it]_wen"	
							}
						}

						$it onAttributes {hardware.osys::rfg::ro} {
							if {[$it width] == 1} {
								lappend signalList "	output reg [getName $it]"
							} else {
								lappend signalList "	output reg\[[expr {[$it width]-1}]:0\] [getName $it]"
							}
							
						}

						$it onAttributes {hardware.osys::rfg::software_written} {
							lappend signalList "	output reg [getName $it]_written"	
						}

					}

				}	
			}
		}
		puts [join $signalList ",\n"]
	}

	# write needed internal wires and regs
	proc writeRegisternames {object} {
		$object walk {
			if {[$item isa osys::rfg::RamBlock]} {

				$item onAttributes {hardware.osys::rfg::rw} {
					puts "	reg\[[expr [ld [$item depth]]-1]:0\] [getName $item]_rf_addr;"
					puts "	reg [getName $item]_rf_ren;"
					puts "	wire\[[expr [$item width]-1]:0\] [getName $item]_rf_rdata;"
					puts "	reg [getName $item]_rf_wen;"
					puts "	reg\[[expr [$item width]-1]:0\] [getName $item]_rf_wdata;"
					## just for one ram (ToDo: add condition)
					set delays 3
					for {set i 0} {$i < $delays} {incr i} {
						puts "	reg read_en_dly$i;"
					}
				}

			} elseif {[$item isa osys::rfg::Register]} {
				$item onAttributes {hardware.osys::rfg::rreinit_source} {
					puts "	reg rreinit;"
				} otherwise {
					$item onEachField {
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

	# write counter instance 
	proc writeModules {object} {
		$object walk {
			if {[$item isa osys::rfg::RamBlock]} {
				writeRamModule $item
			}
			if {[$item isa osys::rfg::Register]} {
				$item onEachField {
					
					$it onAttributes {hardware.osys::rfg::counter} {
						writeCounterModule $item $it
					}

				}
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
		##set reg_size [expr [$object size]/8]
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

	# write the register function // rewrite this there is with if else constructs...
	proc writeRegister {object} {
		$object walk {
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
		}
	}

	proc RamBlockCheck {object} {
		set var 0
		$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				RamBlockCheck $it
			} else {
				if {[$it isa osys::rfg::RamBlock]} {
					incr ramBlockCount 1
				}
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

		$object walk {
			if {[$item isa osys::rfg::RamBlock]} {
					set dontCare [string repeat x [ld [$item depth]]]
					set care [expr [$item getAttributeValue software.osys::rfg::absolute_address]/([$item depth]*[$registerFile register_size]/8)] 
					set care [format %x $care]
					puts "				\{[expr [getAddrBits $registerFile]-[expr [ld [$item depth]]+3]]'h$care,[expr "[ld [$item getAttributeValue software.osys::rfg::absolute_address]]-[ld [expr [$registerFile register_size]/8]]"]'b$dontCare\}:"
					puts "				begin"
					puts "					read_data\[[expr "[$item width]-1"]:0\] <= [getName $item]_rf_rdata;"
					if {[$item width] != [$registerFile register_size]} {
						puts "					read_data\[[expr "[$registerFile register_size]-1"]:[$item width]\] <= [expr "[$registerFile register_size]-[$item width]"]'b0;"
					}
					puts "					invalid_address <= 1'b0;"
					set delays 3
					puts "					access_complete <= write_en || read_en_dly[expr $delays-1];"
					puts "				end"
			} elseif {[$item isa osys::rfg::Register]} {
				if {[getAddrBits $registerFile] == [ld [expr [$registerFile register_size]/8]]} {
					puts "				[expr [getAddrBits $registerFile]+1-[ld [expr [$registerFile register_size]/8]]]'h[format %x [expr [$item getAttributeValue software.osys::rfg::absolute_address]/8]]:"
				} else {
					puts "				[expr [getAddrBits $registerFile]-[ld [expr [$registerFile register_size]/8]]]'h[format %x [expr [$item getAttributeValue software.osys::rfg::absolute_address]/8]]:"
				}
				puts "				begin"
				set lowerBound 0
				$item onEachField {
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
<% writeTemplate $registerFile  %>);
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
<% writeBlackbox $registerFile %>
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