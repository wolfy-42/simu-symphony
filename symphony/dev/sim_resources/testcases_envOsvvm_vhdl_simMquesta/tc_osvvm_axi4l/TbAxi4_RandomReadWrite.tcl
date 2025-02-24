# --------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Xianxin Du
# Created       : 2021-06-04
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testcase for axi4 lite osvvm in vhdl.
#
#               Command Line Options: uses modified scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: TbAxi4_RandomReadWrite
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME TbAxi4_RandomReadWrite
set TCSUBDIR $TESTCASESDIR_OSVVM/tc_osvvm_axi4l

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
append ::OPTIMIZATION_INVOCATION ""
append ::SIMULATOR_INVOCATION ""

puts $SIMULATOR_INVOCATION

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE
