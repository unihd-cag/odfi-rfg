package uni.hd.cag.osys.rfg.rf.device.simulation

import uni.hd.cag.osys.rfg.rf.device._

/**
 * @author fzahn
 *
 */
class SimpleSimulationDevice extends Device {

  def open = {

  }

  def close = {

  }

  // Node -> RegisterFile Map
  //-----------------
  var nodesMap = scala.collection.mutable.Map[Short, scala.collection.mutable.Map[Long, Long]]()

  private def getNodeMap(nodeId: Short): scala.collection.mutable.Map[Long, Long] = {

    nodesMap.get(nodeId) match {
      case Some(map) => map
      case None =>
        var nodeMap = scala.collection.mutable.Map[Long, Long]()
        nodesMap = nodesMap + (nodeId -> nodeMap)
        nodeMap

    }

  }

  def readRegister(nodeId: Short, address: Long): Option[Long] = {

    println("Read from  " + nodeId)

    // Get node Map and read
    //-----------
    this.getNodeMap(nodeId).get(address)

  }

  def writeRegister(nodeId: Short, address: Long, value: Long) = {

    println("Writing to " + nodeId)
    this.getNodeMap(nodeId) += (address -> value)
  }

}

/**
 * Companion object to open/close the native interface
 */
object SimpleSimulationDevice {

}
