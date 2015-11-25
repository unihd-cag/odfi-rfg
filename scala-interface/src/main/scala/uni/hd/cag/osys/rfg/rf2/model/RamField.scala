package uni.hd.cag.osys.rfg.rf2.model

/**
 * @author zm4632
 */
class RamField extends Field {



  /**
   * parent register type
   * @group rf
   */
  var parent: RamBlock = null

  /**
   * The entry to which we need to write this field
   */
  var entry: RamEntry = null

  /**
   * Set this field to write its value to the given Entry
   * The method returns a new Field with all fields set correctly
   *
   * !! WARNING User must use the returned RamField instance, otherwise it won't be thread safe !!
   *
   */
  def forEntry(index: Int): RamField = {

    // Clone and set entry
    var newField = this.clone
    newField.entry = parent.entry(index)

    newField

  }
  override def clone: RamField = {

    // Create
    var field = new RamField

    // Name 
    field.name = this.name.data

    // Width
    field.width = this.width

    // Offset
    field.offset = this.offset

    // Parent
    field.parent = this.parent

    field
  }
}
object RamField {

  implicit val defaultClosure: (RamField => Unit) = { t => }

}