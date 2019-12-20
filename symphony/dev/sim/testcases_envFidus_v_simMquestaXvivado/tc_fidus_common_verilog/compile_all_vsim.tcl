# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Victor Dumitriu
# Created       : 2018-03-20
# ----------------------------------------------------------------------//
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


vlog -incr -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$SIMDIR/../sources/include_parameters.v"
vlog -incr -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$SIMDIR/../sources/module1.v" +incdir+$SIMDIR/../sources
vlog -incr -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$SIMDIR/../sources/top_simuverilog.v" +incdir+$SIMDIR/../sources

# CORE
vlog -incr -timescale $TCTIMESCALE "$SIMDIR/./cores/xilinx/glbl.v"

# BFM
vlog -incr -sv -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
vlog -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.v"
vlog -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.v"

# TB
vlog -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.v"

}

# TC
eval $TC_COMP_INVOCATION_VERILOG

# ##########################################################################################
