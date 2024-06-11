# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2018-12-12
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Inserted in every test-case to print settings
#
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

puts_debug1 "==============tccommon_print_config_options.tcl================"

# Print configured options.
if {$::CMD_ARG_WAVELOGGING > 0} {puts stdout "Logging turned ON."
} else {puts stdout "Wave-logging turned OFF."} 

if {$::CMD_ARG_OPTIMIZE > 0} {puts stdout "Optimization turned ON."
} else {puts stdout "Optimization turned OFF."}

if {$::CMD_ARG_COVERAGE > 0} {puts stdout "Coverage turned ON."
} else {puts stdout "Coverage turned OFF."}

if {$::CMD_ARG_COMPILE > 0} {puts stdout "Compilation turned ON."
} else {puts stdout "Compilation turned OFF."}

if {$::CMD_ARG_VIEW > 0} {puts stdout "Simulation will be RE-OPPENED in GUI mode after running."
} else {puts stdout "Simulation will NOT be RE-OPENED in GUI mode after running."}

if {$::CMD_ARG_UVM > 0} {puts stdout "Simulation will use UVM files in the testcase."
}

# INITSEED is either randomly set, or set to CMD_ARG_SEED if it is non-empty.
puts stdout "Seed is set to $INITSEED."

# Coverage parameters
puts stdout "Coverage is set to $COVERAGE_PARAMS"

if {[info exists ::REGRESSION]} {
    if {$::REGRESSION eq "yes"} {   
        puts stdout "Regression mode is detected."
    } else {puts stdout "Single testcase mode of operation active - regression mode is not detected."}
} else {
    puts stdout "Regression is not set, therefore not detected."
}

puts stdout "PWD is "
set tmp_pwd [pwd]
puts stdout "$tmp_pwd"

puts stdout "\n"
