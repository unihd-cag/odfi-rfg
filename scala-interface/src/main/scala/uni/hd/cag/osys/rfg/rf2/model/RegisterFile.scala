package uni.hd.cag.osys.rfg.rf2.model

/**
 * @author zm4632
 */
class RegisterFile extends Group {

}
object RegisterFile {

  def apply() = new RegisterFile

  def apply(url: java.net.URL) = {

    // Instanciate
    var res = new RegisterFile

    // Set Stax Parser and streamIn
    var io = com.idyria.osi.ooxoo.core.buffers.structural.io.sax.StAXIOBuffer(url)
    res.appendBuffer(io)
    io.streamIn

    // Return
    res

  }

  def apply(xml: String) = {

    // Instanciate
    var res = new RegisterFile

    // Set Stax Parser and streamIn
    var io = com.idyria.osi.ooxoo.core.buffers.structural.io.sax.StAXIOBuffer(xml)
    res.appendBuffer(io)
    io.streamIn

    // Return
    res

  }

}