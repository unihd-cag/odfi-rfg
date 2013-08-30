package uni.hd.cag.osys.rfg.rf


import com.idyria.osi.ooxoo.core.buffers.extras.transaction._

/**
    This trait is used to give some objects the entry points to starting interaction with a register file.

    A register file interaction is always following the same procedure:

    - Begin a transaction with current object as initiator
       - The initiator must be a Node object type
    - Do some work
    - commit the transaction/rollback if an error occured



*/
trait RegisterFileHost {

    /**
        The instance of the Register File  to be used
    */
    var registerFile : RegisterFile

    /**
        The ID of the target host whose registerfile is to be interacted with
    */
    var id : Short

    def onRegisterFile( closure : (RegisterFile => Unit)) = {


        // Begin Transaction
        //----------------------
        Transaction(this)

        // Execute
        //--------------
        try {
            closure(registerFile)

             // Commit
            //---------------
            Transaction().commit


        } catch {

            // Rollback
            //------------
            case e : Throwable =>
                //Transaction(t).rollback
                throw e



        } finally {
            println("-- Discard transaction --")
            Transaction.discard()

        }






    }

    def register( search : String )(implicit closure: Register => Unit) : Unit = {

        this.onRegisterFile(_.register(search)(closure))

    }

    def registerValue( search : String ) : Long = {

        println("-- Get Register Value --")
        var value : Long = 0
        this.onRegisterFile {

            rf =>
               var reg = rf.register(search)
               value = reg.value

        }
        value

    }


}

class DummmyRegisterfileHost (

    var id  : Short,
    var registerFile : RegisterFile


    ) extends RegisterFileHost {


}
