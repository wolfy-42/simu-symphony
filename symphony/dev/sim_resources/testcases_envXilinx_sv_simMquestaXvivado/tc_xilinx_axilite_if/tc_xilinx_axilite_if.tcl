#---------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Filename    : tc_xilinx_axilite_if.tcl
# Project     : RIPL/SIMU
# Author      : Paul Roukema
# Created     : May 26, 2021
# Description : Testcase definition for axilite demo
#
#---------------------------------------------------------------------------//

puts stdout "==============tc_xilinx_axilite_if.tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_xilinx_axilite_if
set TCSUBDIR $TESTCASESDIR_XILINX/tc_xilinx_axilite_if

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE
