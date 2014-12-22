package uni.hd.cag.osys.rfg.rf

trait RemoteRFLanguage extends RFLanguage {
  val registerFileDefinition = "extoll_rf.anot.xml"
  val registerFile = RegisterFile(getClass.getClassLoader().getResource(registerFileDefinition))
  
  val knownNodes = scala.collection.mutable.Map[Int, RegisterFileHost]()
  
  def onNode[T <: Any](nodeId: Short)(cl: => T): T = {
    val rf = knownNodes.getOrElseUpdate(nodeId, new DummyRegisterfileHost(nodeId, registerFile))
    on(rf) {
      cl
    } 
  }
}