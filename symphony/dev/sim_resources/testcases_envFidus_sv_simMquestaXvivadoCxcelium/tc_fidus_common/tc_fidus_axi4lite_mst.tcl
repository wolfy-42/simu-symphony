# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-06-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testbench for clock and reset BFMs.
#               Intentionally fails for demonstration purposes.
#
#               Command Line Options: uses modified scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: tc_fidus_axi4lite_mst
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_fidus_axi4lite_mst
set TCSUBDIR $TESTCASESDIR_FIDUS_SV/tc_fidus_common
puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# common test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
append ::OPTIMIZATION_INVOCATION ""
append ::SIMULATOR_INVOCATION ""

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE