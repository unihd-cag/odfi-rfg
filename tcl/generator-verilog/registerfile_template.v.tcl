<%
	package require HelperFunctions 1.0.0
	source ${osys::rfg::generator::verilog::location}/Instances.tm
	
	set ramBlockCount 0

	proc writeAddressMap {object} {
		$object walkDepthFirst {
            if {[$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock] || [$it isa osys::rfg::RegisterFile]} {
				set size [$it getAttributeValue software.osys::rfg::size]
                if {[expr [getAddrBits $registerFile]-1] < [ld [expr [$registerFile register_size]/8]]} {
		            puts "[getName $it]: base\[[expr [getAddrBits $registerFile]]:3\] [expr [$it getAttributeValue software.osys::rfg::absolute_address]/8] size: $size"
	            } else {
		            puts "[getName $it]: base\[[expr [getAddrBits $registerFile]-1]:3\] [expr [$it getAttributeValue software.osys::rfg::absolute_address]/8] size: $size"

			    }
            }

			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				return false	
			} else {
				return true
			}
		}
	}

	## write the verilog template for an easy implementation in a higher level module 
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

                $it onAttributes {hardware.osys::rfg::ro} {
                    lappend signalList "    .${context}[getName $it]_addr()"
                    lappend signalList "    .${context}[getName $it]_ren()"
                    lappend signalList "    .${context}[getName $it]_rdata()"
                }
                
                $it onAttributes {hardware.osys::rfg::wo} {
                    lappend signalList "    .${context}[getName $it]_addr()"
                    lappend signalList "    .${context}[getName $it]_wen()"
                    lappend signalList "    .${context}[getName $it]_wdata()"
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

							$it onAttributes {hardware.osys::rfg::hardware_clear} {
								lappend signalList "	.${context}[getName $it]_clear()"
							} 

						}

					}
				}
			}
            
			if {[$it isa osys::rfg::RegisterFile]} {
				
                set registerfile $it
                
                $registerfile onAttributes {hardware.osys::rfg::external} {
                    lappend signalList "	.${context}[getName $registerfile]_address()"
                    lappend signalList "	.${context}[getName $registerfile]_read_data()"
                    lappend signalList "	.${context}[getName $registerfile]_invalid_address()"
                    lappend signalList "	.${context}[getName $registerfile]_access_complete()"
                    lappend signalList "	.${context}[getName $registerfile]_read_en()"
                    lappend signalList "	.${context}[getName $registerfile]_write_en()"
                    lappend signalList "	.${context}[getName $registerfile]_write_data()"
                }

                $registerfile onAttributes {hardware.osys::rfg::internal} {
                    writeTemplate $registerfile "[$registerfile name]_"
                }

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

                $it onAttributes {hardware.osys::rfg::ro} {   
					lappend signalList "	input wire\[[expr [ld [$it depth]]-1]:0\] ${context}[getName $it]_addr"
					lappend signalList "	input wire ${context}[getName $it]_ren"
					lappend signalList "	output wire\[[expr [$it width]-1]:0\] ${context}[getName $it]_rdata"
                }

                $it onAttributes {hardware.osys::rfg::wo} {
					lappend signalList "	input wire\[[expr [ld [$it depth]]-1]:0\] ${context}[getName $it]_addr"
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

						$it onAttributes {hardware.osys::rfg::hardware_clear} {
							lappend signalList "	input wire ${context}[getName $it]_clear"	
						}

					}

				}	
			}
			## ToDo rewrite with wire and reg signals
			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				set registerfile $it
				if {[expr [getAddrBits $registerfile]-1] < [ld [expr [$registerfile register_size]/8]]} {
					lappend signalList "	output reg\[[getAddrBits $registerfile]:[ld [expr [$registerFile register_size]/8]]\] [getName $registerfile]_address"
				} else {
					lappend signalList "	output reg\[[expr [getAddrBits $registerfile]-1]:[ld [expr [$registerFile register_size]/8]]\] [getName $registerfile]_address"
				}
				lappend signalList "	input wire\[[expr [getRFmaxWidth $registerfile] - 1]:0\] [getName $registerfile]_read_data"
				lappend signalList "	input wire [getName $registerfile]_invalid_address"
				lappend signalList "	input wire [getName $registerfile]_access_complete"
				lappend signalList "	output reg [getName $registerfile]_read_en"
				lappend signalList "	output reg [getName $registerfile]_write_en"
				lappend signalList "	output reg\[[expr [getRFmaxWidth $registerfile] - 1]:0\] [getName $registerfile]_write_data"
 				##writeBlackbox $it "[$registerfile name]_"
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
                
                $it onAttributes {software.osys::rfg::ro} {
					puts "	reg\[[expr [ld [$it depth]]-1]:0\] [getName $it]_rf_addr;"
					puts "	reg [getName $it]_rf_ren;"
					puts "	wire\[[expr [$it width]-1]:0\] [getName $it]_rf_rdata;"
					set delays 3
					for {set i 0} {$i < $delays} {incr i} {
						puts "	reg read_en_dly$i;"
					}
                }

                $it onAttributes {software.osys::rfg::wo} {
					puts "	reg\[[expr [ld [$it depth]]-1]:0\] [getName $it]_rf_addr;"
					puts "	reg [getName $it]_rf_wen;"
					puts "	reg\[[expr [$it width]-1]:0\] [getName $it]_rf_wdata;"
					## just for one ram (ToDo: add condition)
					set delays 3
					for {set i 0} {$i < $delays} {incr i} {
						puts "	reg read_en_dly$i;"
					}
                    
                }

				$it onAttributes {software.osys::rfg::rw} {
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
		
        if {[$ramBlock hasAttribute software.osys::rfg::rw] ||\
            [$ramBlock hasAttribute software.osys::rfg::ro] ||\
            [$ramBlock hasAttribute software.osys::rfg::wo]} {
			# Write always block
			puts "	/* RamBlock [getName $ramBlock] */"
			puts "	`ifdef ASYNC_RES"
			puts "	always @(posedge clk or negedge res_n) `else"
			puts "	always @(posedge clk) `endif"
			puts "	begin"
			puts "		if (!res_n)"
			puts "		begin"

            $ramBlock onAttributes {software.osys::rfg::ro} {
                puts "			`ifdef ASIC"
                puts "			[getName $ramBlock]_rf_addr <= [ld [$ramBlock depth]]'b0;"
                puts "			`endif"
                puts "			[getName $ramBlock]_rf_ren <= 1'b0;"
                puts "		end"
                puts "		else"
                puts "		begin"
                set equal [expr [$ramBlock getAttributeValue software.osys::rfg::absolute_address]/([$ramBlock depth]*[$registerFile register_size]/8)]
                if {[expr [getAddrBits $registerFile]-1] < [expr [ld [$ramBlock depth]]+3]} {
                    puts "			[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
                    puts "			[getName $ramBlock]_rf_ren <= read_en;"
                } else {
                    puts "			if (address\[[expr [getAddrBits $registerFile]-1]:[expr [ld [$ramBlock depth]]+3]\] == $equal)"
                    puts "			begin"
                    puts "				[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
                    puts "				[getName $ramBlock]_rf_ren <= read_en;"
                    puts "			end"
                }
            }
            
            $ramBlock onAttributes {software.osys::rfg::wo} {
                puts "			`ifdef ASIC"
                puts "			[getName $ramBlock]_rf_addr <= [ld [$ramBlock depth]]'b0;"
                puts "			[getName $ramBlock]_rf_wdata  <= [$ramBlock width]'b0;"
                puts "			`endif"
                puts "			[getName $ramBlock]_rf_wen <= 1'b0;"
                puts "		end"
                puts "		else"
                puts "		begin"
                set equal [expr [$ramBlock getAttributeValue software.osys::rfg::absolute_address]/([$ramBlock depth]*[$registerFile register_size]/8)]
                if {[expr [getAddrBits $registerFile]-1] < [expr [ld [$ramBlock depth]]+3]} {
                    puts "			[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
                    puts "			[getName $ramBlock]_rf_wdata <= write_data\[[expr [$ramBlock width] -1]:0\];"
                    puts "			[getName $ramBlock]_rf_wen <= write_en;"
                } else {
                    puts "			if (address\[[expr [getAddrBits $registerFile]-1]:[expr [ld [$ramBlock depth]]+3]\] == $equal)"
                    puts "			begin"
                    puts "				[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
                    puts "				[getName $ramBlock]_rf_wdata <= write_data\[[expr [$ramBlock width] -1]:0\];"
                    puts "				[getName $ramBlock]_rf_wen <= write_en;"
                    puts "			end"
                }
            }

            $ramBlock onAttributes {software.osys::rfg::rw} {
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
                if {[expr [getAddrBits $registerFile]-1] < [expr [ld [$ramBlock depth]]+3]} {
                    puts "			[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
                    puts "			[getName $ramBlock]_rf_wdata <= write_data\[[expr [$ramBlock width] -1]:0\];"
                    puts "			[getName $ramBlock]_rf_wen <= write_en;"
                    puts "			[getName $ramBlock]_rf_ren <= read_en;"
                } else {
                    puts "			if (address\[[expr [getAddrBits $registerFile]-1]:[expr [ld [$ramBlock depth]]+3]\] == $equal)"
                    puts "			begin"
                    puts "				[getName $ramBlock]_rf_addr <= address\[[expr 2+[ld [$ramBlock depth]]]:3\];"
                    puts "				[getName $ramBlock]_rf_wdata <= write_data\[[expr [$ramBlock width] -1]:0\];"
                    puts "				[getName $ramBlock]_rf_wen <= write_en;"
                    puts "				[getName $ramBlock]_rf_ren <= read_en;"
                    puts "			end"
                }
            }
			
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

			$field onAttributes {hardware.osys::rfg::hardware_clear} {
					puts "			if([getName $field]_clear)"
					puts "			begin"
					puts "				[getName $field] <= [$field width]'h0;"
					puts "			end"
			}

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
						
						
						writeRegisterHardwareWrite $register $it

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
						$it onAttributes {software.osys::rfg::software_write_clear} {
							puts "			[getName $it] <= [$it width]'h0;"

						} otherwise {
						
							$it onAttributes {hardware.osys::rfg::software_write_xor} {
								puts "				[getName $it] <= (write_data\[[expr $upperBound-1]:$lowerBound\] ^ [getName $it]);"
							} otherwise {
								puts "				[getName $it] <= write_data\[[expr $upperBound-1]:$lowerBound\];"
							}
						}
						puts "			end"
						
						writeRegisterHardwareWrite $register $it

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
		puts "	/* RegisterFile [getName $subRF]*/"
		puts "	`ifdef ASYNC_RES"
		puts "	always @(posedge clk or negedge res_n) `else"
		puts "	always @(posedge clk) `endif"
		puts "	begin"
		puts "		if (!res_n)"
		puts "		begin"
		puts "			[getName $subRF]_write_en <= 1'b0;"
		puts "			[getName $subRF]_read_en  <= 1'b0;"
		puts "			`ifdef ASIC"
		puts "			[getName $subRF]_write_data <= 64'b0;"
		if {[expr [getAddrBits $subRF]-1] < [ld [expr [$subRF register_size]/8]]} {
			puts "			[getName $subRF]_address  <= [expr [getAddrBits $subRF]+1-[ld [expr [$subRF register_size]/8]]]'b0;"
		} else {
			puts "			[getName $subRF]_address  <= [expr [getAddrBits $subRF]-[ld [expr [$subRF register_size]/8]]]'b0;"
		}
		
		puts "			`endif"
		puts "		end"
		puts "		else"
		puts "		begin"
		set care [expr [$subRF getAttributeValue software.osys::rfg::absolute_address]>>[ld [getRFsize $subRF]]]
		set care [format %x $care]
		puts "			if(address\[[expr [getAddrBits $RF]- 1]:[getAddrBits $subRF]\] == [expr [getAddrBits $RF]-[getAddrBits $subRF]]'h$care)"
		puts "			begin"
        if {[expr [getAddrBits $subRF]-1] < [ld [expr [$subRF register_size]/8]]} {
            puts "				[getName $subRF]_address <= address\[[expr [getAddrBits $subRF]]:[ld [expr [$subRF register_size]/8]]\];"    
        } else {
		    puts "				[getName $subRF]_address <= address\[[expr [getAddrBits $subRF]-1]:[ld [expr [$subRF register_size]/8]]\];"
        }
        puts "			end"
		puts "			if( (address\[[expr [getAddrBits $RF]- 1]:[getAddrBits $subRF]\] == [expr [getAddrBits $RF]-[getAddrBits $subRF]]'h$care) && write_en)"
		puts "			begin"
		puts "				[getName $subRF]_write_data <= write_data\[63:0\];"
		puts "				[getName $subRF]_write_en <= 1'b1;"
		puts "			end"
		puts "			else"
		puts "			begin"
		puts "				[getName $subRF]_write_en <= 1'b0;"
		puts "			end"
		puts "			if( (address\[[expr [getAddrBits $RF]- 1]:[getAddrBits $subRF]\] == [expr [getAddrBits $RF]-[getAddrBits $subRF]]'h$care) && read_en)"
		puts "			begin"
		puts "				[getName $subRF]_read_en <= 1'b1;"
		puts "			end"
		puts "			else"
		puts "			begin"
		puts "				[getName $subRF]_read_en <= 1'b0;"
		puts "			end"
		puts "		end"
		puts "	end"
		puts ""
	}

	# write the register function
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
			    if {[$it hasAttribute software.osys::rfg::ro] || [$it hasAttribute software.osys::rfg::rw]} {
                    set dontCare [string repeat x [ld [$it depth]]]
                    set care [expr [$it getAttributeValue software.osys::rfg::absolute_address]/([$it depth]*[$registerFile register_size]/8)] 
                    if {$care != 0} {
                        set care [format %x $care]
                        puts "				\{[expr [getAddrBits $registerFile]-[expr [ld [$it depth]]+3]]'h$care,[ld [$it depth]]'b$dontCare\}:"
                    } else {
                        puts "				[ld [$it depth]]'b$dontCare:"
                    }
                    puts "				begin"
                    puts "					read_data\[[expr "[$it width]-1"]:0\] <= [getName $it]_rf_rdata;"
                    if {[$it width] != [getRFmaxWidth $registerFile]} {
                        puts "					read_data\[[expr "[getRFmaxWidth $registerFile]-1"]:[$it width]\] <= [expr "[getRFmaxWidth $registerFile]-[$it width]"]'b0;"
                    }
                    puts "					invalid_address <= 1'b0;"
                    set delays 3
                    puts "					access_complete <= write_en || read_en_dly[expr $delays-1];"
                    puts "				end"
			    } elseif {[$it hasAttribute software.osys::rfg::wo]} {
                    set dontCare [string repeat x [ld [$it depth]]]
                    set care [expr [$it getAttributeValue software.osys::rfg::absolute_address]/([$it depth]*[$registerFile register_size]/8)] 
                    if {$care != 0} {
                        set care [format %x $care]
                        puts "				\{[expr [getAddrBits $registerFile]-[expr [ld [$it depth]]+3]]'h$care,[ld [$it depth]]'b$dontCare\}:"
                    } else {
                        puts "				[ld [$it depth]]'b$dontCare:"
                    }
                    puts "				begin"
                    puts "                  invalid_address <= 1'b0;"
                    set delays 3
                    puts "                  access_complete <= write_en || read_en_dly[expr $delays-1];"
                    puts "              end"
                }
            } elseif {[$it isa osys::rfg::Register] && ![$it hasAttribute hardware.osys::rfg::rreinit_source]} {
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
				if {$lowerBound !=[getRFmaxWidth $registerFile]} {
					puts "					read_data\[[expr [getRFmaxWidth $object]-1]:$lowerBound\] <= [expr [getRFmaxWidth $registerFile]-$lowerBound]'b0;"
				}
				puts "					invalid_address <= 1'b0;"
				puts "					access_complete <= write_en || read_en;"
				puts "				end"
			}
			
			if {[$it isa osys::rfg::RegisterFile] && [$it hasAttribute hardware.osys::rfg::external]} {
				##::puts "Absolute Address: [$it getAttributeValue software.osys::rfg::absolute_address]"
				##::puts "Size in Bits: [ld [getRFsize $it]]"
				##::puts "Shifted Result: [expr [$it getAttributeValue software.osys::rfg::absolute_address]>>[ld [getRFsize $it]]]"
				set care [expr [$it getAttributeValue software.osys::rfg::absolute_address]>>[ld [getRFsize $it]]]
				##set care [expr [$it getAttributeValue software.osys::rfg::absolute_address]/([getRFsize $it]*[$object register_size]/8)]
				set care [format %x $care]
				set dontCare [expr [getAddrBits $object] - 3 - ([getAddrBits $object] - [getAddrBits $it])]
				if {$dontCare == 0} {
                    puts "				{[expr [getAddrBits $object] - [getAddrBits $it]]'h$care}:"
                } else { 
                    puts "				{[expr [getAddrBits $object] - [getAddrBits $it]]'h${care},${dontCare}'b[string repeat x $dontCare]}:"
                }
                puts "				begin"
				puts "					read_data <= [getName $it]_read_data;"
				puts "					invalid_address <= [getName $it]_invalid_address;"
				puts "					access_complete <= [getName $it]_access_complete;"
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
	output reg[<% puts -nonewline "[expr [getRFmaxWidth $registerFile]-1]"%>:0] read_data,
	output reg invalid_address,
	output reg access_complete,
	input wire read_en,
	input wire write_en,
	input wire[<% puts -nonewline "[expr [getRFmaxWidth $registerFile]-1]"%>:0] write_data,
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
			read_data   <= <%puts -nonewline "[getRFmaxWidth $registerFile]"%>'b0;
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
