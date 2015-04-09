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
import uni.hd.cag.osys.rfg.rf.device.Device
import uni.hd.cag.osys.rfg.rf.device.simulation.SimpleSimulationDevice
import com.idyria.osi.ooxoo.core.buffers.extras.transaction.Transaction

class RegisterFileLanguageTest extends FunSuite with ShouldMatchers with GivenWhenThen {

  test("Simple Language test") {

    // Create a RF Host to have access to API
    //-------------
    val registerFile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
    var rfHost = new DummyRegisterfileHost(0, registerFile)
    Device.targetDevice = new SimpleSimulationDevice

    // Try a script language, it must compile
    //----------------
    var value = 0x80L

    val sscript = new RFLanguage {

      on(rfHost) {

        //write(80 into "extoll_rf/info_rf/node[12]")

        write(80) into "extoll_rf/info_rf/node"
        80 into "extoll_rf/info_rf/node"

        80 :-> "extoll_rf/info_rf/node"

        // write :-> 80 into "extoll_rf/info_rf/node[12]"

        // Read
        //----------

        // Poll
        //---------------

        //poll on "valueable" until 1 during 10

      }

    }

  }

  test("Blocking mode test") {

    // Create a RF Host to have access to API
    //-------------
    val registerFile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
    var rfHost = new DummyRegisterfileHost(0, registerFile)
    var testDevice = new TestDevice
    Device.targetDevice = testDevice

    // Try a script language, it must compile
    //----------------
    val sscript = new RFLanguage {

      Given("A Blocking Transaction with a selected node")
      onBlocking(rfHost) {

        Then("A write should not fail")
        write(80) into "extoll_rf/info_rf/node.id"

      }

      Then("One Write and no Read should have been issued ")
      assertResult(0)(testDevice.readCount)
      assertResult(1)(testDevice.writeCount)

      Given("A normal transaction")
      on(rfHost) {

        Then("One Transaction is defined on the Stack")
        assertResult(1)(Transaction.currentTransactions.size)
        assertResult(1)(Transaction.currentTransactions(Thread.currentThread()).size)

        When("Starting a nested Blocking transaction")
        onBlocking {

          Then("Two transactions are on the Stack")
          assertResult(2)(Transaction.currentTransactions(Thread.currentThread()).size)

          And("The Blocking transaction features an initiator")
          assert(Transaction.currentTransactions(Thread.currentThread()).top.initiator != null)

          And("A write should not fail")
          write(80) into "extoll_rf/info_rf/node.id"

        }

        When("Blocking transaction ends")
        Then("Only one Transaction remains")
        assertResult(1)(Transaction.currentTransactions(Thread.currentThread()).size)

        And("Now two Writes and no Read whould have been issued")
        assertResult(0)(testDevice.readCount)
        assertResult(2)(testDevice.writeCount)
        
      }

    }

  }

  test("No IO test") {

    // Create a RF Host to have access to API
    //-------------
    val registerFile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
    var rfHost = new DummyRegisterfileHost(0, registerFile)
    var testDevice = new TestDevice
    Device.targetDevice = testDevice

    new RFLanguage {

      val value = 80
      val registerPath = "extoll_rf/info_rf/node"
      val ramPath = "extoll_rf/pflash_rf/buffer_data[0]"
      Given("A NO IO blocking transaction")
      noIO(rfHost) {
        write(value) into registerPath 
      }

      Then("No read or write should have reached the Device")
      assertResult(0)(testDevice.readCount)
      assertResult(0)(testDevice.writeCount)
      
      And("The value written should be read from the Device")
      noIO(rfHost){
        assertResult(value)(read(registerPath))
      }

      Given("A NO IO blocking transaction to a ram")
      noIO(rfHost) {
        write(value) into ramPath
      }
      Then("The value written should be read from the ram")
      noIO(rfHost){
        val asdf = read(ramPath)
          assertResult(value)(asdf)
       }
    }

  }

}


