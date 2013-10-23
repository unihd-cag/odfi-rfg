package uni.hd.cag.osys.rfg.rf

import org.scalatest._
import uni.hd.cag.osys.rfg.rf.RFLanguage
import uni.hd.cag.osys.rfg.rf.device.Device
import uni.hd.cag.osys.rfg.rf.device.simulation.SimpleSimulationDevice


class RegisterFileLanguageTest extends FunSuite with ShouldMatchers {

  
    test("Simple Language test")  {
      
      // Create a RF Host to have access to API
      //-------------
      val registerFile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
      var rfHost = new DummyRegisterfileHost(0,registerFile)
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
    




}


