package uni.hd.cag.osys.rfg.rf.device.remote

import com.idyria.osi.wsb.core.message.soap.SOAPMessagesHandler
import uni.hd.cag.osys.rfg.rf.device.Device




object RFHandler extends SOAPMessagesHandler {
  
  /**
   * Handle reads
   */
  on[ReadRequest] {
    (message,request) => 
      
      // Read
      val readValue = Device.readRegister(request.nodeID.toShort, request.address) match {
        case Some(v) => v
        case None => throw new RuntimeException(s"Could not read value from nodeID ${request.nodeID} @0x${request.address.data.toInt.toHexString}")
      }
      
      
      // Send Response
      val response = ReadResponse()
      response.value = readValue
      
      response
  }
  
  on[WriteRequest] {
    (message,request) => 
      
      // Write
      Device.writeRegister(request.nodeID.toShort, request.address,request.value)
      
      // response
      WriteResponse()
  }
  
}

