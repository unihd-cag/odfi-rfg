package uni.hd.cag.osys.rfg.rf

import uni.hd.cag.osys.rfg.rf.RegisterFileHost
import com.idyria.osi.ooxoo.core.buffers.structural.xelement


/**
 * This trait provides a lightweight language to write and read from register content
 * 
 * It is thought to be mixed in a class containing the actual implementation code
 * 
 */
trait RFLanguage {

  var currentHost : RegisterFileHost = null
  
  
  /**
   * 
   */
  def on(rf: RegisterFileHost)(cl: => Any) : Unit = {
    
    currentHost = rf
    rf.onRegisterFile {
      rf => cl
    }
    
    
    
  }
  
  // Read Language
  //------------------------
  def read(str: String) : Long = {
    
    currentHost.registerFile.search(str) match {
      case r : Register => r.value
      case f: Field => f.value
      case _ => throw new RuntimeException("unsupported path: $str")
    }
    
  }
  
  // Write Language
  //-----------------------
  class Destination(value: Long) {
    
    
    /**
     * Writes value to the destination by searching for the correct object
     */
    def into ( destination: String) : Destination = {
      
      this
    }
    
    def ->( destination: String) : Destination = into(destination)
    
    def :->(destination: String) : Destination= into(destination)
    
    def :->(destination: Destination) : Destination= {
      
      this
    }
    
   
    
  }
  
  /**
   * Convert Value to Destination object for it to be applied to an object
   */
  implicit def longToDestination(i:Long) : Destination = {
    var d = new Destination(i)
    d
  }
  
  
  /**
   * Creates a dummy destination for complex language:
   * 
   * Ex: write :-> (80) into "/path/to/destination"
   */
  def write : Destination = new Destination(0)
  
  /**
   * Creates a destination from a value
   * 
   * Ex: write(80) into "/path/to/destination"
   */
  def write(v:Int) : Destination = new Destination(v)
  
  
  
}