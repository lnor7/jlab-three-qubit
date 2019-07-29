# File: delay.tcl
# Date: 23-Jan-03
# Author: Kenneth Jensen <sanctity@mit.edu>
#
# Description:  Displays a countdown of a specified length.
#
# Usage: delay [time]
#
# time - the time in seconds for the countdown
#
# Notes:  Compiled with freewrap 5.5

set start [clock seconds]
set delay $argv
set time [clock seconds]


wm title . "Pulse countdown"
font create .f -size 50
while { ($time-$start) < $delay } {
    set time [clock seconds]
    destroy .time
    label .time -text [expr $delay-$time+$start] -width 7 -font .f
    pack .time -side top -padx 10 -pady 10
    update
    while { $time == [clock seconds] } {}
} 
exit

