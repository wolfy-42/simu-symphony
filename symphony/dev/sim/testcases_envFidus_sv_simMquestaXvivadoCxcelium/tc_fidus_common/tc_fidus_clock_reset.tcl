# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-05-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testcase for clock and reset BFMs.
#               Intentionally fails for demonstration purposes.
#
# Updated       : 2019-10-08 / Dessislav Valkov - simplified and extracted the common tasks
#               to separate files
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
# TODO: make the name auto detected
set TCFILENAME tc_fidus_clock_reset
# TODO: make the folder auto detected
set TCSUBDIR $TESTCASESDIR_FIDUS_SV/tc_fidus_common
puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
append ::OPTIMIZATION_INVOCATION ""
append ::SIMULATOR_INVOCATION ""

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE