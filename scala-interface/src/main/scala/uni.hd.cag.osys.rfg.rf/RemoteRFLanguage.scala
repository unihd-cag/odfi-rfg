package uni.hd.cag.osys.rfg.rf

trait RemoteRFLanguage extends RFLanguage {
  
def remoteWrite(rf: RegisterFileHost, nodeId: Int, path: String, value: Long) = {
  var address: Long = 0
  var converted_value: Long = 0
  on(rf) {
    noIO{
      write(value) into path
      converted_value = read(path)
      address = search(path).asInstanceOf[NamedAddressedValued].absoluteAddress.toLong
    }
  }
  
  //write the values via rma
  
  }
def remoteRead(rf: RegisterFileHost, nodeId: Int, path: String): Long = {
  var value: Long = 0
  var address: Long = 0
  on(rf) {
    noIO{
      address = search(path).asInstanceOf[NamedAddressedValued].absoluteAddress.toLong
    }
  }
  
  //read from address via rma
  value
  }
}