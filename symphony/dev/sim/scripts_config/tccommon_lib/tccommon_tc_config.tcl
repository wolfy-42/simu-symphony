# --------------------------------------------------------------------//
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-25
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Common test case structure for configuration before simulation
#
# Updated       : 2019-10-25 / author - comment
# --------------------------------------------------------------------//

puts stdout "==============tccommon_tc_config.tcl================\n"

############################ Prepare Simulation ############################################
# A new tc will be run in a new sim environment, new log and new results folder are created
source $SCRPTTCOMMONDIR/tccommon_init_sim.tcl
# Initialize simulation - random seed value, can be forced here to a constant value
source $SCRPTTCOMMONDIR/tccommon_adjust_seed.tcl
# Sets coverage parameters if enabled in the commandline arguments
source $SCRPTTCOMMONDIR/tccommon_adjust_coverage.tcl
# The regression script can disable the start of waveform viewer or compilation for a testcase if it has already been done. 
source $SCRPTTCOMMONDIR/tccommon_adjust_regression.tcl
# Print config options/settings for information
source $SCRPTTCOMMONDIR/tccommon_print_config_options.tcl

