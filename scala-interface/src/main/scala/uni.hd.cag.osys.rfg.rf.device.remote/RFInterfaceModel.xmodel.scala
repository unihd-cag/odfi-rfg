package com.extoll.mex.backend.interfaces.registerfile

import com.idyria.osi.ooxoo.model.out.scala._
import com.idyria.osi.ooxoo.model.out.scala._
import com.idyria.osi.ooxoo.model.out.markdown._
import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.producer
import com.idyria.osi.wsb.lib.soap.ProtocolBuilder
     
@producers(Array(
    new producer(value=classOf[ScalaProducer]),
     new producer(value=classOf[MDProducer])
)) 
object RFServiceModel extends ProtocolBuilder {  
  
    parameter("scalaProducer.targetPackage","uni.hd.cag.osys.rfg.rf.device.remote")

    namespace("rf" -> (s"http://github.com/unihd-cag/odfi-rfg/remote"))
      
    // Common Trait
    //-----------------
    val addressTarget = "rf:AddressTarget" is {
      isTrait
      
      attribute("address") ofType "long"
      attribute("nodeID") ofType "integer"
      
    }
    
    // Read
    //--------------
    message("rf:Read") {
      request {
        
        withTrait(addressTarget)
        
      }
      response {
        
        attribute("value") ofType "long"
        
      }
    }
    
    // Write
    //----------
    message("rf:Write") {
      request {
        
        withTrait(addressTarget)
        
        attribute("value") ofType "long"
        
      }
      
      response {
        
      }
    }
    
     
    
    
    
    

}
