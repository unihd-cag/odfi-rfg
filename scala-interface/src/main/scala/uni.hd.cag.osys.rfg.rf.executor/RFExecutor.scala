package uni.hd.cag.osys.rfg.rf.executor

import java.io.File
import com.idyria.osi.aib.core.bus.aib
import com.idyria.osi.ooxoo.core.buffers.datatypes.DateTimeBuffer
import com.idyria.osi.ooxoo.core.buffers.datatypes.XSDStringBuffer
import com.idyria.osi.ooxoo.core.buffers.structural.ElementBuffer
import com.idyria.osi.ooxoo.core.buffers.structural.xelement
import com.idyria.osi.ooxoo.db.Document
import com.idyria.osi.ooxoo.db.store.DocumentContainer
import com.idyria.osi.ooxoo.db.store.fs.FSStore
import com.idyria.osi.vui.core.VBuilder
import com.idyria.osi.vui.core.components.controls.DefaultTreeModel
import com.idyria.osi.vui.core.components.controls.DefaultTreeNode
import com.idyria.osi.vui.core.components.controls.TreeModel
import com.idyria.osi.vui.core.components.controls.TreeNode
import com.idyria.osi.vui.core.components.controls.VUIButton
import com.idyria.osi.vui.core.components.scenegraph.SGNode
import com.idyria.osi.vui.core.stdlib.node.SGCustomNode
import com.idyria.osi.vui.lib.gridbuilder.GridBuilder
import com.idyria.osi.aib.core.compiler.EmbeddedCompiler
import java.io.ByteArrayOutputStream
import com.idyria.osi.ooxoo.db.store.DocumentStore

class RFExecutorComponent(var db: DocumentStore) extends SGCustomNode[Any] with GridBuilder {

  // Components For Data management
  //-------------------------
  var scriptTextArea = textArea(expand)
  var resultTextArea = textArea(expand)

  var lastSavedLabel = label("")
  var fileName = textInput

  // Compile
  //--------------
  var compiler = new EmbeddedCompiler
  var compileClosure = {
    content: String =>

      // Prepare output
      //----------------
      var out = new ByteArrayOutputStream

      // Compile
      //------------------
      try {

        Console.withOut(out) {
          compiler.compile(content)
        }
        resultTextArea.setText(new String(out.toByteArray()))

      } catch {
        case e: Throwable => resultTextArea.setText(e.getMessage())
      }
  }

  // Load Script
  //--------------------
  aib.registerClosure {
    docAndScript: Tuple2[Document, RFScript] =>

      var script = docAndScript._2

      //-- Load Data to text
      //------------------
      println("Loading Script")
      scriptTextArea.setText(script.script)
      lastSavedLabel.setText(script.lastSaved.toString)
      fileName.setText(docAndScript._1.id)
  }

  /*
       * Create a Grid:
       * 
        - General Informations
       	- On the left, a tree of file
       	- On the right:
       			- 
       			- Editor | Result
       * 
       */
  def createUI = grid {
	  
    this.groupsStack.top.group.setName("RFExec")
    
    
    // - On the left, a tree of file
    // - On the right:
    //     - Controls
    //     - Editor | Result
    "main" row (expandHeight) {

      //--- Left
      ///--------------
      subgrid {

        "-" row label("Saved Scripts:")
        "-" row { ScriptsTree(db) using expand }

      } spanRight {

        // Right : Control
        //----------------------

        "control" row (spread) {

          // Save File
          //------------------
          "save" row subgrid {

            "-" row {

              var saveButton = button("Save") { b => b.disable }
              var deleteButton = button("Delete") { b => b.disable }
              fileName {
                _.model.onWith("model.setText") {
                  t: String =>
                    t match {
                      case "" => List(saveButton, deleteButton).foreach(_.disable);
                      case _  => List(saveButton, deleteButton).foreach(_.enable);
                    }
                }
              }
              label("File:") | { fileName(expandWidth) } | {

                // Save Action
                //-----------------
                saveButton.onClick {

                  //-- Determine container and file name
                  var (container, file) = fileName.model.getText.split("""/""") match {

                    // Save to container
                    case parts if (parts.length > 1) => (parts(0), parts(1))

                    // Save to default container
                    case parts                       => ("main", parts(0))
                  }

                  //-- Save doc
                  var scriptXML = new RFScript
                  scriptXML.script = scriptTextArea.model.getText
                  db.container(container).writeDocument(file, scriptXML)

                }
                saveButton

              } | {

                // Delete Action
                //--------------------
                deleteButton.onClick {

                }
                deleteButton
              }
            }
          }

          "-" row (spread) { label("Control Row")("border" -> true) }

          // Control Buttons
          //-------------------------
          "buttons" row subgrid {

            "compilation" row {

              //-- Compile
              var compileButton = button("Compile") {
                b => b.onClick(compileClosure(scriptTextArea.model.getText))
              }

              //-- Check box for live compilation
              compileButton | checkBox(spread)("Live Compilation") {
                c =>
                  c.onClicked {
                    compileButton.setEnabled(!c.isChecked)
                  }
              }

            }

          }
        }

        // Editor
        //--------------------
        "editor" row {

          subgrid {
            // Input
            //-------------

            use(expand)

            "-" row label("Enter Your Script below:")

            "script" row (scriptTextArea using (expand))

          } | subgrid {
            
            // Output
            //-------------

            use(expand)
            //apply("border"->true)

            "-" row label("Compilation/Run Results")
            "result" row (resultTextArea using expand)

          }

        }

      }

    }
  }

  //def createUI = ui

}

/**
 * The RF Executor Tool is a tool to try RF script
 */
object RFExecutor extends App with VBuilder with GridBuilder {

  println("Welcome to RF Executor Tool")

  // Open Database
  //------------------
  //var db = new FSStore(new File(List(".osys", "rf-executor").mkString(File.separator)))
  var db = new FSStore(new File(List("osys", "rf-executor").mkString(File.separator)))

  // The main Frame
  //-------------------
  var f = frame {

    f =>
      f title ("RF Executor Tool")
      f size (800, 600)

      f <= grid {

        // INformations
        //---------------------
        "info" row {

          "-" row { label("Welcome to RF Executor") using ("font-size" -> 14, expandWidth, spread) }
          "-" row {
            text(expandWidth, spread) {
              "The RF Executor tool will let you write Register File interface scripts, compile and simulate them, as well as try to execute them on a remote host"
            }
          }
        }
        
        // Component
        "-" row ( new RFExecutorComponent(db) using expand)

      }
  }

  f.show

}

// Model for saving
//----------------
@xelement(name = "RFScript")
class RFScript extends ElementBuffer {

  @xelement(name = "LastSaved")
  var lastSaved: DateTimeBuffer = new DateTimeBuffer

  @xelement(name = "Script")
  var script: XSDStringBuffer = null

}

/**
 * Class To navigate over the saved files
 */
class ScriptsTree(var db: DocumentStore) extends SGCustomNode[Any] with VBuilder with DefaultTreeModel with DefaultTreeNode {

  // Document node
  //---------------
  class DocumentNode(var container: DocumentContainer, var document: Document) extends DefaultTreeNode {

    override def toString: String = document.id

    this.on("doubleclicked") {

      println("Opening Script")

      // Parse Document
      //----------------
      var doc = container.document(document.id, new RFScript)

      // Send on AIB
      //-----------------
      aib ! (document, doc.get)

    }

  }

  // Prepare Root Model
  //-----------------
  this.root = this
  this.show = false

  //-- Init Children with containers
  db.containers.foreach {
    container =>
      this <= new DefaultTreeNode {

        // Init Container Node from container
        override def toString: String = container.id

        // Add Documents as children
        container.documents.foreach {
          doc => this <= new DocumentNode(container, doc)
        }

        // Listen to document writes
        //---------
        container.onWith("document.writen") {

          pathAndElement: Tuple2[String, RFScript] =>

            this <= new DocumentNode(container, container.document(pathAndElement._1).get)
            ScriptsTree.this.@->("node.reload", this)
        }

      }
  }

  //-- Default value if no containers already
  if (db.containers.size == 0) {
    this <= new DefaultTreeNode {

      override def toString: String = "No Documents already"
    }
  }

  override def createUI = {

    tree {
      t => t.setModel(this)
    }

  }

}
object ScriptsTree {

  def apply(db: DocumentStore) = new ScriptsTree(db)
}