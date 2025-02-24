# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
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

# RTL
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$SIMDIR/../sources/include_parameters.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$SIMDIR/../sources/module1.v" -incdir $SIMDIR/../sources
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$SIMDIR/../sources/top_simuverilog.v" -incdir $SIMDIR/../sources

# CORE
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./cores/xilinx/glbl.v"

# BFM
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axi4lite_mst_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE -define SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/./libraries/lib_math.v"

simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axis_etg_bfms/fidus_axis_etg_if.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axis_etg_bfms/fidus_axis_packet_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axis_etg_bfms/fidus_prbs_pkg.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axis_etg_bfms/fidus_axis_etg_pcap_pkg.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axis_etg_bfms/fidus_axis_etg_stream_pkg.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axis_etg_bfms/fidus_axis_etg_bfm.sv"

# TB
simu_vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv"

}

# TC
eval $TC_COMP_INVOCATION


# ##########################################################################################
