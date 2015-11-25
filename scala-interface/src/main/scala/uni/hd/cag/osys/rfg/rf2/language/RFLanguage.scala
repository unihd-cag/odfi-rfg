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
package uni.hd.cag.osys.rfg.rf2.language

import com.idyria.osi.ooxoo.core.buffers.structural.xelement
import com.idyria.osi.ooxoo.core.buffers.extras.transaction.Transaction
import uni.hd.cag.osys.rfg.rf2.model.RamField
import uni.hd.cag.osys.rfg.rf2.model.Group
import uni.hd.cag.osys.rfg.rf2.model.Field
import uni.hd.cag.osys.rfg.rf2.model.Register
import uni.hd.cag.osys.rfg.rf2.model.RamEntry


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
  def currentHost: RegisterFileHost = {

    Transaction().initiator match {
      case null =>
        throw new RuntimeException("Using RFLanguage interface outside of a transaction created with an initiator which must be a RegisterFileHost instance")

      case host: RegisterFileHost =>

        host

      case initiator =>

        throw new RuntimeException(s"Using RFLanguage interface outside of a transaction created with an initiator which must be a RegisterFileHost instance (currently: ${initiator.getClass()})")

    }

  }

  /**
   * Opens a transaction on a node, must be called before any operation using a RF language instance
   */
  def on[T <: Any](rf: RegisterFileHost)(cl: => T): T = {

    // currentHost = rf
    rf.onRegisterFile {
      rf => cl
    }

  }

  /**
   * Opens a transaction on a node, must be called before any operation using a RF language instance
   * The transaction is running in blocking mode, which allows to use the registerfile without any device interaction
   */
  def onBlocking[T <: Any](rf: RegisterFileHost)(cl: => T) : T = {

    rf.onRegisterFile {
      rf =>
        Transaction.doBlocking {
          cl
        }
    }

  }
  
  
  
  /**
   * Creates a Blocking Nested transaction and commits it at the end of the closure
   */
  def onBlocking[T <: Any](cl: => T) : T = {
    Transaction.doBlocking {
      cl
    }
  }
  
  /**
   * Opens a transaction on a node, must be called before any operation using a RF language instance
   * The transaction is running in blocking mode, which allows to use the registerfile without any device interaction
   */
  def onBuffering[T <: Any](rf: RegisterFileHost = currentHost)(cl: => T) : T = {

    rf.onRegisterFile {
      rf =>
        Transaction.doBuffering {
          cl
        }
    }

  }
  
  /**
   * Creates a Blocking Nested transaction and discards it at the end of the closure
   */
  def noIO[T <: Any](rf: RegisterFileHost)(cl: => T) : T= {
    
    rf.onRegisterFile {
      rf =>
        Transaction.doBlocking {
          var res = cl
          Transaction.discard()
          res
        }
    }
  }
  
  /**
   * Creates a Blocking Nested transaction and discards it at the end of the closure
   */
  def noIO[T <: Any](cl: => T) :T = {
    Transaction.doBlocking {
      var res = cl
      Transaction.discard()
      res
    }
  }

  // Poll Language
  // poll "valueable" until value for time
  //---------------------

  /**
   * Warning
   */
  class Poll {

    var location: String = _

    var value: (Long => Boolean) = { v => false }

    var time: Long = 0

    var resultValue: Long = 0

    /**
     * Executes
     */
    def now: Poll = {

      // Checks
      //------------
      (location, value, time) match {
        case (null, v, t) => throw new RuntimeException(s"Cannot poll on register because all location($location),value($value), and time($time) are not defined")
        case _            =>
      }

      // Do
      //----------

      //-- Take start time
      var currentTime = System.currentTimeMillis()

      //-- Value matched
      var matched = false

      //-- Read and update until time elapsed
      while (!matched && (System.currentTimeMillis() - currentTime) < time) {

        read(location) match {
          case ok if (value(ok) == true) =>
            resultValue = ok; matched = true
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

    def on(l: String): Poll = {

      this.location = l
      this
    }

    def until(value: Long => Boolean): Poll = {
      this.value = value
      this
    }

    /**
     * Time is in milliseconds
     */
    def during(time: Long): Poll = {
      this.time = time
      this
    }

  }
  object Poll {

    def unapply(i: Poll): Option[Long] = {
      Some(i.resultValue)
    }

  }

  def poll: Poll = new Poll

  /**
   * Polls a register until it gets the stated value
   *
   * Per default, stop polling
   *
   */
  def poll(expect: (String, Long)): Unit = {

  }

  // Read Language
  //------------------------
  def read(str: String): Long = {

    currentHost.registerFile.search(str) match {
      case r: Register  => r.value.toLong
      case f: Field     => f.value
      case rf: RamField => rf.value
      case re: RamEntry =>  re.value.toLong
      case _            => throw new RuntimeException(s"unsupported path: $str")
    }

  }

  def read(destination: (Group, String)): Long = {

    destination._1.search(destination._2) match {
      case r: Register  => r.value.toLong
      case f: Field     => f.value
      case rf: RamField => rf.value
      case re: RamEntry => re.value.toLong
      case _            => throw new RuntimeException(s"unsupported path: ${destination._1}/${destination._2}")
    }

  }

  // Write Language
  //-----------------------
  class Destination(value: Long) {

    /**
     * Writes value to the destination by searching for the correct object
     */
    def into(destination: String): Destination = {

      currentHost.registerFile.search(destination) match {
        case r: Register  => r.value = value
        case f: Field     => f.value = value
        case rf: RamField => rf.value = value
        case re: RamEntry => re.value = value
        case _            => throw new RuntimeException(s"unsupported path: $destination")
      }

      this
    }

    def into(destination: (Group, String)): Destination = {

      destination._1.search(destination._2) match {
        case r: Register  => r.value = value
        case f: Field     => f.value = value
        case rf: RamField => rf.value = value
        case re: RamEntry => re.value = value
        case _            => throw new RuntimeException(s"unsupported path: ${destination._1}/${destination._2}")
      }

      this

    }

    def :->(destination: String): Destination = into(destination)

    def :->(destination: Destination): Destination = {

      this
    }

  }

  /**
   * Convert Value to Destination object for it to be applied to an object
   */
  implicit def longToDestination(i: Long): Destination = {
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
  def write(v: Long): Destination = new Destination(v)

  // Search
  //---------------
  def search(s: String): Any = {
    currentHost.registerFile.search(s)
  }
  
  
  // Register 
  //-------------------
  def register(s:String) : Register = {
    currentHost.registerFile.register(s)
  }

  // Explain
  //------------
  /*def explain(s: String): Unit = {
    search(s) match {
      case r: Register  => r.explain
      case f: Field     => println(s"Field: ${f.name} , value: ${f.value}")
      case rf: RamField => rf
      case r            => throw new RuntimeException(s"unsupported path for explanation: $s , type: ${r.getClass.getCanonicalName()}")
    }
  }*/

}
