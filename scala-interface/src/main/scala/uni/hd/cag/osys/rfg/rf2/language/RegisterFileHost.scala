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

 
import com.idyria.osi.ooxoo.core.buffers.extras.transaction._
import uni.hd.cag.osys.rfg.rf2.model.Register
import uni.hd.cag.osys.rfg.rf2.model.RegisterFile

/**
    This trait is used to give some objects the entry points to starting interaction with a register file.

    A register file interaction is always following the same procedure:

    - Begin a transaction with current object as initiator
       - The initiator must be a Node object type
    - Do some work
    - commit the transaction/rollback if an error occured



*/
trait RegisterFileHost extends RegisterFileNode {

    /**
        The instance of the Register File  to be used
    */
    var registerFile : RegisterFile


    def onRegisterFile[T <: Any]( closure : (RegisterFile => T)) : T = {


        // Begin Transaction
        //----------------------
        Transaction.begin(this)

        // Execute
        //--------------
        try {
            var res = closure(registerFile)

             // Commit
            //---------------
            Transaction().commit

            res

        } catch {

            // Rollback
            //------------
            case e : Throwable =>
                //Transaction(t).rollback
                throw e



        } finally {
            //println("-- Discard transaction --")
            Transaction.discard()

        }






    }

    def register( search : String )(implicit closure: Register => Unit) : Unit = {

        this.onRegisterFile(_.register(search)(closure))

    }

    def registerValue( search : String ) : Long = {

        //println("-- Get Register Value --")
        var value : Long = 0
        this.onRegisterFile {

            rf =>
               var reg = rf.register(search)
               value = reg.value.toLong

        }
        value

    }


}

class DummyRegisterfileHost (

    var id  : Short,
    var registerFile : RegisterFile


    ) extends RegisterFileHost {


}
