#! /usr/bin/env wish8.5
# Adapted from brilliant example here:
#   http://stackoverflow.com/questions/166231/tcl-tk-examples

package require Tk

proc main {} {
    if {[lsearch -exact [font names] TkDefaultFont] == -1} {
        # older versions of Tk don't define this font, so pick something
        # suitable
        font create TkDefaultFont -family Helvetica -size 12
    }
    # in 8.5 we can use {*} but this will work in earlier versions
    eval font create TkBoldFont [font actual TkDefaultFont] -weight bold

    buildUI
}

proc buildUI {} {
    frame .toolbar
    scrollbar .vsb -command [list .t yview]
    text .t \
        -width 80 -height 10 \
        -yscrollcommand [list .vsb set] \
        -highlightthickness 0
    .t tag configure command -font TkBoldFont
    .t tag configure error   -font TkDefaultFont -foreground firebrick
    .t tag configure output  -font TkDefaultFont -foreground black

    grid .toolbar -sticky nsew
    grid .t .vsb  -sticky nsew
    grid rowconfigure . 1 -weight 1
    grid columnconfigure . 0 -weight 1

    set i 0
    foreach {label command} {
        awake     {prevent_computer_sleep}
        sleep     {allow_computer_sleep}
        status    {pmset -g | grep sleep}
    } {
        button .b$i -text $label -command [list runCommand $command]
        pack .b$i -in .toolbar -side left
        incr i
    }
}

proc output {type text} {
    .t configure -state normal
    .t insert end $text $type "\n"
    .t see end
    .t configure -state disabled
}

proc runCommand {cmd} {
    output command $cmd
    set f [open "| $cmd" r]
    fconfigure $f -blocking false
    fileevent $f readable  [list handleFileEvent $f]
}

proc closePipe {f} {
    # turn blocking on so we can catch any errors
    fconfigure $f -blocking true
    if {[catch {close $f} err]} {
        output error $err
    }
}

proc handleFileEvent {f} {
    set status [catch { gets $f line } result]
    if { $status != 0 } {
        # unexpected error
        output error $result
        closePipe $f

    } elseif { $result >= 0 } {
        # we got some output
        output normal $line

    } elseif { [eof $f] } {
        # End of file
        closePipe $f

    } elseif { [fblocked $f] } {
        # Read blocked, so do nothing
    }
}

main
