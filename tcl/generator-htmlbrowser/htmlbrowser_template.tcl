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
            return "../RF_TOP.html"
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
            generateNavigationRec $it $activeItem [expr {$count + 1}]
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
    $item onAttributes {software.osys::rfg::rw} {
        puts "                                                                <li>rw</li>"
    }
    $item onAttributes {software.osys::rfg::ro} {
        puts "                                                                <li>ro</li>"
    }
    $item onAttributes {software.osys::rfg::wo} {
        puts "                                                                <li>wo</li>"
    }
    $item onAttributes {software.osys::rfg::write_clear} {
        puts "                                                                <li>write_clear</li>"
    }
    $item onAttributes {software.osys::rfg::write_xor} {
        puts "                                                                <li>write_xor</li>"
    }
}

proc generateHwAttr item {
    $item onAttributes {hardware.osys::rfg::rw} {
        puts "                                                                <li>rw</li>"
    }
    $item onAttributes {hardware.osys::rfg::ro} {
        puts "                                                                <li>ro</li>"
    }
    $item onAttributes {hardware.osys::rfg::wo} {
        puts "                                                                <li>wo</li>"
    }
    $item onAttributes {hardware.osys::rfg::changed} {
        puts "                                                                <li>changed</li>"
    }
    $item onAttributes {hardware.osys::rfg::clear} {
        puts "                                                                <li>clear</li>"
    }
    $item onAttributes {hardware.osys::rfg::counter} {
        puts "                                                                <li>counter</li>"
    }
    $item onAttributes {hardware.osys::rfg::edge_trigger} {
        puts "                                                                <li>edge_trigger</li>"
    }
    $item onAttributes {hardware.osys::rfg::external} {
        puts "                                                                <li>external</li>"
    }
    $item onAttributes {hardware.osys::rfg::internal} {
        puts "                                                                <li>internal</li>"
    }
    $item onAttributes {hardware.osys::rfg::no_wen} {
        puts "                                                                <li>no_wen</li>"
    }
    $item onAttributes {hardware.osys::rfg::rreinit} {
        puts "                                                                <li>rreinit</li>"
    }
    $item onAttributes {hardware.osys::rfg::rreinit_source} {
        puts "                                                                <li>rreinit_source</li>"
    }
    $item onAttributes {hardware.osys::rfg::shared_bus} {
        puts "                                                                <li>shared_bus</li>"
    }
    $item onAttributes {hardware.osys::rfg::software_written} {
        puts "                                                                <li>software_written</li>"
    }
    $item onAttributes {hardware.osys::rfg::sticky} {
        puts "                                                                <li>sticky</li>"
    }
    $item onAttributes {hardware.osys::rfg::trigger} {
        puts "                                                                <li>trigger</li>"
    }
    $item onAttributes {hardware.osys::rfg::wen} {
        puts "                                                                <li>wen</li>"
    }
}

proc generateDescTable activeItem {
    puts "<table class=\"table table-hover\">"
    puts "                            <thead>"
    puts "                                <tr>"
    puts "                                    <th>Name</th>"
    puts "                                    <th>Type</th>"
    if {[$activeItem isa osys::rfg::RamBlock]} {
    puts "                                    <th>Width</th>"
    puts "                                    <th>Size</th>"
    }
    puts "                                    <th>Address</th>"
    puts "                                    <th>Path</th>"
    puts "                                </tr>"
    puts "                            </thead>"
    puts "                            <tbody>"
    if {[$activeItem isa osys::rfg::Group]} {
        $activeItem onEachComponent {
            puts "                                <tr class=\"clickable-row\" data-href=\"[getFileName $it $activeItem]\">"
            puts "                                    <td>[$it name]</td>"
            puts "                                    <td>[getType $it]</td>"
            puts "                                    <td>0x[format %x [$it getAttributeValue software.osys::rfg::absolute_address]]</td>"
            puts "                                    <td>[getAbsoluteName $it /]</td>"
            puts "                                </tr>"
        }
    } elseif {[$activeItem isa osys::rfg::Register]} {
        puts "                                <tr>"
        puts "                                    <td>[$activeItem name]</td>"
        puts "                                    <td>[getType $activeItem]</td>"
        puts "                                    <td>0x[format %x [$activeItem getAttributeValue software.osys::rfg::absolute_address]]</td>"
        puts "                                    <td>[getAbsoluteName $activeItem /]</td>"
        puts "                                </tr>"
    } elseif {[$activeItem isa osys::rfg::RamBlock]} {
        puts "                                <tr>"
        puts "                                    <td><span data-toggle=\"collapse\" data-target=\"#[getAbsoluteName $activeItem _]\" class=\"glyphicon glyphicon-chevron-right clickable\"></span> [$activeItem name]</td>"
        puts "                                    <td>[getType $activeItem]</td>"
        puts "                                    <td>[$activeItem width] bit</td>"
        puts "                                    <td>[$activeItem depth]</td>"
        puts "                                    <td>0x[format %x [$activeItem getAttributeValue software.osys::rfg::absolute_address]]</td>"
        puts "                                    <td>[getAbsoluteName $activeItem /]</td>"
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
    puts "                                    <th>Name</th>"
    puts "                                    <th>Width</th>"
    puts "                                    <th>Reset</th>"
    puts "                                    <th>Path</th>"
    puts "                                </tr>"
    puts "                            </thead>"
    puts "                            <tbody>"
    $item onEachField {
        if {[string compare [$it name] "Reserved"]} {
            puts "                                <tr>"
            puts "                                    <td><span class=\"glyphicon glyphicon-chevron-right clickable\" data-toggle=\"collapse\" data-target=\"#[getAbsoluteName $item _]_[$it name]\"></span> [$it name]</td>"
            puts "                                    <td>[$it width] bit</td>"
            puts "                                    <td>[$it reset]</td>"
            puts "                                    <td>[getAbsoluteName $item /]/[$it name]</td>"
            puts "                                </tr>"
            puts "                                <tr>"
            puts "                                    <td class=\"hidden-row\" colspan=\"4\">"
            puts "                                        <div id=\"[getAbsoluteName $item _]_[$it name]\" class=\"collapse\">"
            puts "                                            <table class=\"table\">"
            puts "                                                <tbody>"
            puts "                                                    <tr>"
            puts "                                                        <td colspan=\"2\">Description: [$it description]</td>"
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
                        <h4>Description: <% $caller description%></h4>
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
