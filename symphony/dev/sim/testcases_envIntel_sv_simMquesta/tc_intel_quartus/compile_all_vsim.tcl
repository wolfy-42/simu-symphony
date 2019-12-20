# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Victor Dumitriu
# Created       : 2018-03-20
# ----------------------------------------------------------------------//
# Description   : Module-wide compilation commands used by test-case
#               simulation scripts.
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

puts stdout "==============compile_all_vsim.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################
# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {


set QSYS_SIMDIR $TCSUBDIR/intel_avalon_example_system/testbench

# Source default simulation environment.
source $QSYS_SIMDIR/mentor/msim_setup.tcl

# Set compilation options.
#set USER_DEFINED_COMPILE_OPTIONS "+cover=bcefs +acc"

# Compile libraries.
dev_com

# Compile testbench files.
com

# BFM
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"

# TB
vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv" -L altera_common_sv_packages

}

# TC
eval $TC_COMP_INVOCATION -L altera_common_sv_packages

# ##########################################################################################
