package uni.hd.cag.osys.rfg.rf2.model

import uni.hd.cag.osys.rfg.rf2.value.Valued
import com.idyria.osi.ooxoo.core.buffers.structural.DataUnit

/**
 * @author zm4632
 */
class Register extends RegisterTrait with Valued {

  // End of parsing
  //-------------------------
  override def streamIn(du:DataUnit) = {
    
    if (du.isHierarchyClose) {
      
      // update fields offsets by going 2 by 2 over the list
      this.fields.scan(null) {
        case (null,right) =>
          right.parentRegister = this
          right
        case (left,null) => 
          left.parentRegister = this
          left
        case (left,right) => 
          left.parentRegister = this
          right.parentRegister = this 
          right.offset = left.offset+left.width
          right
      }
      /*this.fields.grouped(2).foreach {
        case arr if (arr.size==1) =>
          arr(0).parentRegister=this
        case arr => 
          arr.foreach(_.parentRegister=this)
          arr(1)
          
      }
      this.fields.foreach {
        f => 
          f.parentRegister = this
      }*/
      
    }
    
    super.streamIn(du)
  }
  
  // Fields
  //------------------
  
  
  /**
   * Search string format:
   *
   * xxxxx
   *
   * Just the name of the field to search for
   *
   * @group rf
   */
  def field(searchAndApply: String)(implicit closure: Field => Unit): Field = {

    // Look For possible field
    //----------------
    this.fields.find(_.name.equals(searchAndApply)) match {
      case Some(searchedField) =>

        // Execute closure
        //----------------------
        closure(searchedField)

        return searchedField
      case None =>
        throw new RuntimeException(s"""
                    Searching for Field ${searchAndApply} under ${this.name} in expression $searchAndApply failed, is the field defined in the current register ?
                """)
    }

  }
}
object Register {

  implicit val defaultClosure: (Register => Unit) = { t => }

}