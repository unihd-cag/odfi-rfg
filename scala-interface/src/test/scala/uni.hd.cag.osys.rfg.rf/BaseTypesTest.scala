package uni.hd.cag.osys.rfg.rf

import  com.idyria.osi.ooxoo.core.buffers.structural._
 
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
    }

}
