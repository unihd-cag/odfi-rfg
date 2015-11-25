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
package uni.hd.cag.osys.rfg.rf.device


import com.idyria.osi.ooxoo.core.buffers.structural._
import com.idyria.osi.ooxoo.core.buffers.datatypes._
import com.idyria.osi.ooxoo.core.buffers.extras.transaction._
 
import uni.hd.cag.osys.rfg.rf._

/**

    This ooxoo buffer pushes and pulls Data Units to the main Device class.

    - DataUnit string value contains the long value of the read/write register
    - DataUnit Context contains following:
       - transactionId to group read/writes together



*/
class DeviceInterfaceBuffer extends BaseBufferTrait {


    // DU Context Informations
    //---------------

    def getNodeAndTarget(du : DataUnit) : Option[(RegisterFileHost , NamedAddressed)] = {

        (du("node") , du("target")) match {

            case (Some(node),Some(target))  =>
                Option(node.asInstanceOf[RegisterFileHost],target.asInstanceOf[NamedAddressed])
            case _ =>
                None
        }
    }


    // Read (catch pull operation for this)
    //--------------------

    override def pull( du : DataUnit) = {

        // Gather context and perform
        //---------------
        this.getNodeAndTarget(du) match {
        	
        	// Host is a Device also, map to it instead of global singleton device
        	//----------------
          	case Some((host : Device,target)) => 
            
          	  host.readRegister(host.id,target.absoluteAddress) match {
                    case Some(value) => du.value = value.toString
                    case _ =>
                }
                du
          	  
        	// Host and Register, Use global Singleton Device
        	//--------
            case Some((host,target)) =>
                Device.readRegister(host.id,target.absoluteAddress) match {
                    case Some(value) => du.value = value.toString
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
        Added Register + Node context to data Unit
    */
    override def pushRight( du : DataUnit) = {

        // Gather context and perform
        //---------------
        this.getNodeAndTarget(du) match {

        	// Host is a Device also, map to it instead of global singleton device
        	//----------------
          	case Some((host : Device,target)) => 
            
          	  host.writeRegister(host.id,target.absoluteAddress,java.lang.Long.decode(du.value))
               
            // Host and Register, Use global Singleton Device
        	//--------
            case Some((host,target)) => 
              	Device.writeRegister(host.id,target.absoluteAddress,java.lang.Long.decode(du.value))
            case None =>
                throw new IllegalArgumentException("Cannot Perform Device write from Data Unit because Node and/or register are missing from DataUnit context")
        }


    }

}
