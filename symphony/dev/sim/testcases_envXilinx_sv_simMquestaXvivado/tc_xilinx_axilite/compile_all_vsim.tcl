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


# CORE
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./cores/xilinx/glbl.v"

# BFM
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axi4lite_mst_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE +define+SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/./libraries/lib_math.v"

# VIP BFM
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/xilinx_axi_vip/axilite_master/sim/axilite_master.sv" -L xilinx_vip -L axi_vip_v1_1_3
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/xilinx_axi_vip/axilite_master/sim/axilite_master_pkg.sv" -L xilinx_vip

# TB
vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv" -L xilinx_vip
# Simulation library settings: -L axi_vip_v1_1_3 -L xilinx_vip

}

# TC
eval $TC_COMP_INVOCATION -L xilinx_vip

# ##########################################################################################
