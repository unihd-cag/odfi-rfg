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
package uni.hd.cag.osys.rfg.rf2.device

/**
 *
 * Common trait for a Device to which we can read/write registers to
 *
 * @author rleys
 *
 */
trait Device {

  /**
   * Should throw an exception if the Device could not be opened
   */
  def open 
  
  /**
   * Frees resources
   */
  def close
  
  /**
    Should Return a Long value for the register @ provided address

  */
  def readRegister( nodeId : Short, address : Long, size: Int) : Option[Array[Long]]

  /**
    Writes the register value @ provided address
  */
  def writeRegister( nodeId : Short, address : Long, value :Array[Long])



}

/**
    The Device Singleton is the Read/Write interface for registers

    It delivers read/writes to the underlying Device implementation.
    Thus there is only one active Device interface at any time,  but this is the whished behavior


*/
object Device extends Device {

    var targetDevice : Device = null

     def open = {
      
    }
  
     def close = {
       
       if (this.targetDevice==null)
              throw new RuntimeException("Cannot use Device before that a Device.targetDevice has been properly set up")
       this.targetDevice.close
       
     }
    
    def readRegister( nodeId : Short, address : Long,size: Int) : Option[Array[Long]] = {

          if (this.targetDevice==null)
              throw new RuntimeException("Cannot use Device before that a Device.targetDevice has been properly set up")

          this.targetDevice.readRegister(nodeId,address,size)

    }

    def writeRegister( nodeId : Short, address : Long, value : Array[Long]) = {

          if (this.targetDevice==null)
              throw new RuntimeException("Cannot use Device before that a Device.targetDevice has been properly set up")

          this.targetDevice.writeRegister(nodeId,address,value)

    }

}
