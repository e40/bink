The sleepcontrol files in this directory are my attempt to control
when my computer (not display) goes to sleep.

There are three attempts to solve this problem here:

  sleepcontrol     :: flawed solution using cocoaDialog
  sleepcontrol.py  :: proof of concept in Python
  sleepcontrol.tcl :: pretty good solution using Tcl/Tk

sleepcontrol.command is just the launcher for the Tcl/Tk version, so it
can be a Finder shortcut.

Turns out, I don't use any of them, in practice, since I found and
modified KeepingYouAwake.

