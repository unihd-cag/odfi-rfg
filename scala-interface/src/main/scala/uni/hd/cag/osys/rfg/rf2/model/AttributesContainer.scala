package uni.hd.cag.osys.rfg.rf2.model

/**
 * @author zm4632
 */
trait AttributesContainer extends AttributesContainerTrait with CommonTrait {
  
  /**
   * search: attributesgroup.attributeName
   */
  def findAttribute(search:String) : Option[String] = {
    
    // Decompose search string
    var (group,name) = search.split('.') match {
      case arr if (arr.length==2) => (arr(0),arr(1))
      case _ => throw new RuntimeException(s"Search String $search has wrong format, mut be: attributesGroupName.attributeName")
    }
    
    // Search for group
    this.attributes.find { a => a.for_.toString ==  group} match {
      case Some(attributes) =>
        attributes.attributes.find { attribute => attribute.name.toString == name } match {
          case Some(attribute) => Some(attribute.toString())
          case None => None
        }
      case None => None
    }
  
  }
  
  def findAttributeLong(search:String) : Option[Long] = this.findAttribute(search) match {
    case Some(value) => Some(value.toLong)
    case None => None
  }
  
  
}