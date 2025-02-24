# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : B. Piotto
# Created       : 2023-06-26
#
# Description   : Testcase for ethernet BFMs.
# --------------------------------------------------------------------//

# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

set TCFILENAME tc_fidus_eth_pkts
set TCSUBDIR $TESTCASESDIR_FIDUS_SV/tc_fidus_eth_bfm
puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
puts stdout "Sourcing configuration file $TCCOMMON_TCCONFIG"
source $TCCOMMON_TCCONFIG

# Config variables modified here.
append ::OPTIMIZATION_INVOCATION " -debugdb"
append ::SIMULATOR_INVOCATION "  -modelsimini $TCSUBDIR/modelsim.ini -suppress 3070"

# Execute compilation and simulation
puts stdout "Sourcing compilation file $TCCOMMON_TCCOMPILESIMULATE"
source $TCCOMMON_TCCOMPILESIMULATE

