package uni.hd.cag.osys.rfg.rf2.bulk

import org.scalatest.FunSuite
import uni.hd.cag.osys.rfg.rf2.device.Device
import uni.hd.cag.osys.rfg.rf2.language.DummyRegisterfileHost
import uni.hd.cag.osys.rfg.rf2.language.RFLanguage
import uni.hd.cag.osys.rfg.rf2.model.RegisterFile
import com.idyria.osi.ooxoo.core.buffers.extras.transaction.Transaction
import org.scalatest.GivenWhenThen

/**
 * @author zm4632
 */
class BulkTest extends FunSuite with RFLanguage with GivenWhenThen {

  var dummyRF = RegisterFile(getClass.getClassLoader.getResource("rf2/rf2_test.xml"))
  var dummyHost = new DummyRegisterfileHost(0, dummyRF)

  // Dummy Device 
  //------------------
  var dummyDevice = new Device {

    var sizeOfWrites = 0
    var numberOfWrites = 0
    var values: Array[Long] = new Array[Long](0)

    /**
     * Should throw an exception if the Device could not be opened
     */
    def open = {
      sizeOfWrites = 0
      numberOfWrites = 0
    }

    /**
     * Frees resources
     */
    def close = {

    }

    /**
     * Should Return a Long value for the register @ provided address
     *
     */
    def readRegister(nodeId: Short, address: Long, size: Int): Option[Array[Long]] = {
      var res = new Array[Long](size)
      println(s"Read")
      return Some(new Array[Long](size))
    }

    /**
     * Writes the register value @ provided address
     */
    def writeRegister(nodeId: Short, address: Long, value: Array[Long]) = {
      println("Go write " + value.length)
      value.foreach {
        v => println(s"--> $v")
      }
      this.sizeOfWrites += value.length
      numberOfWrites += 1
      this.values = value
    }

  }
  Device.targetDevice = dummyDevice

  test("Bulk Raw Test") {

    // Make a few Writes
    //-------------------
    When("1 Write in normal mode")

    dummyDevice.open
    on(dummyHost) {
      write(0xA) into ("test")
    }
    assertResult(1)(dummyDevice.sizeOfWrites)
    assertResult(1)(dummyDevice.numberOfWrites)

    When("1 Write in buffering mode")

    dummyDevice.open
    on(dummyHost) {

      Transaction().buffer()

      write(0xA) into ("test")

      Transaction().commit()
      Transaction().discard()
    }
    assertResult(1)(dummyDevice.sizeOfWrites)
    assertResult(1)(dummyDevice.numberOfWrites)

    When("2 Writes in buffering mode")

    dummyDevice.open
    on(dummyHost) {

      Transaction().buffer()

      write(0xA) into ("test")
      write(0xB) into ("test")

      Transaction().commit()
      Transaction().discard()
    }
    assertResult(2)(dummyDevice.sizeOfWrites)
    assertResult(1)(dummyDevice.numberOfWrites)
    assertResult(0xB)(dummyDevice.values(dummyDevice.sizeOfWrites - 1))

  }

  test("Bulk Language test") {

  }

  test("Bulk Field no Write") {

    dummyDevice.open
    onBuffering(dummyHost) {
      
      println("TR State: "+Transaction().state)
      var reg = register("test")
      reg.read()
      
      // Update 1 : 11
      //------------------------
      
      // Select then update
      var a = reg.a
      a.setMemory(1)

      // Select and update
      reg.b = 1

      reg.write()
      
      // Update 2 : 01
      //------------------------
      reg.a = 1
      reg.b = 0
      reg.write()
      
      // Update 3 : 10
      //------------------------
      reg.a = 0
      reg.b = 1
      reg.write()

    }
    assertResult(1)(dummyDevice.numberOfWrites)
    assertResult(3)(dummyDevice.sizeOfWrites)
    
    // Values check
    assertResult(3)(dummyDevice.values(0))
    assertResult(1)(dummyDevice.values(1))
    assertResult(2)(dummyDevice.values(2))
    

  }

}