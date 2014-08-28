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

import org.scalatest._

import com.idyria.osi.ooxoo.core.buffers.extras.transaction._
import com.idyria.osi.ooxoo.core.buffers.structural._
import com.idyria.osi.ooxoo.core.buffers.datatypes._

import uni.hd.cag.osys.rfg.rf._
import uni.hd.cag.osys.rfg.rf.device._
import uni.hd.cag.osys.rfg.rf.device.simulation._

import scala.language.implicitConversions

// Test Purpose Implementation classes
  //------------------
  class TestDevice extends Device {

    var values = Map[Long, Long]()

    var readCount = 0

    var writeCount = 0

    def open = {

    }

    def close = {

    }

    def readRegister(nodeId: Short, address: Long): Option[Long] = {

      readCount += 1

      this.values.get(address) match {
        case Some(value) => Option(value)
        case None        => None
      }

    }

    def writeRegister(nodeId: Short, address: Long, value: Long) = {

      writeCount += 1

      this.values = this.values + (address -> value)

    }

  }

class RegisterFileTransactionTest extends FeatureSpec with ShouldMatchers with GivenWhenThen with BeforeAndAfter with BeforeAndAfterEach {

  var registerfile: RegisterFile = _

  var nodeRegisterPath = "extoll_rf/info_rf/node"

  before {
    registerfile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
  }

  /**
   * Clean transactions
   */
  override def beforeEach = {
    Transaction.discardAll
  }

  

  class TestNode(rf: RegisterFile, nid: Short) extends DummyRegisterfileHost(id = nid, registerFile = rf) {

    /*var nodeId : Short = nid
        var guid : Short =  nid
        var registerFile = rf*/

  }

  //  Tests
  //-----------------------

  feature("Register Interface Buffer") {

    scenario("Read value without context") {

      Given("A register")

      // "extoll_rf/info_rf/node"
      var node = registerfile.register(nodeRegisterPath)

      Then("Reading its value should trigger an exception")
      intercept[RegisterTransactionException] {
        node.value.pull()
      }

    }

    scenario("Read value with wrong initiator context") {

      Given("A register")
      var node = registerfile.register(nodeRegisterPath)

      Then("Reading its value should trigger an exception")
      Transaction(this)
      intercept[RegisterTransactionException] {
        node.value.pull()
      }

    }

    scenario("Read value with correct Transaction") {

      Given("A register")

      var node = registerfile.register(nodeRegisterPath)

      And("A Transaction with a Node initiator")

      var nodeObj = new TestNode(this.registerfile, 0)
      Transaction(nodeObj)

      And("A test Device")

      var testDevice = new TestDevice
      Device.targetDevice = testDevice

      Then("Getting buffer value should return reset value from register")

      node.value.pull()
      assertResult("100adfeabcd1a")(java.lang.Long.toHexString(node.value))

      /*assertResult(None)(node.value.toString)

            And("Reading again should return buffered value from Transaction")

                 //node.value.pull()
                 //assertResult("42")(node.value.toString)*/

    }

    scenario("Write value with correct Transaction") {

      Given("A register")

      var node = registerfile.register(nodeRegisterPath)

      And("A Transaction with a Node initiator")

      Transaction(new TestNode(this.registerfile, 0))

      And("A test Device")

      var testDevice = new TestDevice
      Device.targetDevice = testDevice

      Then("Write 80 to the data buffer and commit transaction should give 80 to the test device")

      node.value.set(80)
      Transaction().commit

      assertResult(1, "Write Count must be 1")(testDevice.writeCount)
      assertResult(80)(testDevice.values(node.absoluteAddress))

    }

  }

  feature("Node RegisterFile Interface with Simulation Device") {

    scenario("Read on RegisterFile From one node") {

      Given("A Node with RegisterFile and Simple Simulation Device")

      var nodeObj = new TestNode(this.registerfile, 0)
      Device.targetDevice = new SimpleSimulationDevice

      Then("Do Some stuff on its registerfile")

      nodeObj onRegisterFile {

        rf =>

          var node = rf.register(nodeRegisterPath)
          node.pull
        //assertResult()(node.)

      }

      var res: Long = nodeObj.registerValue(nodeRegisterPath)

      assertResult("100adfeabcd1a")(java.lang.Long.toHexString(res))

    }

    scenario("Write/Read on RegisterFile From Two node") {

      Given("Two nodes with RegisterFile and Test Device")

      var node0Obj = new TestNode(this.registerfile, 0)
      var node01Obj = new TestNode(this.registerfile, 1)
      var testDevice = new SimpleSimulationDevice
      Device.targetDevice = testDevice

      Then("Write Two Values")
      node0Obj onRegisterFile {
        rf =>

          rf.register(nodeRegisterPath).value = 80
      }
      node01Obj onRegisterFile {
        rf =>

          rf.register(nodeRegisterPath).value = 81
      }

      Then("Read Back values should return matching results")
      assertResult(80)(node0Obj.registerValue(nodeRegisterPath))
      assertResult(81)(node01Obj.registerValue(nodeRegisterPath))

    }

    scenario("Change a field value") {

      Given("A Node with RegisterFile and Simple Simulation Device")

      var nodeObj = new TestNode(this.registerfile, 0)
      Device.targetDevice = new SimpleSimulationDevice

      Then("Change id field value of node register")

      nodeObj onRegisterFile {

        rf =>

          var node = rf.register(nodeRegisterPath)

          var nodeIdField = node.field("id")

          // Verify value change
          //----------------------------
          assertResult("100adfeabcd1a")(java.lang.Long.toHexString(node.value))

          //-- Change id 
          nodeIdField.value = java.lang.Long.decode("0xADCE")
          assertResult("100adceabcd1a")(java.lang.Long.toHexString(node.value))
        //assertResult()(node.)

      }

      // Chec kagainst complete register
      var res: Long = nodeObj.registerValue(nodeRegisterPath)
      assertResult("100adceabcd1a")(java.lang.Long.toHexString(res))

    }

  }

  feature("Read Value from transaction") {

    scenario("Two nodes sequential") {

      //--------------------
      Given(s"The $nodeRegisterPath register")

      var node = registerfile.register(nodeRegisterPath)

    }

    scenario("Two nodes in two threads")(pending)
  }

  feature("Write Value from transaction") {

    scenario("Two nodes sequential")(pending)

    scenario("Two nodes in two threads")(pending)
  }

  feature("Read from transaction with non working device") {

    scenario("Transation Error")(pending)

    scenario("Transaction Error, then active device and validate transaction")(pending)

  }

  feature("Write transaction with errors") {

    scenario("Throw an exception in a transaction")(pending)

  }

}


