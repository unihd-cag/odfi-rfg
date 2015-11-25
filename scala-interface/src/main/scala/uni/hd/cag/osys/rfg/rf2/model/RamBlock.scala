package uni.hd.cag.osys.rfg.rf2.model


import com.idyria.osi.ooxoo.core.buffers.structural.xattribute
import com.idyria.osi.ooxoo.core.buffers.datatypes.LongBuffer
import uni.hd.cag.osys.rfg.rf2.value.Valued

/**
 * @author zm4632
 */
class RamBlock extends RamBlockTrait {
  
  val ramEntries = scala.collection.mutable.WeakHashMap[Int, RamEntry]()
  
  /**
   * @group rf
   */
  @xattribute(name = "addrsize")
  var addressSize: LongBuffer = null
  
  // Search
  //--------------------

  /**
   * Return a RamEntry for the corresponding index
   * @throws a Runtime exception if the index is out of range
   */
  def entry(index: Int): RamEntry = {

    index match {

      // Out of range
      case i if (i < 0 || i > Math.pow(2.0, (this.addressSize).data.toDouble)) => throw new RuntimeException(s"""Could no get entry $i in ram ($name), must be 0 < index < ${this.addressSize.data.toDouble}""")
      case i => ramEntries.getOrElseUpdate(i, new RamEntry(this, i))
    }

  }

  /**
   * Search string format:
   *
   * xxxxx
   *
   * Just the name of the field to search for
   *
   * @group rf
   */
  def field(searchAndApply: String)(implicit closure: RamField => Unit): RamField = {

    // Look For possible field
    //----------------
    this.ramFields.find(_.name.equals(searchAndApply)) match {
      case Some(searchedField) =>

        // Execute closure
        //----------------------
        closure(searchedField)

        return searchedField
      case None =>
        throw new RuntimeException(s"""
                    Searching for RamField ${searchAndApply} under ${this.name} in expression $searchAndApply failed, is the field defined in the current ramblock ?
                """)
    }

  }
}
/**
 * Represents a value entry in a RAM
 */
class RamEntry(var ramBlock: RamBlock, var index: Integer) extends CommonTrait with Valued {

  // Resolve address from ramblock base address
  this.name = s"${ramBlock.name}[$index]"
  
  // Addresses are always 64 bits (8bytes) aligned
  //this.absoluteAddress = ramBlock.absoluteAddress + (index.toLong * 8 )
  
  /*/**
   * @group rf
   */
  var valueBuffer = RegisterTransactionBuffer(this)

  def value = this.valueBuffer

  /**
   *
   * Enables register.value = Long  syntax
   *
   * @group rf
   */
  def value_=(data: Long) = this.valueBuffer.set(data)*/
  
  
  
}
object RamBlock {

  implicit val defaultClosure: (RamBlock => Unit) = { t => }

}