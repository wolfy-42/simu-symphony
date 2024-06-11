# ---------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
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

puts_debug1 "==============tccommon_adjust_regression.tcl================"

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
