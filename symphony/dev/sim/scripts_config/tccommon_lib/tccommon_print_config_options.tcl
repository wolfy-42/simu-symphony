# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
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

puts stdout "==============tccommon_print_config_options.tcl================"

# Print configured options.
if {$::CMD_ARG_LOGGING > 0} {puts stdout "Logging turned ON."
} else {puts stdout "Logging turned OFF."} 

if {$::CMD_ARG_OPTIMIZE > 0} {puts stdout "Optimization turned ON."
} else {puts stdout "Optimization turned OFF."}

if {$::CMD_ARG_COVERAGE > 0} {puts stdout "Coverage turned ON."
} else {puts stdout "Coverage turned OFF."}

if {$::CMD_ARG_COMPILE > 0} {puts stdout "Compilation turned ON."
} else {puts stdout "Compilation turned OFF."}

if {$::CMD_ARG_VIEW > 0} {puts stdout "Simulation will be RE-OPPENED in viewer mode after running."
} else {puts stdout "Simulation will NOT be RE-OPENED in viewer mode after running."}

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
