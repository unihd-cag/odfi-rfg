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
