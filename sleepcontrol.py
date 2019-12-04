#! /usr/bin/env python2.7
# Example taken from:
#   https://github.com/jaredks/rumps
#
# This is just a proof of concept.  It doesn't actually do anything.
# I don't actually use this solution because it has issues (see the
# github issues for the above project).
#
# pre-requisites:
#  sudo port install py-pip
#  sudo port select --set pip pip27 
#  sudo pip install pyobjc rumps

import rumps

class SleeperStatusBarApp(rumps.App):
    def __init__(self):
        super(SleeperStatusBarApp, self).__init__("Sleeper")
        self.menu = ["Preferences", "Allow computer to sleep"]

    @rumps.clicked("Preferences")
    def prefs(self, _):
        rumps.alert("No preferences yet")

    @rumps.clicked("Allow computer to sleep")
    def onoff(self, sender):
        sender.state = not sender.state

if __name__ == "__main__":
    SleeperStatusBarApp().run()
