/**
 *
 */
package uni.hd.cag.osys.rfg.rf.device

/**
 *
 * Common trait for a Device to which we can read/write registers to
 *
 * @author rleys
 *
 */
trait Device {

  /**
    Should Return a Long value for the register @ provided address

  */
  def readRegister( nodeId : Short, address : Long) : Option[Long]

  /**
    Writes the register value @ provided address
  */
  def writeRegister( nodeId : Short, address : Long, value : Long)



}

/**
    The Device Singleton is the Read/Write interface for registers

    It delivers read/writes to the underlying Device implementation.
    Thus there is only one active Device interface at any time,  but this is the whished behavior


*/
object Device extends Device {

    var targetDevice : Device = null

    def readRegister( nodeId : Short, address : Long) : Option[Long] = {

          if (this.targetDevice==null)
              throw new RuntimeException("Cannot use Device before that a Device.targetDevice has been properly set up")

          this.targetDevice.readRegister(nodeId,address)

    }

    def writeRegister( nodeId : Short, address : Long, value : Long) = {

          if (this.targetDevice==null)
              throw new RuntimeException("Cannot use Device before that a Device.targetDevice has been properly set up")

          this.targetDevice.writeRegister(nodeId,address,value)

    }

}
