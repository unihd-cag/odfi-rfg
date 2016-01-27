#provide a tclsh-ish main for a starpack which contains libraries
puts "Argv0: [file dirname $argv0]"
lappend auto_path [file join [file dirname $argv0] lib odfi-dev-tcl tcl]
lappend auto_path [file join [file dirname $argv0] lib odfi-rfg tcl]

puts "Autopath: $auto_path"

package require osys::rfg
package require osys::generator

proc read_eval_print {} {
    global errorInfo

    while {1} {
        puts -nonewline "% "
        flush stdout
        if {[gets stdin line] >= 0} {
            if {[catch {uplevel \#0 $line} result]} {
                puts $result
            } else {
                puts $result
            }
        } else {
            exit
        }
    }
}

# add the current dir to the auto_path

if {[llength $argv] == 0} {
    # show a prompt
    if {[info commands console] != ""} {
        console show
    } else {
        read_eval_print
    }
} else {
    set sourcefile [lindex $argv 0]
    set argv [lrange $argv 1 end]
    if {$sourcefile == "run_test"} {
        ::puts "Running Tests..."
        cd [file dirname $argv0]/lib/odfi-rfg/unit-tests/rfg_api/
        source testAll.tcl
        cd [file dirname $argv0]/lib/odfi-rfg/examples/
        ::puts "Running Exmaples"
        source GenerateRF.tcl

    } else {
        # source the file into this interpreter
        source $sourcefile
    }
}
