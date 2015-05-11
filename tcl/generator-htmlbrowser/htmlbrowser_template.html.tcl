<%

proc breadCrumbsName item {

    puts "<ol class=\"breadcrumb\" style=\"display:inline\">"

    set parents {}
    set current $item
    while {$current!=""} {
        lappend parents $current
        set current [$current parent]
    }
    set parents [lreverse $parents]
    foreach p $parents {
        puts "<li>[$p name]</li>"
    }

    puts "</ol>"

}

proc dataName {item {sep "/"}} {

    set names {}
    foreach p [$item parents] {
        lappend names [$p name]
    }
   
    return [join $names $sep]
}

## Functions
proc writeGroup {out group} {

    #[$group name]
    # [breadCrumbsName $group]
    if {[$group getAttributeValue software.osys::rfg::absolute_address] != false} {
        puts "<ul data-name=\"[dataName $group]\">


        <li>
            <span class=\"glyphicon glyphicon-book\"></span>[$group name]
            <span class=\"badge\">0x[format %x [$group getAttributeValue software.osys::rfg::absolute_address]]</span>
        "       
    } else {
        puts "<ul data-name=\"[dataName $group]\">


        <li>
            <span class=\"glyphicon glyphicon-book\"></span>[$group name]
        "
    }



    $group onEachGroup {

        writeGroup $out $it
    } 

    $group onEachComponent {
        if {[$it isa osys::rfg::Register]} {
            writeRegister $out $it  
        }
        if {[$it isa osys::rfg::RamBlock]} {
            writeRamBlock $it
        }
    } 

    puts "</li>"
    puts "</ul>"


}

proc writeRegister {out register} {

    set regPath [dataName $register]
    set regId   [dataName $register -]

    puts "<ul data-name=\"[dataName $register]\">
            <li> <span class=\"glyphicon glyphicon-list\"></span> [$register name] <span class=\"badge\">0x[format %x [$register  getAttributeValue software.osys::rfg::absolute_address]]</span> <span class=\"caret\" onclick=\"openClose('$regId')\"></span>
            <p>
                [$register description]
            </p>
    "

    ## Start
    puts "<div id=\"$regId\" style=\"display:none\">"

    ## Scala Code
    #################

    puts "
    <div>
        <h4>Scala API Path</h4>
        <pre>
    var [$register name] = read(\"$regPath\")
    write(value) into \"$regPath\"
        </pre>
    </div>

    "

    $register onEachField {
        set fieldId   [dataName $it -]
        puts "<ul data-name=\"[dataName $it]\">
            <li> <span class=\"glyphicon glyphicon-minus\"></span> [$it name] <span class=\"badge\">width: [$it width]</span><span class=\"caret\" onclick=\"openClose('$fieldId')\"></span>
            </ul>
            "
        puts "<div id=\"$fieldId\" style=\"display:none\">"
        ## put here description 
        puts "<h4>Description: </h4>"
        puts "[$it description]"
    
        ## Attributes
        #################
        puts "<td>"

        ## start of table
        puts "<table class=\"table table-bordered table-hover table-condensed\">"

        ## Header
        puts "<theader>"

        puts "<tr>
                <th>Name</th>
                <th>Value</th>
            </tr>"
        puts "</theader>"

        ## Content
        puts "<tbody>"
        $it onEachAttributes {
            puts "<tr><td colspan='2'>[$attrs name]</td></tr>"

            $attrs onEachAttribute {
                puts "<tr>
                        <td>$attr</td>
                        <td>$value</td>
                    </tr>"
            }

        }
        puts "</tbody>"

        ## end of table
        puts "</table>"

        puts "</td>"
        ## Path and final
        puts "<td>${regPath}.[$it name]</td>"
        puts "</tr>"
        puts "</div>"
    }

    ## End
    puts "</div>"

    puts "</li>"
    puts "</ul>"


}

proc writeRamBlock {ramBlock} {
    set ramBlockPath [dataName $ramBlock]
    set ramBlockId   [dataName $ramBlock -]

    puts "<ul data-name=\"[dataName $ramBlock]\">
            <li> <span class=\"glyphicon glyphicon-list\"></span> [$ramBlock name] <span class=\"badge\">0x[format %x [$ramBlock  getAttributeValue software.osys::rfg::absolute_address]]</span> <span class=\"badge\">width: [$ramBlock width] </span> <span class=\"badge\">size: [$ramBlock depth] </span> <span class=\"caret\" onclick=\"openClose('$ramBlockId')\"></span>
            <p>
                [$ramBlock description]
            </p>
    "

    ## Start
    puts "<div id=\"$ramBlockId\" style=\"display:none\">"

    ## Scala Code
    #################

    puts "
    <div>
        <h4>Scala API Path</h4>
        <pre>
    var [$ramBlock name] = read(\"$ramBlockPath\[\$address\]\")
    write(value) into \"$ramBlockPath\[\$address\]\"
        </pre>
    </div>

    "
    ## End
    puts "</div>"

    puts "</li>"
    puts "</ul>"
}

proc writeField {out field} {

    
return
## Reset 
set reset "reset=\"[$field reset]\""

## Output 
odfi::common::println "<Field name=\"[$field name]\"  width=\"[$field width]\" $reset >"  $out 
odfi::common::printlnIndent
writeDescription $out $field
$field onEachAttributes {
        writeAttributes $out $it        
}
odfi::common::printlnOutdent
odfi::common::println "</Field>" $out
}

proc writeAttributes {out attributes} {
           
odfi::common::println "<Attributes for=\"[$attributes name]\">"  $out
odfi::common::printlnIndent
writeDescription $out $attributes            
foreach element [$attributes attr_list] { ## write each attribute
   if {[llength $element] == 2} {
        odfi::common::println "<Attribute name=\"[lindex $element 0]\">[lindex $element 1]</Attribute>"  $out
   } else {
        odfi::common::println "<Attribute name=\"$element\"/>"  $out
   }
}
odfi::common::printlnOutdent
odfi::common::println "</Attributes>" $out
}

%>
<html>
    <head>
        

    <!-- JQuery -->
    <script src="bs/jquery-1.10.2.min.js"></script>

    <!-- JQuery UI -->
    <script src="bs/jquery-ui.js"></script>
    <link rel="stylesheet" href="bs/bootstrap.min.css">

    <!-- Latest compiled and minified CSS -->
    <link rel="stylesheet" href="bs/bootstrap.min.css">

    <!-- Optional theme -->
    <link rel="stylesheet" href="bs/bootstrap-theme.min.css">

    <!-- Latest compiled and minified JavaScript -->
    <script src="bs/bootstrap.min.js"></script>

    <style type="text/css">

    .ui-autocomplete {
        background-color: white;
        border: 1px black solid;
    }

    </style>

    <script>

    function openClose(elementId) {
        console.log("Open close")
        $("#"+elementId).toggle("slow")
    }
    function updateFilter() {

        var filter = $("#filter").val()
        //console.log("Filter: "+filter)

        if (filter) {

            // Hide All
            //--------------
            $("#rfg-tree ul").each(function(i,element) {
            //console.log("found")
                $(element).hide()


            })

            // Show Parents
            //--------------
            $("ul[data-name*='"+filter+"']").each(function(i,element) {
            //console.log("found")

                // Show Parents

                $(element).show()

                $($(element).parents()).each(function(i,e){ $(e).show()})

            })
        } else {

            $("#rfg-tree ul").each(function(i,element) {
            //console.log("found")
            $(element).show()
            })

        }
        

        ///[$item parents]

    }

    </script

    </head>
    <body>
        
    <h1><% puts [$registerFile name] %></h1>

    <!-- Filter -->
    <div class="ui-widget">
      <label for="filter">Filter: </label>
       <input type="text" id="filter" onkeyup="updateFilter()" style="width:100%"/>
    </div>
 

    <!-- Tree -->
    <!-- #### -->
    <div id="rfg-tree">
    <%
        writeGroup "" $registerFile
        #puts "<li> [$registerFile name]"




        #puts "</li>"

    %>

    </div>

    <!-- Autocomplete -->
    <script>
    <%

        set paths {}

        $registerFile walk {

            lappend paths "\"[dataName $item "/"]\""

        }
        

    %>
    $(function() {
    var availableTags = [
      <% puts [join $paths " "]%>
    ];
    /*$( "#filter" ).autocomplete({
      source: availableTags
    });*/
  });
    </script>

    </body>

</html>