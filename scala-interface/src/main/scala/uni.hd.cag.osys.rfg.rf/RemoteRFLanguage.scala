package uni.hd.cag.osys.rfg.rf

import com.extoll.rma2.device._
import uni.hd.cag.osys.rfg.rf.device._


trait RemoteRFLanguage extends RFLanguage {
  //var registerFileDefinition:String  = "tourmalet_extoll_rf.anot.xml"
  //println("about to make registerfile at " + registerFileDefinition)
  val registerFile: RegisterFile //= RegisterFile(getClass.getResource("/"+registerFileDefinition))
  
  //println("made register file at " + registerFile)
  
  val knownNodes = scala.collection.mutable.Map[Int, RegisterFileHost]()
  
  def onNode[T <: Any](nodeId: Short)(cl: => T): T = {
    
    if (Device.targetDevice != RMA2Device) {
      throw new Exception("wrong target device!")
    }
    
    val rf = knownNodes.getOrElseUpdate(nodeId, new DummyRegisterfileHost(nodeId, registerFile))
      
    on(rf) {
      cl
    } 
  }
}
