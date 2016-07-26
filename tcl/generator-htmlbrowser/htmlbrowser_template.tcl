<%
variable indent_count
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
            return "../[$item name].html"
        }
    } else {
        return "html/[getAbsoluteName $item _].html"
    }
}

proc getRoot item {
    set current $item
    while {[string compare [$current parent] ""]} {
        set current [$current parent]
    }
    return $current
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

proc subCompIsActive {item activeItem} {
    set current $activeItem
    ## while the root is not reached
    while {[string compare $current ""]} {
        if {!([string compare $current $item])} {
            return true
        } else {
            set current [$current parent]
        }
    }
    return false
}

proc indent count {
    set result {}
    while {$count > 0} {
        set result "$result    "
        set count [expr {$count - 1}]
    }
    return $result
}

proc generateNavigationRec {current activeItem count} {
    ## if $current is a group or registerfile
    if {[$current isa osys::rfg::Group]} {
        if {!([string compare $current $activeItem])} {
            puts "[indent $count]<a href=\"#\" class=\"list-group-item active\">"
        } else {
            puts "[indent $count]<a href=\"[getFileName $current $activeItem]\" class=\"list-group-item\">"
        }
        set count [expr {$count + 1}]
        if {[subCompIsActive $current $activeItem]} {
            puts "[indent $count]<span class=\"glyphicon glyphicon-chevron-down clickable\" data-toggle=\"collapse\" href=\"#[getAbsoluteName $current _]\"></span>[$current name]"
        } else {
            puts "[indent $count]<span class=\"glyphicon glyphicon-chevron-right clickable\" data-toggle=\"collapse\" href=\"#[getAbsoluteName $current _]\"></span>[$current name]"
        }
        puts "[indent $count]<span class=\"badge\">0x[format %x [$current getAttributeValue software.osys::rfg::absolute_address]]</span>"
        set count [expr {$count - 1}]
        puts "[indent $count]</a>"
        if {[subCompIsActive $current $activeItem]} {
            puts "[indent $count]<div class=\"list-group collapse in\" id=\"[getAbsoluteName $current _]\">"
        } else {
            puts "[indent $count]<div class=\"list-group collapse\" id=\"[getAbsoluteName $current _]\">"
        }
        $current onEachComponent {
            if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
                generateNavigationRec $it $activeItem [expr {$count + 1}]
            }
        }
        puts "[indent $count]</div>"
    } else {
        ## if $current is the active component
        if {!([string compare $current $activeItem])} {
            puts "[indent $count]<a href=\"#\" class=\"list-group-item active\">[$current name]"
        } else {
            puts "[indent $count]<a href=\"[getFileName $current $activeItem]\" class=\"list-group-item\">[$current name]"
        }
        set count [expr {$count + 1}]
        puts "[indent $count]<span class=\"badge\">0x[format %x [$current getAttributeValue software.osys::rfg::absolute_address]]</span>"
        set count [expr {$count - 1}]
        puts "[indent $count]</a>"
    }
}

proc getType item {
    if {[$item isa osys::rfg::Register]} {
        return "Register"
    } elseif {[$item isa osys::rfg::RamBlock]} {
        return "RAM Block"
    } elseif {[$item isa osys::rfg::Group]} {
        if {[$item isa osys::rfg::RegisterFile]} {
            return "Register File"
        } else {
            return "Group"
        }
    } else {
        return "-"
    }
}

proc generateSwAttr item {
    $item onEachAttributes {
        if {![string compare [$attrs name] "software"]} {
            $attrs onEachAttribute {
                set attr_name [string range $attr 11 end]
                if {[string compare $attr_name "address_shift"] && [string compare $attr_name "size"] \
                    && [string compare $attr_name "relative_address"] && [string compare $attr_name "absolute_address"]} {
                    puts "                                                                <li>$attr_name</li>"
                }
            }
        }
    }
}

proc generateHwAttr item {
    $item onEachAttributes {
        if {![string compare [$attrs name] "hardware"]} {
            $attrs onEachAttribute {
                set attr_name [string range $attr 11 end]
                puts "                                                                <li>$attr_name</li>"
            }
        }
    }
}

proc getDescription item {
    if {![string compare [$item description] ""]} {
        return "-"
    } else {
        return [$item description]
    }
}

proc generateDescTable activeItem {
    puts "<table class=\"table table-hover\">"
    puts "                            <thead>"
    puts "                                <tr>"
    if {[$activeItem isa osys::rfg::RamBlock]} {
        puts "                                    <th class=\"col-md-3\">Name</th>"
        puts "                                    <th class=\"col-md-2\">Type</th>"
        puts "                                    <th class=\"col-md-1\">Width</th>"
        puts "                                    <th class=\"col-md-1\">Size</th>"
        puts "                                    <th class=\"col-md-1\">Address</th>"
        puts "                                    <th class=\"col-md-4\">Description</th>"
    } elseif {[$activeItem isa osys::rfg::Group] || [$activeItem isa osys::rfg::Register]} {
        puts "                                    <th class=\"col-md-3\">Name</th>"
        puts "                                    <th class=\"col-md-2\">Type</th>"
        puts "                                    <th class=\"col-md-2\">Address</th>"
        puts "                                    <th class=\"col-md-5\">Description</th>"
    }
    puts "                                </tr>"
    puts "                            </thead>"
    puts "                            <tbody>"
    if {[$activeItem isa osys::rfg::Group]} {
        $activeItem onEachComponent {
            if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
                puts "                                <tr class=\"clickable-row\" data-href=\"[getFileName $it $activeItem]\">"
                puts "                                    <td>[$it name]</td>"
                puts "                                    <td>[getType $it]</td>"
                puts "                                    <td>0x[format %x [$it getAttributeValue software.osys::rfg::absolute_address]]</td>"
                puts "                                    <td>[getDescription $it] </td>"
                puts "                                </tr>"
            }
        }
    } elseif {[$activeItem isa osys::rfg::Register]} {
        puts "                                <tr>"
        puts "                                    <td>[$activeItem name]</td>"
        puts "                                    <td>[getType $activeItem]</td>"
        puts "                                    <td>0x[format %x [$activeItem getAttributeValue software.osys::rfg::absolute_address]]</td>"
        puts "                                    <td>[getDescription $activeItem] </td>"
        puts "                                </tr>"
    } elseif {[$activeItem isa osys::rfg::RamBlock]} {
        puts "                                <tr class=\"collapse-row\" data-toggle=\"collapse\" data-target=\"#[getAbsoluteName $activeItem _]\">"
        puts "                                    <td><span class=\"glyphicon glyphicon-chevron-right clickable\"></span> [$activeItem name]</td>"
        puts "                                    <td>[getType $activeItem]</td>"
        puts "                                    <td>[$activeItem width] bit</td>"
        puts "                                    <td>[$activeItem depth]</td>"
        puts "                                    <td>0x[format %x [$activeItem getAttributeValue software.osys::rfg::absolute_address]]</td>"
        puts "                                    <td>[getDescription $activeItem] </td>"
        puts "                                </tr>"
        puts "                                <tr>"
        puts "                                    <td class=\"hidden-row\" colspan=\"6\">"
        puts "                                        <div id=\"[getAbsoluteName $activeItem _]\" class=\"collapse\">"
        puts "                                            <table class=\"table\">"
        puts "                                                <tbody>"
        puts "                                                    <tr>"
        puts "                                                        <td>Software attributes:"
        puts "                                                            <ul>"
        generateSwAttr $activeItem
        puts "                                                            </ul>"
        puts "                                                        </td>"
        puts "                                                        <td>Hardware attributes:"
        puts "                                                            <ul>"
        generateHwAttr $activeItem
        puts "                                                            </ul>"
        puts "                                                        </td>"
        puts "                                                    </tr>"
        puts "                                                </tbody>"
        puts "                                            </table>"
        puts "                                        </div>"
        puts "                                    </td>"
        puts "                                </tr>"
    }
    puts "                            </tbody>"
    puts "                        </table>"
}

proc generateFieldTable item {
    puts "<h4>Fields:</h4>"
    puts "                        <table class=\"table table-hover\">"
    puts "                            <thead>"
    puts "                                <tr>"
    puts "                                    <th class=\"col-md-3\">Name</th>"
    puts "                                    <th class=\"col-md-2\">Width</th>"
    puts "                                    <th class=\"col-md-2\">Reset</th>"
    puts "                                    <th class=\"col-md-5\">Description</th>"
    puts "                                </tr>"
    puts "                            </thead>"
    puts "                            <tbody>"
    $item onEachField {
        if {[string compare [$it name] "Reserved"]} {
            puts "                                <tr class=\"collapse-row\" data-toggle=\"collapse\" data-target=\"#[getAbsoluteName $item _]_[$it name]\">"
            puts "                                    <td><span class=\"glyphicon glyphicon-chevron-right\" ></span> [$it name]</td>"
            puts "                                    <td>[$it width] bit</td>"
            puts "                                    <td>[$it reset]</td>"
            puts "                                    <td>[getDescription $it] </td>"
            puts "                                </tr>"
            puts "                                <tr>"
            puts "                                    <td class=\"hidden-row\" colspan=\"4\">"
            puts "                                        <div id=\"[getAbsoluteName $item _]_[$it name]\" class=\"collapse\">"
            puts "                                            <table class=\"table\">"
            puts "                                                <tbody>"
            puts "                                                    <tr>"
            puts "                                                        <td colspan=\"2\">Path: [getAbsoluteName $item /]/[$it name] </td>"
            puts "                                                    </tr>"
            puts "                                                    <tr>"
            puts "                                                        <td>Software attributes:"
            puts "                                                            <ul>"
            generateSwAttr $it
            puts "                                                            </ul>"
            puts "                                                        </td>"
            puts "                                                        <td>Hardware Attributes:"
            puts "                                                            <ul>"
            generateHwAttr $it
            puts "                                                            </ul>"
            puts "                                                        </td>"
            puts "                                                    </tr>"
            puts "                                                </tbody>"
            puts "                                            </table>"
            puts "                                        </div>"
            puts "                                    </td>"
            puts "                                </tr>"
        } else {
            puts "                                <tr>"
            puts "                                    <td>[$it name]</td>"
            puts "                                    <td>[$it width] bit</td>"
            puts "                                    <td>-</td>"
            puts "                                    <td>-</td>"
            puts "                                </tr>"
        }
    }
        puts "                            </tbody>"
        puts "                        </table>"
}

proc generateNavigation {activeItem} {
    puts "<div class=\"list-group list-group-root\">"
    generateNavigationRec [getRoot $activeItem] $activeItem 7
    puts -nonewline "[indent 6]</div>"
}

proc getJsFolder item {
    if {[string compare [$item parent] ""]} {
        return "../js"
    } else {
        return "js"
    }
}

proc getCssFolder item {
    if {[string compare [$item parent] ""]} {
        return "../css"
    } else {
        return "css"
    }
}

proc getInputId item {
    if {[string compare [$item parent] ""]} {
        return "autocomplete"
    } else {
        return "root-autocomplete"
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
        <!-- User defined css -->
        <link rel="stylesheet" type="text/css" <% puts -nonewline "href=\"[file join [getCssFolder $caller] user_defined.css]\">"%>
    </head>
    <body>
        <div class="container-fluid">
            <div class="row">
                <div class="col-sm-12">
                    <div class="margin-15px">
                        <h3><% puts -nonewline "[getAbsoluteName $caller]"%> Documentation</h3>
                        <% generateBreadcrumb $caller%>
                    </div>
                </div>
            </div>
            <div class="row">
                <div class="col-sm-4">
                    <div class="form-group ui-widget right-inner-addon margin-15px">
                        <i class="glyphicon glyphicon-search"></i>
                        <input <% puts -nonewline "id=\"[getInputId $caller]\""%> type="search" class="form-control" placeholder="Search" />
                    </div>
                    <div class="margin-15px">
                        <% generateNavigation $caller%>
                    </div>
                </div>
                <div class="col-sm-8">
                    <div class="margin-15px">
                        <h3 class="vspace-30px"><% $caller name%></h3>
                        <% generateDescTable $caller%>
                        <%  if {[$caller isa osys::rfg::Register]} {
                                generateFieldTable $caller
                            }%>
                    </div>
                </div>
            </div>
        </div>
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] jquery-1.10.2.min.js]\""%>></script>
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] jquery-ui.min.js]\""%>></script>
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] bootstrap.min.js]\""%>></script>
        <!-- User defined javascript -->
        <script <% puts -nonewline "src=\"[file join [getJsFolder $caller] user_defined.js]\""%>></script>
        <script ></script>
    </body>
</html>
