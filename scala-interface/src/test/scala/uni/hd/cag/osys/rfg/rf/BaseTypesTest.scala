/*

RFG Register File Generator
Copyright (C) 2014  University of Heidelberg - Computer Architecture Group

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/
package uni.hd.cag.osys.rfg.rf

import com.idyria.osi.ooxoo.core.buffers.structural._
import org.scalatest._


class BaseTypesTest extends FeatureSpec with ShouldMatchers with GivenWhenThen {

  feature("Verilog Value") {

    scenario("Hex Value") {

      var buffer = VerilogLongValue(0)
      expectResult("abcd")(java.lang.Long.toHexString(buffer.dataFromString("16'hABCD")))

      buffer = VerilogLongValue(0)
      var du = new DataUnit
      du.value = "16'hABCD"
      buffer.importDataUnit(du)

      expectResult("abcd")(java.lang.Long.toHexString(buffer.data))
    }

    scenario("Binary Value") {

      var buffer = new VerilogLongValue()

      expectResult("a")(java.lang.Long.toHexString(buffer.dataFromString("4'b1010")))
      expectResult("3aba")(java.lang.Long.toHexString(buffer.dataFromString("16'b011101010111010")))

    }

    scenario("Decimal Value") {

      var buffer = new VerilogLongValue()
      expectResult("444c")(java.lang.Long.toHexString(buffer.dataFromString("32'd17484")))

    }

    scenario("Decimal Value with empty value") {

      var buffer = new VerilogLongValue()
      expectResult("0")(java.lang.Long.toHexString(buffer.dataFromString("32'd")))

    }
  }

  feature("Field Bits") {

    scenario("One Register with one 64 bit field") {

      /* var register= new Register
        var addr = new Field()
        addr.parentRegister = register
        addr.width = 64
        
        // Write Value 0x15f0
        addr.value = 0x15f0
        
        // Return should be 0x15f0
        expectResult(0x15f0)(register.valueBuffer.data)*/

      /*var res = TeaBitUtil.setBits(0x15f4,0,63,0x15f0)
        expectResult(0x15f0)(res)*/

      // Single Bit Sets
      //-------------------------
      var res = Field.setBits(0, 0, 0, 1)
      expectResult(1)(res)
      
      res = Field.setBits(0, 1, 1, 1)
      expectResult(2)(res)
      
      res = Field.setBits(0x15f4, 0, 63, 0x15f0)
      expectResult(0x15f0)(res)

      res = Field.setBits(0x15f0, 0, 63, 0x15f4)
      expectResult(0x15f4)(res)

      res = Field.setBits(0, 63, 63, 1)
      expectResult('1')(res.toBinaryString(63 - 63))

      //expectResult(0x15f4)(res) 

      // Multiple bit sets
      //------------------------------
      
      //-- Set 3 times '1' at 3 positions
      var res2 = Field.setBits(0, 0,0, 1)
      res2 = Field.setBits(res2, 2,2, 1)
      res2 = Field.setBits(res2, 4,4, 1)
      expectResult("10101")(res2.toBinaryString)
      
      //-- Reset only one bit in the middle
      var resettedOne =  Field.setBits(res2, 2,2, 0)
      expectResult("10001")(resettedOne.toBinaryString)
      
      //-- Reset previous '1'
      var reseted1 = Field.setBits(res2, 0,0,0)
      reseted1 = Field.setBits(reseted1, 2,2, 0)
      reseted1 = Field.setBits(reseted1, 4,4, 0)
      expectResult("0")(reseted1.toBinaryString)
      
      var reseted2 = Field.setBits(res2, 0,4,0)
      expectResult("0")(reseted2.toBinaryString)
      
    }

  }

}
