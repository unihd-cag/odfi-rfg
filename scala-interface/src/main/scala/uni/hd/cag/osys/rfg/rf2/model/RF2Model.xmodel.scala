package uni.hd.cag.osys.rfg.rf2.model

import com.idyria.osi.ooxoo.model.ModelBuilder
import com.idyria.osi.ooxoo.model.out.markdown.MDProducer
import com.idyria.osi.ooxoo.model.out.scala.ScalaProducer
import com.idyria.osi.ooxoo.model.producers
import com.idyria.osi.ooxoo.model.producer

@producers(Array(
  new producer(value = classOf[ScalaProducer]),
  new producer(value = classOf[MDProducer])))
object RF2Model extends ModelBuilder {

  
  var valued = "ValuedTrait" is {
    isTrait
    attribute("reset").classType = "uni.hd.cag.osys.rfg.rf.VerilogLongValue"
  }
  
  var common = "CommonTrait" is {
    attribute("name")
    isTrait
  }
 
  var attributesContainer = "AttributesContainerTrait" is {
    isTrait
    
    importElement("Attributes").setMultiple
    
  }
  
  var attributes = "AttributesTrait" is {
    isTrait
    attribute("for")
    "Attribute" multiple {
      withTrait(common)
      ofType("string")
    } 
  }

  var field = "FieldTrait" multiple {
    withTrait(common)
    withTrait("AttributesContainer")
    isTrait

 
    attribute("width") ofType ("int")
    attribute("reset").classType = "uni.hd.cag.osys.rfg.rf.VerilogLongValue"

    
  }

  var register = "RegisterTrait" multiple {
    
    withTrait(common)
    withTrait("AttributesContainer")
    isTrait
    
    attribute("reset").classType = "uni.hd.cag.osys.rfg.rf.VerilogLongValue"

    importElement("Field").setMultiple

  }

  var group = "GroupTrait" is {

    withTrait(common)
    withTrait("AttributesContainer")
    importElement("Register").setMultiple
    importElement("Group").setMultiple
    importElement("RamBlock").setMultiple

  }
  
  var ramBlock = "RamBlockTrait" is {
    
    withTrait(common)
    withTrait("AttributesContainer")
    //importElement(attributes).setMultiple
    importElement("RamField").setMultiple
    
  }

   /*"RegisterFile" is {

    withTrait("Group")

  }*/

} 