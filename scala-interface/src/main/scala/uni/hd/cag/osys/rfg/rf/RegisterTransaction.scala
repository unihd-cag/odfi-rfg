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
package uni.hd.cag.osys.rfg.rf

import com.idyria.osi.ooxoo.core.buffers.structural._
import com.idyria.osi.ooxoo.core.buffers.datatypes._
import com.idyria.osi.ooxoo.core.buffers.extras.transaction._
import uni.hd.cag.osys.rfg.rf.device._
import scala.language.implicitConversions
import com.idyria.osi.tea.listeners.ListeningSupport

/**

    The RegisterTransactionBuffer makes the interface between the value buffers of the various
    Registers objects, and the Device interface that really gets the value from Device implementation

   It is linked to a standard Transacitno Buffer for transaction management

   Determining the target node is done by the transaction context, meaning this Buffer can only be used
   if a transaction has been started, with the target node as Initiator


*/
class RegisterTransactionBuffer (

        /*
            The register this buffer is operating on
        */
        var target : NamedAddressed

    ) extends LongBuffer with ListeningSupport {


    // Chain: -> TransactionBuffer -> DeviceInterfaceBuffer
    //------------
    this.appendBuffer(new TransactionBuffer )
    this.appendBuffer(new DeviceInterfaceBuffer)


    // Transaction Context
    //-----------------------

    /**
        Get Current Node or throw an exception
    */
    def getContextNode : RegisterFileHost = {

        // Try to get the Target node from Transaction Context
        //----------------
        var currentTransaction = Transaction()

        currentTransaction.initiator match {

            case null =>

                    throw new RegisterTransactionException(target,s"No initiator provided in current transaction, cannot used registerfile without a node initiator")

            case initiator if (!initiator.isInstanceOf[RegisterFileHost]) =>

                    throw new RegisterTransactionException(target,s"The transaction initiator is not a Node type (Detected: ${initiator.getClass.getName}), which is mandatory to be able to send read/writes to the correct node")

            // Success :)
            case _ =>
        }

        currentTransaction.initiator.asInstanceOf[RegisterFileHost]

    }


    // Get (Override pull for this)
    //---------

    override def pull(du : DataUnit) : DataUnit = {

        // Set DataUnit Context
        //---------------

        du( "node" -> this.getContextNode)
        du( "target" -> this.target)

        // Delegate To Parent
        //--------------
        super.pull(du)

    }

    /**
        If no value returned, set to register reset value
    */
    override def importDataUnit( du : DataUnit) = {

        if (du.value==null) {

            //println(s"Reading register: ${this.register.name} , got no value, so setting to reset: ${this.register.getResetValue}")
            du.value = this.target match {
              case r: Register => r.getResetValue.toString
              case _ => "0"
            }

        }
        super.importDataUnit(du)

    }

    /*def get() : Long = {


        // Get initiator
        //-------------------
        var node = this.getContextNode



        // Perform Read
        //-----------------

        println("Calling set data on : "+this+" and "+register+"@"+register.absoluteAddress)
        this.data = Device.readRegister(0,register.absoluteAddress)


        // Return data
        this.data
    }*/


    // Put (catch push operation for this)
    //---------------

    /**
        Added Register + Node context to data Unit
    */
    override def push( du : DataUnit) = {

    	 this.@->("push")
      
        // Set DataUnit Context
        //---------------

        du( "node" -> this.getContextNode)
        du( "target" -> this.target)


        // Delegate to parent
        //----------
        super.push(du)

    }




}

/**

    The companion object of the register transaction buffer is used to retain current running transaction informations,
    so that single RegisterTransactionBuffers can determine if they are part of a transaction at the moment


*/
object RegisterTransactionBuffer {

    def apply(target : NamedAddressed) = new RegisterTransactionBuffer(target)

    // Conversion to/from long
    implicit def convertValueBufferToLong( b : RegisterTransactionBuffer) : Long = {b.pull();b.data }


}


class RegisterTransactionException(target : NamedAddressed,message : String)  extends Exception(s"On Register: ${target.name}, happened: $message") {





}
