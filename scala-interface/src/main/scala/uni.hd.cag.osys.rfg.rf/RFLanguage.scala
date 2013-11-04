package uni.hd.cag.osys.rfg.rf


import com.idyria.osi.ooxoo.core.buffers.structural.xelement
import scala.language.implicitConversions
import com.idyria.osi.ooxoo.core.buffers.extras.transaction.Transaction

/**
 * This trait provides a lightweight language to write and read from register content
 * 
 * It is thought to be mixed in a class containing the actual implementation code
 * 
 */
trait RFLanguage {

 // var currentHost : RegisterFileHost = null
  
  // Current Host
  //--------------------
  
  /**
   * Try to find currentHost through transaction
   */
  def currentHost : RegisterFileHost= {
    
    Transaction().initiator match {
      case null => 
        throw new RuntimeException("Using RFLanguage interface outside of a transaction created with an initiator which must be a RegisterFileHost instance")
      
      case host : RegisterFileHost => 
        
        
        host
        
      case initiator => 
        
        throw new RuntimeException(s"Using RFLanguage interface outside of a transaction created with an initiator which must be a RegisterFileHost instance (currently: ${initiator.getClass()})")
      
       
    }
    
  }
  
  
  /**
   * Opens a transaction on a node, must be called before any operation using a RF language instance
   */
  def on(rf: RegisterFileHost)(cl: => Any) : Unit = {
    
   // currentHost = rf
    rf.onRegisterFile {
      rf => cl
    }
    
    
    
  }
  
  // Poll Language
  // poll "valueable" until value for time
  //---------------------
  

  /**
   * Warning
   */
  class Poll  {
    
    var location : String = _
    
    var value : (Long => Boolean) = {v => false}
    
    var time : Long = 0
    
    var resultValue : Long = 0
   
    
    /**
     * Executes
     */
    def now : Poll = {
      
      // Checks
      //------------
      (location,value,time) match {
        case (null,v,t) => throw new RuntimeException(s"Cannot poll on register because all location($location),value($value), and time($time) are not defined")
        case _ =>
      }
      
      // Do
      //----------
      
      //-- Take start time
      var currentTime = System.currentTimeMillis()
      
      //-- Value matched
      var matched = false
      
      //-- Read and update until time elapsed
      while( !matched && (System.currentTimeMillis()-currentTime) < time) {
        
        read(location) match {
          case ok if( value(ok) == true) => resultValue = ok ; matched = true
          case v => resultValue = v
        }
      }
      
      //-- Result
      matched match {
        case true => this
        case false => 
          throw new RuntimeException(s"Polling failed on register $location waiting for value $value, timed out after $time milliseconds. Last value: $resultValue ")
      }
      
    }
    
    def on(l: String) : Poll = {
      
      this.location = l
      this
    }
    
    def until(value: Long => Boolean) : Poll = {
      this.value = value
      this
    }
    
    /**
     * Time is in milliseconds
     */
    def during(time: Long) : Poll = {
      this.time = time
      this
    }

    
  }
  object Poll {
    
    def unapply(i: Poll) : Option[Long] = {
      Some(i.resultValue)
    }
    
    
  }
  
  def poll : Poll = new Poll

  
  /**
   * Polls a register until it gets the stated value
   * 
   * Per default, stop polling
   * 
   */
  def poll(expect: (String,Long)) : Unit = {
    
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
      
      currentHost.registerFile.search(destination) match {
         case r : Register => r.value = value
         case f: Field => f.value = value
         case _ => throw new RuntimeException("unsupported path: $str")
      }
      
      
      this
    }
    
    def into(destination: (Group,String)) : Destination = {
      
      destination._1.search(destination._2) match {
         case r : Register => r.value = value
         case f: Field => f.value = value
         case _ => throw new RuntimeException("unsupported path: $str")
      }
      
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
  //def write : Destination = new Destination(0)
  
  /**
   * Creates a destination from a value
   * 
   * Ex: write(80) into "/path/to/destination"
   */
  def write(v:Long) : Destination = new Destination(v)
  
  
  
}