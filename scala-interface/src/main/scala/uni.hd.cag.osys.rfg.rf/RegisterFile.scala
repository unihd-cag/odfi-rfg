package uni.hd.cag.osys.rfg.rf

import java.io._
import java.net.URL
import scala.language.implicitConversions
import com.idyria.osi.ooxoo.core.buffers.datatypes._
import com.idyria.osi.ooxoo.core.buffers.structural._
import com.idyria.osi.ooxoo.core.buffers.structural.io.sax._
import com.idyria.osi.tea.bit._

import scala.language.dynamics
import com.idyria.osi.tea.listeners.ListeningSupport

// Common Traits
//-------------------

/**
 * @group rf
 */
trait Named {

  /**
   * name attribute
   * @group rf
   */
  @xattribute
  var name: XSDStringBuffer = null

}

trait NamedAddressed extends Named {

  /**
   * @group rf
   */
  @xattribute(name = "_absoluteAddress")
  var absoluteAddress: LongBuffer = null

  /**
   * @group rf
   */
  @xattribute(name = "_baseAddress")
  var baseAddress: LongBuffer = null

}

trait NamedAddressedValued extends NamedAddressed {

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
  def value_=(data: Long) = this.valueBuffer.set(data)

}

/**
 * This Buffer is used for sw="" hw="" hwreg read/write rights
 *
 */
class ReadWriteRightsType extends XSDStringBuffer {

  def canWrite: Boolean = this.data.contains('w')
  def canRead: Boolean = this.data.contains('r')

}
object ReadWriteRightsType {

  def apply(str: String) = {
    var rwt = new ReadWriteRightsType
    rwt.data = str
    rwt
  }
}

/**
 * This Buffer represents a verilog value, which is defined as:
 *
 * SIZE'TYPEVALUE
 *
 * TYPE = h,b,d etc..
 */
class VerilogLongValue extends LongBuffer {

  var originalStringValue = "0"

  /**
   * Parse Verilog value
   */
  override def dataFromString(str: String): java.lang.Long = {

    this.originalStringValue = str
    var resValue: Long = 0
    //println("Parsing: "+str)

    var expr = """(?i)([0-9]+)'(b|h|d)([A-Fa-f0-9]+)?""".r
    expr.findFirstMatchIn(str) match {

      //-> HEx Match, parse value
      case Some(m) if (m.group(2) == "h") =>

        resValue = java.lang.Long.decode(s"0x${m.group(3)}")

      //-> B match
      case Some(m) if (m.group(2) == "b") =>

        // Every character is a bit
        var offset = 0
        m.group(3).reverse.foreach {
          c =>
            resValue = TeaBitUtil.setBits(resValue, offset, offset, java.lang.Long.parseLong(s"$c"))
            offset += 1
        }

      //-> Decimal match, let normal long parse value
      case Some(m) if (m.group(2) == "d") =>

  
        resValue = m.group(3) match {
          case null => 0
          case v => super.dataFromString(v)
        }

      //-> No match, let normal long parse value
      case None if (str.matches("[0-9]+")) =>

        // Only Do if 
        resValue = super.dataFromString(str)

      //-> No match but keep value 0 if a Define is referenced
      case None if (str.matches(".*`.*")) =>
        resValue = 0
      case _ =>
        throw new IllegalArgumentException(s"""Verilog Value matched format for input: $str , but match case was not handled""")

    }

    this.data = resValue
    this.data
  }

  /**
   * Return the last parsed representation
   */
  override def toString: String = this.originalStringValue

}

object VerilogLongValue {

  def apply(init: Long) = {
    var obj = new VerilogLongValue()
    obj.data = init
    obj
  }

  implicit def convertStringToVerilogLongValue(str: String): VerilogLongValue = {

    var value = new VerilogLongValue
    value.data = value.dataFromString(str)
    value

  }
}

// Register File Structure
//-------------------------

/**
 * Top Level element
 *
 */
@xelement(name = "regfile")
class RegisterFile extends Group {

  @xelement
  var vendorsettings: VendorSettings = null

}

/**
 * Companion Objects used as factories
 */
object RegisterFile {

  /**
   * Create a RegisterFile from an URL
   */
  def apply(annotXML: URL): RegisterFile = {

    //  Prepar RF
    var rf = new RegisterFile()

    // Append Input IO
    rf - new StAXIOBuffer(new InputStreamReader(annotXML.openStream))

    // Streamin
    rf.lastBuffer.streamIn
   
    //rf streamIn
    //rf.getNextBuffer.remove

    // Return
    rf

  }

  /**
   * Create a RegisterFile from a File path
   */
  def apply(file: String): RegisterFile = this.apply(new File(file).toURI.toURL)
  
  /**
   * Create a RegisterFile from a File path
   */
  def apply(file: File): RegisterFile = this.apply(file.toURI.toURL)

}

@xelement(name = "vendorsettings")
class VendorSettings extends ElementBuffer {

  @any
  var any = AnyXList()

}

trait DynamicSearchable extends Dynamic {
  
	def selectDynamic(name: String) : DynamicSearchable
}

/**
 * The <regrooot element
 *
 */
@xelement(name = "regroot")
class Group  extends DynamicSearchable with ElementBuffer with Named {

  // Attributes
  //-----------------

  // Structure
  //------------------

  //----- regroot
  /**
   * @group rf
   */
  @xelement(name = "regroot")
  var groups = XList { new Group }

  //---- Register
  /**
   * @group rf
   */
  @xelement(name = "reg64")
  var registers = XList { new Register }

  //---- Rams
  /**
   * @group rf
   */
  @xelement(name = "ramblock")
  var rams = XList { new RamBlock }

  //---- Repeat
  /**
   * @group rf
   */
  @xelement(name = "repeat")
  var repeats = XList {

    //-- Create Repeat as Group
    var repeat = new RepeatGroup(this)

    //-- Add to groups
    Group.this.groups += repeat

    //-- Return
    repeat
  }

  // General
  //-------------------

  /**
   * @group rf
   */
  def apply(closure: Group => Unit) = {

    closure(this)
  }

  // Search
  //-------------------------

  /**
   * 
   * Dynamic Search
   */
  def selectDynamic(name: String) : DynamicSearchable = {
    
    this
  }
  
  
  /**
   * Generic search that can return Register, Ram Entries or Fields
   *
   * Format of search string:
   *
   *  - Register: /path/to/register
   *  - Ram Entry: /path/to/ram[entryIndex]
   *  - Field of ram or register: /path/to/register.field or /path/to/ram[entryIndex].field
   *
   *
   */
  def search(search: String): Any = {

    // Patterns
    val ramEntry = """(.+)\[([0-9]+)\]$""".r
    val ramEntryField = """(.+)\[([0-9]+)\]\.([\w]+)$""".r
    val regField = """(.+)\.([\w]+)$""".r
    val reg = """(.+)$""".r

    /**
     * match more complex ram search, if not matching, easier matching falls back to Registers
     */
    search.trim match {

      //-- Ram entry
      case ramEntry(path, entry)             =>

        var ram = this.ram(path)
        return ram.entry(Integer.parseInt(entry))
        
        
        
      //-- Ram Entry field
      case ramEntryField(path, entry, fieldName) =>

        var ram = this.ram(path)
        var field = ram.field(fieldName)
        return field.forEntry(Integer.parseInt(entry))
        
      //-- Register Field
      case regField(path, fieldName)             =>

         var reg = this.register(path)
         var field = reg.field(fieldName)
         return field
         
      //-- Register
      case reg(path)                         =>

        var reg = this.register(path)
        return reg
      case _                                 => throw new RuntimeException(s"Generic Search expression $search does not match expected format")
    }

  }

  /**
   * Search for a regroot
   *
   * Search String format:
   *
   * xxx/xxx/xxx
   *
   * wherre xxx should be the name of a regroot
   *
   * @group rf
   * @return the found regroot, this if the search string is empty
   * @throws RuntimeException if the specificed search path doesn't point to any regroot
   */
  def group(searchAndApply: String)(implicit closure: Group => Unit): Group = {

    
    if (searchAndApply=="") {
      return this
    }
    
    // Split regroot names
    //-----------------
    var regRoots = searchAndApply.split("/")

    // Search
    //----------------
    var currentSearchedRegRoot = this

    regRoots.foreach {
      currentSearchedRegRootName =>

        //-- Look for a regroot with current searched Name in currrent Regroot source
        currentSearchedRegRoot.groups.find(_.name.toString == currentSearchedRegRootName) match {
          case Some(nextRegRoot) => currentSearchedRegRoot = nextRegRoot
          case None =>
            throw new RuntimeException(s"""
                            Searching for regroot ${currentSearchedRegRootName} under ${currentSearchedRegRoot.name} in expression $searchAndApply failed, is the searched path available in the current in use registerfile ?
                        """)
        }

    }

    // Apply Closure if one is provided
    closure(currentSearchedRegRoot)
    //closure(currentSearchedRegRoot)

    // Return
    currentSearchedRegRoot
  }

  /**
   * Search for a Register
   *
   * Search String format:
   *
   * xxxxx/xxx/xxxx/yyyyy
   * path/to/regroot/register
   *
   * With:
   *
   * - xxxx are possible regroots to search
   * - the last path element yyyy beeing the name of the searched register
   *
   * @group rf
   */
  def register(searchAndApply: String)(implicit closure: Register => Unit): Register = {

    // Split String
    //----------------
    var paths = searchAndApply.split("/")
    var searchedRegister = paths.last

    // Regroot: This or the one defined by all the paths elements until the last one
    //---------
    var regRoot = this.group(paths.dropRight(1).mkString("/"))

    // Look For possible register
    //----------------
    regRoot.registers.find(_.name.equals(searchedRegister)) match {
      case Some(searchedRegister) =>

        // Execute closure
        //----------------------
        closure(searchedRegister)

        return searchedRegister
      case None =>
        throw new RuntimeException(s"""
                    Searching for Register ${searchedRegister} under ${regRoot.name} in expression $searchAndApply failed, is the searched path available in the current in use registerfile ?
                """)
    }

  }

  /**
   * Search for a RamBlock
   *
   * Search String format:
   *
   * xxxxx/xxx/xxxx/yyyyy
   * path/to/regroot/ramblock
   *
   * With:
   *
   * - xxxx are possible regroots to search
   * - the last path element yyyy beeing the name of the searched ramblock
   *
   * @group rf
   *
   */
  def ram(searchAndApply: String)(implicit closure: RamBlock => Unit): RamBlock = {

    // Split String
    //----------------
    var paths = searchAndApply.split("/")
    var searchedRamName = paths.last

    // Regroot: This or the one defined by all the paths elements until the last one
    //---------
    var regRoot = this.group(paths.dropRight(1).mkString("/"))

    // Look For possible register
    //----------------
    regRoot.rams.find(_.name.equals(searchedRamName)) match {
      case Some(searchedRam) =>

        // Execute closure
        //----------------------
        closure(searchedRam)

        return searchedRam
      case None =>
        throw new RuntimeException(s"""
                    Searching for Ram ${searchedRamName} under ${regRoot.name} in expression $searchAndApply failed, is the searched path available in the current in use registerfile ?
                """)
    }

  }

  /**
   * Search for a Field
   *
   * Search String format:
   *
   * xxxxx/xxx/xxxx/yyyyy.fieldName
   *
   *
   * With:
   *
   * - xxxx are possible regroots to search
   * - the last path element yyyy beeing the name of the searched register
   * - @fieldName is the name of the field to search on target register
   *
   * @group rf
   */
  def field(searchAndApply: String)(implicit closure: Field => Unit): Field = {

    // Get Register Path and Field Path
    //-------------------------
    var paths = searchAndApply.split("""\.""")

    if (paths.size != 2) {
      throw new IllegalArgumentException(s"Field search format must be: /path/to/register.fieldName, provided: ${searchAndApply}")
    }

    var registerPath = paths.head
    var fieldName = paths.last

    // Search
    //---------------
    this.register(registerPath).field(fieldName)(closure)

  }

}
object Group {

  implicit val defaultRegrootClosure: (Group => Unit) = { t => }

}

@xelement(name = "repeat")
class RepeatGroup(var parent: Group) extends Group with NamedAddressed {

  /**
   * @group rf
   */
  @xattribute(name = "loop")
  var loop: IntegerBuffer = 1

  //-- When Streamin is finished for this element :
  //--    -> Duplicate the group based on loop attribute, and update addresses
  override def streamIn(du: DataUnit) = {

    //-- Let parent work normally
    //---------------------
    super.streamIn(du)

    //-- Finish
    //------------------
    if (du.isHierarchyClose && this.stackSize == 0) {

      //-- Size of one repeat is number of registers * 64
      var repeatSize: Long = this.registers.size * 8

      //-- loop over number of repeat times
      for (i <- 1 to (this.loop - 1)) {

        // Duplicate
        var newRepeat = this.clone

        // Update
        newRepeat.name = s"""${newRepeat.name}_$i"""
        newRepeat.absoluteAddress = this.absoluteAddress + (i * repeatSize)
        newRepeat.registers.foreach(reg => reg.absoluteAddress = newRepeat.absoluteAddress + (newRepeat.registers.indexOf(reg) * 8))

        // Add To Parent group
        parent.groups += newRepeat
      }

      //-- Update current group as number 0
      this.name = s"""${this.name}_0"""
      this.registers.foreach {
        reg =>
          var index = this.registers.indexOf(reg)
          var newAddress = index * 8
          reg.absoluteAddress = this.absoluteAddress + newAddress
      }

    }

  }

  /**
   * Duplicate this repeat with all registers and so on
   */
  override def clone: RepeatGroup = {

    // Create
    var newRepeat = new RepeatGroup(parent)

    // Name
    newRepeat.name = s"${this.name}"

    // Absolute Address
    newRepeat.absoluteAddress = this.absoluteAddress.data

    // Registers
    this.registers.foreach(newRepeat.registers += _.clone)

    newRepeat
  }

}

/**
 * <Register
 *
 * Search string format:
 *
 * xxxx
 *
 * With:
 * - xxxx beeing the name of a field
 *
 *
 */
@xelement(name = "reg64")
class Register extends ElementBuffer with NamedAddressedValued with ListeningSupport {

  // Attributes
  //-----------

  /**
   * @group rf
   */
  @xattribute(name = "desc")
  var description: XSDStringBuffer = null

  // Structure
  //----------------

  //---- Reserved bits
  @xelement(name = "reserved")
  var reserved: Reserved = null

  //---- rreinit
  @xelement(name = "rreinit")
  var rreinit: BooleanBuffer = false

  //---- fields

  /**
   * The Builder closure for Fields also calculates the field offset in the register
   *
   * @group rf
   */
  @xelement(name = "hwreg")
  var fields: XList[Field] = XList {
    
    //-- Create Field
    //--------------------
    var newField = new Field
    newField.parentRegister = this
    fields.lastOption match {
      case Some(previousField) =>
        
        //-- Field gets an extra on the offset if there is a reserved element at the moment
        //-- Clear the reserved once consumed
        this.reserved match {
          case null => newField.offset = previousField.offset + previousField.width
          case rsv => 
            newField.offset = previousField.offset + previousField.width + rsv.width
            reserved = null
        }
        
        
      case None =>
    }
    newField
  }

  // Value
  //------------------

  /**
   * This is the combination of all the subfields reset values
   *
   * @group rf
   */
  def getResetValue: Long = {

    // Base value
    //------------
    var resetValue: Long = 0
    var offset = 0

    // Go through fields and set bits in long
    //--------------
    this.fields.foreach {
      f =>
        //println(s"Updating reg value with field: @${offset} -> ${offset+(f.width-1)} = ${f.reset.data}")

        // Set Bits in result long
        //----------
        resetValue = TeaBitUtil.setBits(resetValue, offset, offset + (f.width - 1), f.reset)

        // Update offset
        //------------------
        offset = offset + f.width
    }

    resetValue

  }

 /* /**
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

  // Search
  //--------------------

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

  // Utils
  //------------
  
  /**
   * Prints To Stdout a string with values of fields
   */
  def explain = {
    
    println(s"Register $name = 0x${value.toLong.toHexString}")
    this.fields.foreach { f => 
      println(s"-- ${f.name} = 0x${f.value.toHexString}")
    }
  } 
  
  /**
   * Prints To Stdout a string with values of fields
   */
  def explainMemory = {
    
    println(s"Register $name = 0x${value.data.toLong.toHexString}")
    this.fields.foreach { f => 
      println(s"-- ${f.name} = 0x${f.memoryValue.toHexString}")
    }
  } 
  
  override def clone: Register = {

    // Create
    var reg = new Register

    // Name
    reg.name = this.name.data

    // Desc
    reg.description = this.description.data

    // Address
    if (this.absoluteAddress != null)
      reg.absoluteAddress = this.absoluteAddress.data

    // Fields : Clone and update to new Register
    this.fields.foreach(reg.fields += _.clone)
    reg.fields.foreach {
      f => f.parentRegister = reg
    }

    reg
  }
}

object Register {

  implicit val defaultClosure: (Register => Unit) = { t => }

}

@xelement(name = "ramblock")
class RamBlock extends ElementBuffer with NamedAddressed {

  val ramEntries = scala.collection.mutable.WeakHashMap[Int, RamEntry]()
  // Attributes
  //-----------

  /**
   * @group rf
   */
  @xattribute(name = "addrsize")
  var addressSize: LongBuffer = null

  /**
   * @group rf
   */
  @xattribute(name = "ramwidth")
  var width: LongBuffer = null

  /**
   * @group rf
   */
  @xattribute(name = "desc")
  var description: XSDStringBuffer = null

  //---- fields

  /**
   * The Builder closure for Fields also calculates the field offset in the register
   *
   * @group rf
   */
  @xelement(name = "field")
  var fields: XList[RamField] = XList {
    var newField = new RamField
    newField.parent = this
    fields.lastOption match {
      case Some(previousField) =>
        newField.offset = previousField.offset + previousField.width
      case None =>
    }
    newField
  }

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
    this.fields.find(_.name.equals(searchAndApply)) match {
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

  // FIXME
  //@xattribute
  //var external : BooleanBuffer = null
}

object RamBlock {

  implicit val defaultClosure: (RamBlock => Unit) = { t => }

}

/**
 * Represents a value entry in a RAM
 */
class RamEntry(var ramBlock: RamBlock, var index: Integer) extends NamedAddressedValued {

  // Resolve address from ramblock base address
  this.name = s"${ramBlock.name}[$index]"
  
  // Addresses are always 64 bits (8bytes) aligned
  this.absoluteAddress = ramBlock.absoluteAddress + (index.toLong * 8 )
  
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

@xelement(name = "field")
class RamField extends ElementBuffer with Named {

  /**
   * @group rf
   */
  @xattribute(name = "width")
  var width: IntegerBuffer = null

  // Value
  //--------------------

  /**
   * Offset of this field inside register.
   * Basically previous field offset + previous field size
   * @group rf
   */
  var offset = 0

  /**
   * parent register type
   * @group rf
   */
  var parent: RamBlock = null

  /**
   * The entry to which we need to write this field
   */
  var entry : RamEntry = null
  
  /**
   * Set this field to write its value to the given Entry
   * The method returns a new Field with all fields set correctly
   * 
   * !! WARNING User must use the returned RamField instance, otherwise it won't be thread safe !!
   * 
   */
  def forEntry(index : Int ) : RamField = {
    
    // Clone and set entry
    var newField = this.clone
    newField.entry = parent.entry(index)
    
    newField
 
  }
 
  
  def value: Long = {

    // Read
    var actualValue = entry.value

    // Extract
    TeaBitUtil.extractBits(actualValue, offset, offset + width - 1)
  }
  
  /**
   * Returns the value of this field based on the actual memory value of the register, with no read
   */
  def memoryValue : Long = {
    
    // Read
    var actualValue = entry.value

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
    var actualValue: Long = entry.value

    var scalResult = Field.setBits(actualValue, offset, offset + (width - 1), newData)

    
    // Modify / Write
    this.entry.value = scalResult
    
   // this.@->("value.updated")

    ///println(s"Now val is ${java.lang.Long.toHexString(this.parentRegister.value)}")

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

/**
 * <hwreg
 *
 */
@xelement(name = "hwreg")
class Field extends ElementBuffer with Named with ListeningSupport {

  // Attributes
  //-----------------

  /**
   * @group rf
   */
  @xattribute
  var width: IntegerBuffer = null

  /**
   * @group rf
   */
  @xattribute(name = "desc")
  var description: XSDStringBuffer = null

  /**
   * @group rf
   */
  @xattribute(name = "reset")
  var reset: VerilogLongValue = VerilogLongValue(0)

  /**
   * @group rf
   */
  @xattribute(name = "sw")
  var sw = ReadWriteRightsType("ro")

  /**
   * @group rf
   */
  @xattribute(name = "hw")
  var hw = ReadWriteRightsType("rw")

  // Value
  //--------------------

  /**
   * Offset of this field inside register.
   * Basically previous field offset + previous field size
   * @group rf
   */
  var offset = 0

  /**
   * parent register type
   * @group rf
   */
  var parentRegister: Register = null

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
  def memoryValue : Long = {
    
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

  def testSetBits(baseValue: Long, lsb: Int, msb: Int, newValue: Long): Long = {

    var width = msb - lsb + 1;

    // Variables
    //----------------
    var fullMask: Long = java.lang.Long.decode("0x7FFFFFFFFFFFFFFF");
    var fullMaskLeft: Long = 0;
    var newValShifted: Long = 0;
    var resultVal: Long = 0;
    var baseValueRight: Long = 0;

    //-- Shift newVal left to its offset position
    newValShifted = newValue << lsb;

    //-- Suppress right bits of baseValue by & masking with F on the left
    fullMaskLeft = fullMask << (lsb + width);
    resultVal = baseValue & fullMaskLeft;

    //-- Set Result value in result by ORing with the placed shifted bits new value
    resultVal = resultVal | newValShifted;

    // Reconstruct  Right part
    //----------------------------------

    //-- Isolate base value right part
    baseValueRight = baseValue & (fullMask >> (63 - lsb));

    //-- Restore right part
    resultVal = resultVal | baseValueRight;

    return resultVal

  }

  override def clone: Field = {

    var field = new Field

    // Name
    field.name = this.name.data

    // Desc
    if (this.description != null)
      field.description = this.description.data

    // reset
    field.reset = this.reset.toString
    
    // Parent register
    field.parentRegister = this.parentRegister
    
    // Width
    field.width = this.width
    
    // SW/hw
    field.sw = this.sw
    field.hw = this.hw
    
    // Offset
    field.offset = this.offset

    field
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

@xelement(name = "reserved")
class Reserved extends ElementBuffer {

  // Attributes
  //-----------------

  /**
   * @group rf
   */
  @xattribute
  var width: IntegerBuffer = null

}
