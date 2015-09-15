package uni.hd.cag.osys.rfg.rf2.model

import com.idyria.osi.tea.bit.TeaBitUtil
import com.idyria.osi.tea.listeners.ListeningSupport

/**
 * @author zm4632
 */
class Field extends FieldTrait with ListeningSupport {

  /**
   * parent register type
   * @group rf
   */
  var parentRegister: Register = null

  /**
   * Offset of this field inside register.
   * Basically previous field offset + previous field size
   * @group rf
   */
  var offset = 0

  //var value : Long = 0

  def value: Long = {

    // Read
    var actualValue = parentRegister.value

    // Extract
    TeaBitUtil.extractBits(actualValue, offset, offset + width - 1)
  }

  /**
   * Returns the value of this field based on the actual memory value of the register, with no read
   */
  def memoryValue: Long = {

    // Read
    var actualValue = parentRegister.value

    // Extract
    TeaBitUtil.extractBits(actualValue.data, offset, offset + width - 1)

  }

  /**
   * Set the value of this field:
   *
   * - Read register value
   * - Modify field bits
   * - write register value back
   *
   * @group rf
   */
  def value_=(newData: java.lang.Long) = {

    // Read
    var actualValue: Long = parentRegister.value

    //java.lang.Long.toHexString(node.value)

    //var resultingValue = TeaBitUtil.setBits(actualValue, offset, offset + (width - 1), newData)
    var scalResult = Field.setBits(actualValue, offset, offset + (width - 1), newData)

    //  println(s"Changing value of field $name (${offset+(width-1)}:$offset) , reg was ${java.lang.Long.toHexString(actualValue)}, is now: ${java.lang.Long.toHexString(scalResult)}")
    // println(s"Scal result: ${java.lang.Long.toHexString(scalResult)}")
    // println(s"Setting to: ${this.parentRegister.name}")

    // Modify / Write
    this.parentRegister.value = scalResult

    this.@->("value.updated")

    ///println(s"Now val is ${java.lang.Long.toHexString(this.parentRegister.value)}")

  }

  /**
   * Update value in parent, but without triggering a push
   */
  def setMemory(newData: Long) = {
    
    // Read
    var actualValue: Long = parentRegister.valueBuffer.data
    
   // println(s"Update field form $actualValue to , with @ $offset -> $width")
    //var resultingValue = TeaBitUtil.setBits(actualValue, offset, offset + (width - 1), newData)
    var scalResult = Field.setBits(actualValue, offset, offset + (width - 1), newData)

    // Modify / Write
    this.parentRegister.setMemory(scalResult)

    this.@->("value.updated")

  }
}

object Field {

  implicit val defaultClosure: (Field => Unit) = { t => }
  def setBits(baseValue: Long, lsb: Int, msb: Int, newValue: Long): Long = {

    var width = msb - lsb + 1;

    // Variables
    //----------------
    //var fullMask: Long = java.lang.Long.decode("0x7FFFFFFFFFFFFFFF");
    var fullMask: Long = 0xFFFFFFFFFFFFFFFFL;
    var fullMaskLeft: Long = 0;
    var newValShifted: Long = 0;
    var resultVal: Long = 0;
    var baseValueRight: Long = 0;

    //-- Shift newVal left to its offset position
    newValShifted = newValue << lsb;

    // println(s"newValShifted: 0x${newValShifted.toHexString} "+newValShifted.toBinaryString)

    //println(s"Base full mask: 0x${fullMask.toHexString} "+fullMask.toBinaryString)

    //-- Suppress right bits of baseValue by & masking with F on the left
    (lsb + width) match {
      case 64 => fullMaskLeft = ~(fullMask << (lsb + width));
      case _ => fullMaskLeft = fullMask << (lsb + width);
    }

    resultVal = baseValue & fullMaskLeft;

    //-- Set Result value in result by ORing with the placed shifted bits new value
    resultVal = resultVal | newValShifted;

    // println(s"Res Temp: 0x${resultVal.toHexString} "+resultVal.toBinaryString)

    // Reconstruct  Right part
    //----------------------------------

    //-- Isolate base value right part
    var fullMaskRight = (64 - lsb) match {
      case 64 => ~(fullMask >>> (64 - lsb))
      case _ => fullMask >>> (64 - lsb)
    }
    //  println(s"Full mask right with lsb: $lsb: ${fullMaskRight.toBinaryString}")
    baseValueRight = baseValue & fullMaskRight;

    //-- Restore right part
    resultVal = resultVal | baseValueRight;

    //println(s"Res: 0x${resultVal.toHexString} "+resultVal.toBinaryString)

    return resultVal

  }
}