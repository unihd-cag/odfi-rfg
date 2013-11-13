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

    def getNodeAndRegister(du : DataUnit) : Option[(RegisterFileHost , Register)] = {

        (du("node") , du("register")) match {

            case (Some(node),Some(reg))  =>
                Option(node.asInstanceOf[RegisterFileHost],reg.asInstanceOf[Register])
            case _ =>
                None
        }
    }


    // Read (catch pull operation for this)
    //--------------------

    override def pull( du : DataUnit) = {

        // Gather context and perform
        //---------------
        this.getNodeAndRegister(du) match {
        	
        	// Host is a Device also, map to it instead of global singleton device
        	//----------------
          	case Some((host : Device,register)) => 
            
          	  host.readRegister(host.id,register.absoluteAddress) match {
                    case Some(value) => du.value = value.toString
                    case _ =>
                }
                du
          	  
        	// Host and Register, Use global Singleton Device
        	//--------
            case Some((host,register)) =>
                Device.readRegister(host.id,register.absoluteAddress) match {
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
        this.getNodeAndRegister(du) match {

        	// Host is a Device also, map to it instead of global singleton device
        	//----------------
          	case Some((host : Device,register)) => 
            
          	  host.writeRegister(host.id,register.absoluteAddress,java.lang.Long.decode(du.value))
               
            // Host and Register, Use global Singleton Device
        	//--------
            case Some((host,register)) => 
              	Device.writeRegister(host.id,register.absoluteAddress,java.lang.Long.decode(du.value))
            case None =>
                throw new IllegalArgumentException("Cannot Perform Device write from Data Unit because Node and/or register are missing from DataUnit context")
        }


    }

}
