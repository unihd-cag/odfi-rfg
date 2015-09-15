/*

RFG Register File Generator
Copyright (C) 2014  University of Heidelberg - Computer Architecture Group

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


*/
package uni.hd.cag.osys.rfg.rf

import org.scalatest._

class RegisterFileTest extends FlatSpec with ShouldMatchers {

  trait RegisterFileFixture {
    val registerFile = RegisterFile(getClass().getClassLoader().getResource("extoll_rf.anot.xml"))
  }

  "RegisterFile" should "Parse" in new RegisterFileFixture {
    //------------------------------------------------------------------

    // Check First regroot is named extoll_rf
    //-----------------------------
    registerFile.groups.foreach {
      g => println(s"top: ${g.name}")
    }

    registerFile.groups.size should be === (1)

    registerFile.groups.head.name.toString should equal("extoll_rf")

    registerFile.groups.head.groups.size should be >= (1)
    registerFile.groups.head.groups.foreach {
      g => println(s"${g.name}")
    }

  }

  "Search group" should "Return objects" in new RegisterFileFixture {
    //-------------------------------------------------------------------

    // Get Valid regroot
    //--------------------------
    var infoRfRegroot = registerFile.group("extoll_rf/info_rf")
    assert(infoRfRegroot != null)
    
    

    // Get Invalid regroot
    //--------------------------
    intercept[RuntimeException] {
      registerFile group "extoll_rf/infooooo_rf"
    }

    // Get Valid Regroot and apply a closure on it
    //--------------
    var closureReached = false
    registerFile.group("extoll_rf/info_rf") {

      group => closureReached = true

    }
    expectResult(true)(closureReached)

  }

  "Search reg64" should "Return Objects" in new RegisterFileFixture {
    //-------------------------------------------------------------------

    // Search a reg64
    //---------------------------
    var infoRfNode = registerFile.register("extoll_rf/info_rf/node")
    assert(infoRfNode != null)
    assert(infoRfNode.description == null)

    infoRfNode = registerFile register "extoll_rf/info_rf/node"
    assert(infoRfNode != null)

    // Search another reg64 with description
    //-------------------------
    var ipRegNode = registerFile.register("extoll_rf/info_rf/ip_addresses")
    assert(ipRegNode != null)
    assert(ipRegNode.description != null)

    // test closure execution
    //----------------------------------
    var closureReached = false
    registerFile.register("extoll_rf/info_rf/node") {
      reg =>
        closureReached = true
        expectResult("node")(reg.name.toString)
    }
    expectResult(true)(closureReached)

  }

  "Reg64 Reset method" should "Return XML default value" in new RegisterFileFixture {

    // Search a reg64
    //---------------------------
    var nodeReg = registerFile.register("extoll_rf/info_rf/node")
    assert(nodeReg != null)

    expectResult("100adfeabcd1a")(java.lang.Long.toHexString(nodeReg.getResetValue))

  }

  "Search reg64 in repeat" should "Return Objects" in new RegisterFileFixture {
    //-------------------------------------------------------------------

    // Search a reg64
    //---------------------------
    var smfuIntervalControl = registerFile.register("extoll_rf/smfu_rf/interval_0/control")
    assert(smfuIntervalControl != null)

    // test closure execution
    //----------------------------------
    var closureReached = false
    registerFile.register("extoll_rf/smfu_rf/interval_0/control") {
      reg =>
        closureReached = true
        expectResult("control")(reg.name.toString)
    }
    expectResult(true)(closureReached)

    // Verify all intervals setup
    //---------------------------
    // base deifnition: <repeat _iterSize="0x20" loop="16" _absoluteAddress="0x5880" name="interval">
    var regCount = 4
    var baseAbsoluteAddress = java.lang.Long.decode("0x5880")
    var baseName = "interval"

    for (i <- 0 to regCount - 1) {

      // Get Group and Check attributes
      //----------
      var intervalGroup: RepeatGroup = registerFile.group(s"extoll_rf/smfu_rf/interval_$i").asInstanceOf[RepeatGroup]

      var intervalGroupBaseAddress = baseAbsoluteAddress + (i * regCount * 8)

      assert(intervalGroup != null)
      expectResult(s"interval_$i")(intervalGroup.name.toString)
      expectResult(intervalGroupBaseAddress)(intervalGroup.absoluteAddress.data)

      // Get  Registers and check attributes
      //------------------------
      var controlReg = registerFile.register(s"extoll_rf/smfu_rf/interval_$i/control")
      assert(controlReg != null)
      assert(controlReg.field("Valid").parentRegister!=null,"Register field from repeat block must have parent register")
      
      
      // Control Register
      //---------------------
      expectResult("control")(controlReg.name.toString)
      assert(controlReg.absoluteAddress != null)
      expectResult(intervalGroupBaseAddress)(controlReg.absoluteAddress.data)

      //println(s"Control register $i address: ${controlReg.absoluteAddress.data}")
      
      // Control Field
      //-------------------------
     // println(s"Control register $i address from field: ${controlReg.field("Valid").parentRegister.absoluteAddress.data}")
      var validField = controlReg.field("Valid")
      assert(validField.parentRegister==controlReg)
      
      
      
      var startaddrReg = registerFile.register(s"extoll_rf/smfu_rf/interval_$i/startaddr")
      assert(startaddrReg != null)

      expectResult("startaddr")(startaddrReg.name.toString)
      assert(startaddrReg.absoluteAddress != null)
      expectResult(intervalGroupBaseAddress + 8)(startaddrReg.absoluteAddress.data)

    }

  }

  "Search field" should "Return Objects" in new RegisterFileFixture {
    //-------------------------------------------------------------------

    // Search a reg64
    //---------------------------

    var guidField = registerFile.register("extoll_rf/info_rf/node").field("guid")
    assert(guidField != null)

    guidField = registerFile.field("extoll_rf/info_rf/node.guid")
    assert(guidField != null)
    assert(guidField.parentRegister != null)
    expectResult(0)(guidField.offset)

    // Verify Rights
    //-------------------
    expectResult(true)(guidField.hw.canWrite)
    expectResult(false)(guidField.sw.canWrite)

    // Verify offseting
    //--------------------------
    var nodeIdField = registerFile.register("extoll_rf/info_rf/node").field("id")

    expectResult(false)(nodeIdField.hw.canWrite)
    expectResult(true)(nodeIdField.sw.canWrite)

    assert(nodeIdField.parentRegister != null)
    expectResult(24)(nodeIdField.offset)
    expectResult(16.toString)(nodeIdField.width.toString)

  }

  "Search RAM Entry" should "Return Objects" in new RegisterFileFixture {

    // Search a Ram
    //---------------------------
    var inp0McastRam = registerFile.ram("extoll_rf/nw/xbar_rf/inp0/mcast") 
    assert(inp0McastRam != null)
    assert(inp0McastRam.description == null)

    // Get Entry out of range
    //---------------
    intercept[RuntimeException] {
      inp0McastRam.entry(Integer.MAX_VALUE)
    }
    
    // Search Fields
    //----------------
    var field = inp0McastRam.field("forward_to_host")
    assert(field!=null)
    expectResult(1)(field.width.data)
    expectResult(21)(field.offset)
    
    
  }

  "Generic Search Register" should "Return Objects" in new RegisterFileFixture {

    assert(registerFile.search("extoll_rf/info_rf/node") != null)
    assert(registerFile.search("extoll_rf/info_rf/node").isInstanceOf[Register])

  }

  "Generic Search Register Field" should "Return Objects" in new RegisterFileFixture {

    assert(registerFile.search("extoll_rf/info_rf/node.guid") != null)
    assert(registerFile.search("extoll_rf/info_rf/node.guid").isInstanceOf[Field])

  }

  "Generic Search Ram Entry" should "Return Objects" in new RegisterFileFixture {

     assert(registerFile.search("extoll_rf/nw/xbar_rf/inp0/mcast[12]") != null)
     assert(registerFile.search("extoll_rf/nw/xbar_rf/inp0/mcast[12]").isInstanceOf[RamEntry])
    
    
  }

  "Generic Search Ram Entry Field" should "Return Objects" in new RegisterFileFixture {

    assert(registerFile.search("extoll_rf/nw/xbar_rf/inp0/mcast[12].forward_to_host")!=null)
    assert(registerFile.search("extoll_rf/nw/xbar_rf/inp0/mcast[12].forward_to_host").isInstanceOf[RamField])
    
  }

}


