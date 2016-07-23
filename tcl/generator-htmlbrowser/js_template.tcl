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

## get file name of item relative to the root directory
proc getFileNameRoot item {
    if {[string compare [$item parent] ""]} {
        return "html/[getAbsoluteName $item _].html"
    } else {
        return "[$item name].html"
    }
}

## get file name of item relative to the html directory
proc getFileName item {
        ## if item is not the top register file
        if {[string compare [$item parent] ""]} {
            return "[getAbsoluteName $item _].html"
        } else {
            return "../[$item name].html"
        }
}

## generate source with links relative to html directory
proc generateSourceHtml {root} {
    puts "{ value: \"[getAbsoluteName $root /]\","
    puts "              url: \"[getFileName $root]\""
    puts "            } , "
    $root walkDepthFirst {
        if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
            puts "            { value: \"[getAbsoluteName $it /]\","
            puts "              url: \"[getFileName $it]\""
            puts "            } , "
        }
        if {[$it isa osys::rfg::Register]} {
            $it onEachField {
                if {[string compare [$it name] "Reserved"]} {
                    puts "            { value: \"[getAbsoluteName [$it parent] /]/[$it name]\","
                    puts "              url: \"[getFileName [$it parent]]\""
                    puts "            } , "
                }
            }
        }
        return true
    }
}

## generate source with links relative to root directory
proc generateSourceRoot {root} {
    puts "{ value: \"[getAbsoluteName $root /]\","
    puts "              url: \"[getFileNameRoot $root]\""
    puts "            } , "
    $root walkDepthFirst {
        if {[$it isa osys::rfg::Group] || [$it isa osys::rfg::Register] || [$it isa osys::rfg::RamBlock]} {
            puts "            { value: \"[getAbsoluteName $it /]\","
            puts "              url: \"[getFileNameRoot $it]\""
            puts "            } , "
        }
        if {[$it isa osys::rfg::Register]} {
            $it onEachField {
                if {[string compare [$it name] "Reserved"]} {
                    puts "            { value: \"[getAbsoluteName [$it parent] /]/[$it name]\","
                    puts "              url: \"[getFileNameRoot [$it parent]]\""
                    puts "            } , "
                }
            }
       }
        return true
    }
}
%>

$(function() {
        
  $('.clickable').on('click', function() {
    $(this)
      .toggleClass('glyphicon-chevron-right')
      .toggleClass('glyphicon-chevron-down');
  });
});

$(function() {
         
  $('.collapse-row').on('click', function() {
    $('.glyphicon' ,this)
      .toggleClass('glyphicon-chevron-right')
      .toggleClass('glyphicon-chevron-down');
  });
});

$(function() {
    $(".clickable-row").click(function() {
        window.document.location = $(this).data("href");
    });
});

$(document).ready(function() {
    $("input#autocomplete").autocomplete({
        source: [
            <% generateSourceHtml $caller%>
        ],
        select: function( event, ui ) { 
            window.location = ui.item.url;
        }
    });
});

$(document).ready(function() {
    $("input#root-autocomplete").autocomplete({
        source: [
            <% generateSourceRoot $caller%>
        ],
        select: function( event, ui ) { 
            window.location = ui.item.url;
        }
    });
});
