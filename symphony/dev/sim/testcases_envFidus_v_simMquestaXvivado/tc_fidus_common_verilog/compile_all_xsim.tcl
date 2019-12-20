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

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################
# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {

# RTL
exec >&@stdout xvlog -incr "$SIMDIR/../sources/include_parameters.v"
exec >&@stdout xvlog -incr "$SIMDIR/../sources/module1.v" -i $SIMDIR/../sources
exec >&@stdout xvlog -incr "$SIMDIR/../sources/top_simuverilog.v" -i $SIMDIR/../sources

# CORE
exec >&@stdout xvlog -incr "$SIMDIR/cores/xilinx/glbl.v"

# BFM
exec >&@stdout xvlog -incr -sv "$SIMDIR/./libraries/sim_management_verilog.v"
exec >&@stdout xvlog -incr "$SIMDIR/./bfms/fidus_reset_gen_bfm.v"
exec >&@stdout xvlog -incr "$SIMDIR/./bfms/fidus_clock_gen_bfm.v"

# TB
exec >&@stdout xvlog -incr "$TCSUBDIR/tb.v"

}

# TC
eval $TC_COMP_INVOCATION_VERILOG

# ##########################################################################################
