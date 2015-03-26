
## RFG Register File Generator
## Copyright (C) 2014  University of Heidelberg - Computer Architecture Group
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


## Groups
########################

attributeGroup ::hardware
attributeGroup ::software

## Rights
########################

attributeFunction ::rw
attributeFunction ::ro
attributeFunction ::wo

## Verilog specials
########################

attributeFunction ::counter
attributeFunction ::rreinit
attributeFunction ::rreinit_source
attributeFunction ::software_written
attributeFunction ::wen
attributeFunction ::no_wen
attributeFunction ::sticky
attributeFunction ::write_xor
attributeFunction ::external
attributeFunction ::internal
attributeFunction ::clear
attributeFunction ::write_clear
attributeFunction ::shared_bus
attributeFunction ::edge_trigger

## Addressing
attributeFunction ::relative_address
attributeFunction ::absolute_address
attributeFunction ::absolute_start_address
attributeFunction ::absolute_end_address
attributeFunction ::aligner
attributeFunction ::size
attributeFunction ::address_shift

## RFG 
############
attributeFunction file 
attributeFunction line
