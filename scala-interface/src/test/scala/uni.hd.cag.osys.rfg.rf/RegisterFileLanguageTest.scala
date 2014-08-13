package uni.hd.cag.osys.rfg.rf

import org.scalatest._
import uni.hd.cag.osys.rfg.rf.RFLanguage
import uni.hd.cag.osys.rfg.rf.device.Device
import uni.hd.cag.osys.rfg.rf.device.simulation.SimpleSimulationDevice
import com.idyria.osi.ooxoo.core.buffers.extras.transaction.Transaction

class RegisterFileLanguageTest extends FunSuite with ShouldMatchers  with GivenWhenThen {

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
    Device.targetDevice = new SimpleSimulationDevice

    // Try a script language, it must compile
    //----------------
    val sscript = new RFLanguage {
    
      Given("A Blocking Transaction with a selected node")
      on(rfHost) {

        Then("A write should not fail")
        write(80) into "extoll_rf/info_rf/node"


      }
      
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
          assert(Transaction.currentTransactions(Thread.currentThread()).top.initiator!=null)
          
          And("A write should not fail")
          write(80) into "extoll_rf/info_rf/node"
          
        }
        
        When("Blocking transaction ends")
        Then("Only one Transaction remains")
        assertResult(1)(Transaction.currentTransactions(Thread.currentThread()).size)
        
      }

    }

  }

}


