# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Regression mode detection and configuration
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_adjust_regression.tcl================"

puts stdout "Checking if regression is set or not."

# The regression script can disable compilation for a testcase if it has already
# been done. 
# Regression will disable the start of the waveform viewer as well.
if {[info exists ::REGRESSION]} {
    if {$::REGRESSION eq "yes"} {    
        set ::CMD_ARG_COMPILE         $::REGRESSION_COMPILE_ALL
        set ::CMD_ARG_VIEW 0
    }
puts stdout "Regression is set to $::REGRESSION "    
}