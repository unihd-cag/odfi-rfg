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

import com.idyria.osi.ooxoo.core.buffers.structural.BaseBufferTrait
import com.idyria.osi.ooxoo.core.buffers.structural.DataUnit
import uni.hd.cag.osys.rfg.rf.NamedAddressed
import uni.hd.cag.osys.rfg.rf2.language.RegisterFileHost
import uni.hd.cag.osys.rfg.rf2.model.AttributesContainer

/**
 *
 * This ooxoo buffer pushes and pulls Data Units to the main Device class.
 *
 * - DataUnit string value contains the long value of the read/write register
 * - DataUnit Context contains following:
 * - transactionId to group read/writes together
 *
 *
 *
 */
class DeviceInterfaceBuffer extends BaseBufferTrait {

  // DU Context Informations
  //---------------

  def getNodeAndTarget(du: DataUnit): Option[(RegisterFileHost, AttributesContainer)] = {

    (du("node"), du("target")) match {

      case (Some(node), Some(target)) =>
        Option(node.asInstanceOf[RegisterFileHost], target.asInstanceOf[AttributesContainer])
      case _ =>
        None
    }
  }

  // Read (catch pull operation for this)
  //--------------------

  override def pull(du: DataUnit) = {
  
     var readSize = du("size").asInstanceOf[Option[Int]].getOrElse(1)
     
    // Gather context and perform
    //---------------
    this.getNodeAndTarget(du) match {

      // Host is a Device also, map to it instead of global singleton device
      //----------------
      
      case Some((host: Device, target)) =>

        var absoluteAddress = target.findAttributeLong("software.osys::rfg::absolute_address").get
        host.readRegister(host.id, absoluteAddress,readSize) match {
          case Some(value) => 
              du.value = value(0).toString
              du("buffer" -> value)
          case _ =>
        }
        du

      // Host and Register, Use global Singleton Device
      //--------
      case Some((host, target)) =>

        var absoluteAddress = target.findAttributeLong("software.osys::rfg::absolute_address").get
        Device.readRegister(host.id, absoluteAddress,readSize) match {
          case Some(value) => 
              du.value = value(0).toString
              du("buffer" -> value)
          case _ =>
        }
        du
      case None =>
        throw new IllegalArgumentException(s"""Cannot Perform Device write from Data Unit because Node and/or register are missing from DataUnit context, node: ${du("node")}, register: ${du("register")}""")
    }

  }

  // Write (catch push operation for this)
  //---------------

  /**
   * Added Register + Node context to data Unit
   */
  override def pushRight(du: DataUnit) = {

    var value = du("buffer") match {
      case Some( values) => values.asInstanceOf[Array[String]].map(_.toLong) 
      case None => Array(java.lang.Long.decode(du.value).toLong)
        
    }
    //println(s"Push to driver: "+value.length)
    
    // Gather context and perform
    //---------------
    this.getNodeAndTarget(du) match {

      // Host is a Device also, map to it instead of global singleton device
      //----------------
      case Some((host: Device, target)) =>

        var absoluteAddress = target.findAttributeLong("software.osys::rfg::absolute_address").get
        host.writeRegister(host.id, absoluteAddress, value)

      // Host and Register, Use global Singleton Device
      //--------
      case Some((host, target)) =>

        var absoluteAddress = target.findAttributeLong("software.osys::rfg::absolute_address").get
        Device.writeRegister(host.id, absoluteAddress,value)
      case None =>
        throw new IllegalArgumentException("Cannot Perform Device write from Data Unit because Node and/or register are missing from DataUnit context")
    }

  }

}
