# --------------------------------------------------------------------//
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : VIP Simu SystemVerilog
# Author        : Jacob von Chorus
# Created       : 2018-06-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testcase for clock and reset bfms.
#               Intentially fails for demonstration purposes.
#
#               Command Line Options: Modify scripts_config/cmd_line_options.tcl
#
#               test-case: tc_fidus_clock_reset_verilog
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# General config file
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_fidus_clock_reset_verilog
set TCSUBDIR $TESTCASESDIR2/tc_fidus_common_verilog

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
append ::OPTIMIZATION_INVOCATION ""
append ::SIMULATOR_INVOCATION "" 

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE

