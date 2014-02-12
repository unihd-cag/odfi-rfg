<%
	# logarithmus dualis function for address bit calculation
	proc ld x "expr {int(ceil(log(\$x)/[expr log(2)]))}"
	
	# function to get the address Bits for the register file 
	proc getAddrBits {registerfile} {
		set addrBits [ld [expr [$registerfile size]/8]]
		incr addrBits [ld [expr [$registerfile register_size]/8]]
		return $addrBits
	}
	
	# write the verilog template for an easy implementation in a higher level module 
	proc writeTemplate {object} {

		set signalList {}
		$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				writeTemplate $it
			} else {
				set register $it
				$it onEachField {
					if {[$it name] != "Reserved"} {
						if {[$it hasAttribute hardware.global.rw]} {
							lappend signalList "	.[$register name]_[$it name]_next()"
							lappend signalList "	.[$register name]_[$it name]"
							if {[$it hasAttribute hardware.global.hardware_wen]} {
								lappend signalList "	.[$register name]_[$it name]_wen()"
							}
							if {[$it hasAttribute hardware.global.software_written]} {
								lappend signalList "	.[$register name]_[$it name]_written()"								
							}
						}
						if {[$it hasAttribute hardware.global.wo]} {
							lappend signalList "	.[$register name]_[$it name]_next()"
							if {[$it hasAttribute hardware.global.hardware_wen]} {
								lappend signalLilst "	.[$register name]_[$it name]_wen()"
							}
						}
						if {[$it hasAttribute hardware.global.ro]} {
							lappend signalList "	.[$register name]_[$it name]()"
							if {[$it hasAttribute hardware.global.software_written]} {
								lappend signalList "	.[$register name]_[$it name]_written()"								
							}
						}
						if {[$it hasAttribute hardware.global.counter]} {
							lappend signalList "	.[$register name]_[$it name]_countup()"
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
		$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				writeBlackbox $it 
			} else {
				set register $it 
				$it onEachField {
					if {[$it hasAttribute hardware.global.rw]} {
						if {[$it width] == 1} {
							lappend signalList "	input wire [$register name]_[$it name]_next"
							if {[$it hasAttribute hardware.global.counter]} {
								lappend signalList "	output wire [$register name]_[$it name]"
							} else {
								lappend signalList "	output reg [$register name]_[$it name]"
							}
						} else {
							lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]_next"
							if {[$it hasAttribute hardware.global.counter]} {
								lappend signalList "	output wire\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]"
							} else {
								lappend signalList "	output reg\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]"
							}
						}
					} elseif {[$it hasAttribute hardware.global.wo]} {
						if {[$it width] == 1} {
							lappend signalList "	input wire [$register name]_[$it name]_next"
						} else {
							lappend signalList "	input wire\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]_next"
						}	
					} elseif {[$it hasAttribute hardware.global.ro]} {
						if {[$it width] == 1} {
							if {[$it hasAttribute hardware.global.counter]} {
								lappend signalList "	output wire [$register name]_[$it name]"
							} else {
								lappend signalList "	output reg [$register name]_[$it name]"
							}	
						} else {
							if {[$it hasAttribute hardware.global.counter]} {
								lappend signalList "	output wire\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]"
							} else {
								lappend signalList "	output reg\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]"
							}
						}
					}
					if {[$it hasAttribute hardware.global.hardware_wen]} {
						lappend signalList "	input wire [$register name]_[$it name]_wen"
					}
					if {[$it hasAttribute hardware.global.software_written]} {
						lappend signalList "	output reg [$register name]_[$it name]_written"
					}	
					if {[$it hasAttribute hardware.global.counter]} {
						lappend signalList "	input wire [$register name]_[$it name]_countup"
					}
				}
			}
		}
		puts [join $signalList ",\n"]
	}

	# write needed internal wires and regs
	proc writeRegisternames {object} {
		$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				writeRegisternames $it
			} else {
				set register $it
				$it onEachField {
					if {[$it name] != "Reserved"} {
						if {![$it hasAttribute hardware.global.ro] && ![$it hasAttribute hardware.global.rw]} {
							if {[$it width] == 1} {
								puts "	reg [$register name]_[$it name];"
							} else {
								puts "	reg\[[expr {[$it width]-1}]:0\] [$register name]_[$it name];"
							}
						}
						if {[$it hasAttribute hardware.global.software_written]} {
							if {[$it getAttributeValue hardware.global.software_written]==2} {
								puts "	reg [$register name]_[$it name]_res_in_last_cycle;"
							}
						}
						if {[$it hasAttribute hardware.global.counter]} {
							puts "	reg [$register name]_[$it name]_load_enable;"
							puts "	reg\[[expr {[$it width]-1}]:0\] [$register name]_[$it name]_load_value;"
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
		$register onEachField {
			if {[$it name] != "Reserved"} {
				if {[$it hasAttribute hardware.global.counter]} {
					puts "			[$register name]_[$it name]_load_enable <= 1'b0;"	
				} else {
					puts "			[$register name]_[$it name] <= [$it reset];"
					if {[$it hasAttribute hardware.global.software_written]} {
						puts "			[$register name]_[$it name]_written <= 1'b0;"
						if {[$it getAttributeValue hardware.global.software_written]==2} {
							puts "			[$register name]_[$it name]_res_in_last_cycle <= 1'b1;"
						}
					}
				}
			}
		}
		puts "		end"
	}

	

	# write counter instance 
	proc writeCounterModule {object} {
			$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				writeCounterModule $it
			} else {
				set register $it
				$it onEachField {
					if {[$it hasAttribute hardware.global.counter]} {
						puts "	counter48 #("
						puts "		.DATASIZE([$it width])"
						puts "	) [$register name]_I ("
						puts "		.clk(clk),"
						puts "		.res_n(res_n),"
						puts "		.increment([$register name]_[$it name]_countup),"
						puts "		.load([$register name]_[$it name]_load_value),"
						puts "		.load_enable([$register name]_[$it name]_load_enable),"
						puts "		.value([$register name]_[$it name])"
						puts "	);"
					}
				}
			}
		}
	}

	# write the hardware register write
	proc writeRegisterHardwareWrite {register field} {
			if {[$field hasAttribute hardware.global.wo] || [$field hasAttribute hardware.global.rw]} {
				if {[$field hasAttribute hardware.global.hardware_wen]} {
					puts "			else if([$register name]_[$field name]_wen)"
					puts "			begin"
					if {[$field hasAttribute hardware.global.counter]} {
						puts "				[$register name]_[$field name]_load_enable <= 1'b1;"
						puts "				[$register name]_[$field name]_load_value <= [$register name]_[$field name]_next;"
					} else {
						puts "				[$register name]_[$field name] <= [$register name]_[$field name]_next;"
					}
					puts "			end"
				} else {
					puts "			else"
					puts "			begin"
					puts "				[$register name]_[$field name] <= [$register name]_[$field name]_next;"	
					puts "			end"
				}	
			}	
	}

	# write Software register write calls hardware register write
	proc writeRegisterSoftwareWrite {object register} {
		set reg_size [expr [$object size]/8]
		set lowerBound 0
		$register onEachField {
			set upperBound [expr $lowerBound+[$it width]]
			if {[$it hasAttribute software.global.wo] || [$it hasAttribute software.global.rw]} {
				puts "			if((address\[[expr [getAddrBits $registerFile]-1]:3\]== [expr [$register getAbsoluteAddress]/8]) && write_en)"
				puts "			begin"
				if {[$it hasAttribute hardware.global.counter]} {
					puts "				[$register name]_[$it name]_load_enable <= 1'b1;"
					puts "				[$register name]_[$it name]_load_value <= write_data\[[expr $upperBound-1]:$lowerBound\];"
				} else {
					puts "				[$register name]_[$it name] <= write_data\[[expr $upperBound-1]:$lowerBound\];"
				}
				puts "			end"
				if {[$it hasAttribute hardware.global.wo] || [$it hasAttribute hardware.global.rw]} {
					writeRegisterHardwareWrite $register $it
					if {[$it hasAttribute hardware.global.counter]} {
						puts "			else"
						puts "			begin"
						puts "				[$register name]_[$it name]_load_enable <= 1'b0;"
						puts "			end"
					}
				}
				if {[$it hasAttribute hardware.global.software_written]} {
					if {[$it getAttributeValue hardware.global.software_written]==2} {
						puts "			if(((address\[[expr [getAddrBits $registerFile]-1]:3\]== [expr [$register getAbsoluteAddress]/8]) && write_en) || [$register name]_[$it name]_res_in_last_cycle)"
						puts "			begin"
						puts "				[$register name]_[$it name]_written <= 1'b1;"
						puts "				[$register name]_[$it name]_res_in_last_cycle <= 1'b0;"
						puts "			end"
						puts "			else"
						puts "			begin"
						puts "				[$register name]_[$it name]_written <= 1'b0;"
						puts "			end"
						puts ""															
					} else {
						puts "			if((address\[[expr [getAddrBits $registerFile]-1]:3\]== [expr [$register getAbsoluteAddress]/8]) && write_en)"
						puts "			begin"
						puts "				[$register name]_[$it name]_written <= 1'b1;"
						puts "			end"
						puts "			else"
						puts "			begin"
						puts "				[$register name]_[$it name]_written <= 1'b0;"
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

	# write the register function // rewrite this there is with if else constructs...
	proc writeRegister {object} {
		$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				writeRegister $it
			} else {

				# Write always block
				puts "	/* register [$it name] */"
				puts "	`ifdef ASYNC_RES"
				puts "	always @(posedge clk or negedge res_n) `else"
				puts "	always @(posedge clk) `endif"
				puts "	begin"

				# Write reset logic
				writeReset $it

				# Write register logic
				puts "		else"
				puts "		begin"
				puts ""
				writeRegisterSoftwareWrite $object $it
				puts "		end"

				puts "	end"
				puts ""
			}
		}
	}

	#write the address logic for reading and invalid signal 
	proc writeAddressControl {object} {
		$object onEachComponent {
			if {[$it isa osys::rfg::Group]} {
				writeAddressControl $it
			} else {
				set register $it
				puts "				[expr [getAddrBits $object]-3]'h[format %x [expr [$register getAbsoluteAddress]/8]]:"
				puts "				begin"
				set lowerBound 0
				$it onEachField {
					set upperBound [expr $lowerBound+[$it width]]
					if {[$it hasAttribute software.global.ro] || [$it hasAttribute software.global.rw]} {
						
						puts "					read_data\[[expr $upperBound-1]:$lowerBound\] <= [$register name]_[$it name];"
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
<% writeTemplate $registerFile %>);
*/
module <%puts [$registerFile name]%>(
	///\defgroup sys
	///@{ 
	input wire res_n,
	input wire clk,
	///}@ 
	///\defgroup rw_if
	///@{ 
	input wire[<% puts -nonewline "[expr [getAddrBits $registerFile]-1]"%>:<%puts -nonewline "[ld [expr [$registerFile register_size]/8]]"%>] address,
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
<% writeCounterModule $registerFile %>
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
		end
		else
		begin
			casex(address[<% puts -nonewline "[expr [getAddrBits $registerFile]-1]"%>:<%puts -nonewline "[ld [expr [$registerFile register_size]/8]]"%>])
<% writeAddressControl $registerFile %>				default:
				begin
					invalid_address <= read_en || write_en;
					access_complete <= read_en || write_en;
				end		
			endcase
		end
	end
endmodule