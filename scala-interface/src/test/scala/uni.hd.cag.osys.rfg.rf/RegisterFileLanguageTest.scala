package uni.hd.cag.osys.rfg.rf

import org.scalatest._
import uni.hd.cag.osys.rfg.rf.RFLanguage


class RegisterFileLanguageTest extends FunSuite with ShouldMatchers {

  
    test("Simple Language test")  {
      
      // Create a RF Host to have access to API
      //-------------
      val registerFile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
      var rfHost = new DummyRegisterfileHost(0,registerFile)
      
      // Try a script language, it must compile
      //----------------
      var value = 0x80L
      
      
      
      val sscript = new RFLanguage {
        
 

        on(rfHost) {
          
          //write(80 into "extoll_rf/info_rf/node[12]")
          
          write(80) into "extoll_rf/info_rf/node[12]"
          80 into "extoll_rf/info_rf/node[12]"
          
          
          
          80 :-> "extoll_rf/info_rf/node[12]"
          
          write :-> 80 into "extoll_rf/info_rf/node[12]"
        
         
          /*
          // Get a reference to a register/field etc... using select						
          var reg = select register ""
          var reg = register ""
          var field =""
          
          
          write 80 to  "extoll_rf/info_rf/node[12]"
          
          write 80 to  "extoll_rf/info_rf/node@nodeId"
          
          write 80 to  reg
          
         
          
          // Write from reg/field to other reg/field using String
          write "extoll_rf/info_rf/node" 		to "extoll_rf/info_rf/node"
          write "extoll_rf/info_rf/node@nodeId" to "extoll_rf/info_rf/node@nodeId"
          
          write (read register) 				to "extoll_rf/info_rf/node@nodeId"
          
          // Normal LValue
          register "////" <= 80
          
          register("///").value = 80
          
          // Read
          read register
          read from register
          
          
          
          //----
          (node1,node2).foreach {
            
            node => 
            
          }
          
          
          on(node1,node2) {
            
            read "/nodeid"
            
          }
          
          on(node1) {
            
            
            
          }*/
          
        }
        
        
      }
      
    }
    




}


