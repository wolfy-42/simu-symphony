# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Set the simulation seed
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_adjust_seed.tcl================"

# Dummy value, overwritten by the function below using the command line arguments
set INITSEED 0
# Initialize simulation - random seed value, quits simulation, creates a log directory, resets the log file
# cmd_arg_seed is the input from the command line arguments.
# INITSEED is either randomly set, or set to CMD_ARG_SEED if it is non-empty.
if {$::CMD_ARG_SEED eq ""} {
    set INITSEED [clock seconds]
    puts stdout "Seed is random and is set to unix time $INITSEED."
} else {
    set INITSEED $::CMD_ARG_SEED
    puts stdout "Seed is forced externally to $INITSEED."
}