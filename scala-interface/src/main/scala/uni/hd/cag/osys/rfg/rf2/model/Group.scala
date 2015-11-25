package uni.hd.cag.osys.rfg.rf2.model



/**
 * @author zm4632
 */
class Group extends GroupTrait {

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
      case ramEntry(path, entry) =>

        var ram = this.ram(path)
        return ram.entry(Integer.parseInt(entry))

      //-- Ram Entry field
      case ramEntryField(path, entry, fieldName) =>

        var ram = this.ram(path)
        var field = ram.field(fieldName) {r => }
        return field.forEntry(Integer.parseInt(entry))

      //-- Register Field
      case regField(path, fieldName) =>

        var reg = this.register(path)
        var field = reg.field(fieldName)
        return field

      //-- Register
      case reg(path) =>

        var reg = this.register(path)
        return reg
      case _ => throw new RuntimeException(s"Generic Search expression $search does not match expected format")
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

    if (searchAndApply == "") {
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
    regRoot.ramBlocks.find(_.name.equals(searchedRamName)) match {
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
