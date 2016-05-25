package uni.hd.cag.osys.rfg.rf2.value

import uni.hd.cag.osys.rfg.rf2.model.AttributesContainerTrait
import uni.hd.cag.osys.rfg.rf2.model.AttributesContainer
import com.idyria.osi.ooxoo.core.buffers.structural.DataUnit

/**
 * @author zm4632
 */
trait Valued extends AttributesContainer {
  
  
  
  
  
  
  /**
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
  def value_=(data: Double) = this.valueBuffer.set(data)
  
  def setMemory(data:Double) = this.valueBuffer.data = data
  
  def getMemory = this.valueBuffer.data
  
  // Read More than one value
  //-------------
  def value(size:Int = 1)   = {
    var du = new DataUnit
    du("size" -> size)
    valueBuffer.pull(du)
    this.valueBuffer
  }
  
  
  
  
}