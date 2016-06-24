<%
## returns a string composed of the name of the item and the names of its parents up to the top register file seperated by "seperator"
proc getAbsoluteName {item {seperator " "}} {
    set result {}
    if {[string compare [$item parent] ""]} {
        set current [$item parent]
        set parents {}
        while {[string compare $current ""]} {
            lappend parents $current
            set current [$current parent]
        }
        foreach p $parents {
            set result "[$p name]$seperator$result"
        }
    }
    return "$result[$item name]"
}

## returns a string composed of the name of the item and the names of its parents up to the enclosing register file seperated by "seperator"
proc getRelativeName {item {seperator " "}} {
    set result {}
    if {!([$item isa osys::rfg::RegisterFile])} {
        set current [$item parent]
        set parents {}
        while {!([$current isa osys::rfg::RegisterFile])} {
            lappend parents $current
            set current [$current parent]
        }
        lappend parents $current
        foreach p $parents {
            set result "[$p name]$seperator$result"
        }
    }
    return "$result[$item name]"
}

proc getFileName {item caller} {
    ## if caller is not the top register file
    if {[string compare [$caller parent] ""]} {
        ## if item is not the top register file
        if {[string compare [$item parent] ""]} {
            return "[getAbsoluteName $item _].html"
        } else {
            return "../RF_TOP.html"
        }
    } else {
        return "html/[getAbsolute $item _].html"
    }
}

proc generateBreadcrumb item {
    set current $item
    set parents {}
    puts "<ul class=\"breadcrumb\">"
    while {[string compare [$current parent] ""]} {
        lappend parents [$current parent]
        set current [$current parent]
    }
    set parents [lreverse $parents]
    foreach p $parents {
        puts "                        <li><a href=\"[getFileName $p $item]\">[$p name]</a></li>"
    }
    puts "                        <li class=\"active\">[$item name]</li>"
    puts -nonewline "                    </ul>"
}

proc getCssFolder item {
    if {[string compare [$item parent] ""]} {
        return "../css"
    } else {
        return "css"
    }
}

proc getJsFolder item {
    if {[string compare [$item parent] ""]} {
        return "../js"
    } else {
        return "js"
    }
}
%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title><% puts -nonewline "[getAbsoluteName $caller]"%> Documentation</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" type="text/css" <% puts -nonewline "href=\"[file join [getCssFolder $caller] bootstrap.min.css]\">"%>
        <!-- Optional Bootstrap theme -->
        <link rel="stylesheet" <% puts -nonewline "href=\"[file join [getCssFolder $caller] bootstrap-theme.min.css]\">"%>
        <!-- User defined css -->
        <link rel="stylesheet" type="text/css" <% puts -nonewline "href=\"[file join [getCssFolder $caller] user_defined.css]\">"%>
    </head>
    <body>
        <div class="container-fluid">
            <div class="row">
                <div class="col-sm-12">
                    <h3><% puts -nonewline "[getAbsoluteName $caller]"%> Documentation</h3>
                    <% generateBreadcrumb $caller%>
                </div>
            </div>
            <div class="row">
                <div class="col-sm-4">
                    <div class="just-padding">
                        <div class="list-group list-group-root">
                            <a href="#" class="list-group-item active">
                            <span class="glyphicon glyphicon-chevron-down" data-toggle="collapse" href="#RF_TOP"></span>RF_TOP
                            <span class="badge">0x0</span>
                            </a>
                            <div class="list-group collapse in" id="RF_TOP">
                                <a href="html/RF_TOP_REG_0.html" class="list-group-item">REG_0
                                <span class="badge">0x0</span>
                                </a>
                                <a href="#" class="list-group-item">REG_1
                                <span class="badge">0x8</span>
                                </a>
                                <a href="html/RF_BOTTOM.html" class="list-group-item">
                                <span class="glyphicon glyphicon-chevron-right" data-toggle="collapse" href="#RF_BOTTOM"></span>RF_BOTTOM
                                <span class="badge">0x40</span>
                                </a>
                                <div class="list-group collapse" id="RF_BOTTOM">
                                    <a href="#" class="list-group-item">REG_2
                                    <span class="badge">0x40</span>
                                    </a>
                                    <a href="#" class="list-group-item">REG_3
                                    <span class="badge">0x48</span>
                                    </a>
                                    <a href="html/RF_BOTTOM_RAM_0.html" class="list-group-item">RAM_0
                                    <span class="badge">0x50</span>
                                    </a>
                                    <a href="#" class="list-group-item">RAM_1
                                    <span class="badge">0x60</span>
                                    </a>
                                </div>
                                <a href="#" class="list-group-item">REG_4
                                <span class="badge">0x80</span>
                                </a>
                                <a href="#" class="list-group-item">REG_5
                                <span class="badge">0x88</span>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-sm-8">
                    <h3 class="vspace-30px">RF_TOP</h3>
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Type</th>
                                <th>Address</th>
                                <th>Path</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="clickable-row" data-href="html/RF_TOP_REG_0.html">
                                <td>REG_0</td>
                                <td>Register</td>
                                <td>0x0</td>
                                <td>RF_TOP/REG_0</td>
                            </tr>
                            <tr class="clickable-row" data-href="#">
                                <td>REG_1</td>
                                <td>Register</td>
                                <td>0x8</td>
                                <td>RF_TOP/REG_1</td>
                            </tr>
                            <tr class="clickable-row" data-href="html/RF_BOTTOM.html">
                                <td>RF_BOTTOM</td>
                                <td>Register File</td>
                                <td>0x40</td>
                                <td>RF_TOP/RF_BOTTOM</td>
                            </tr>
                            <tr class="clickable-row" data-href="#">
                                <td>REG_4</td>
                                <td>Register</td>
                                <td>0x80</td>
                                <td>RF_TOP/REG_4</td>
                            </tr>
                            <tr class="clickable-row" data-href="#">
                                <td>REG_5</td>
                                <td>Register</td>
                                <td>0x88</td>
                                <td>RF_TOP/REG_4</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] jquery-1.10.2.min.js]\""%>></script>
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] bootstrap.min.js]\""%>></script>
        <!-- User defined javascript -->
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] user_defined.js]\""%>></script>
    </body>
</html>
