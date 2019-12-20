# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-08-20
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Module-wide compilation commands used by test-case
#               simulation scripts.
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

puts stdout "==============compile_all_activehdl.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################
# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {

#set diamond_dir /export/ssd/Lattice/diamond/3.10_x64/

# RTL
vlog -sv2k12 -incr -dbg -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$SIMDIR/../sources/include_parameters.v"
vlog -sv2k12 -incr -dbg -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$SIMDIR/../sources/module1.v" +incdir+$SIMDIR/../sources
vlog -sv2k12 -incr -dbg -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$SIMDIR/../sources/top_simuverilog.v" +incdir+$SIMDIR/../sources

# CORE


# BFM
vlog -sv2k12 -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
vlog -sv2k12 -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
vlog -sv2k12 -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
vlog -sv2k12 -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
vlog -sv2k12 -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axi4lite_mst_bfm.sv"
vlog -sv2k12 -incr -timescale $TCTIMESCALE +define+SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/./libraries/lib_math.v"

# TB
vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv"

}

# TC
eval $TC_COMP_INVOCATION

# define top level
#module tb


# ##########################################################################################
