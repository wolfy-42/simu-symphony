#---------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Filename    : compile_all.tcl
# Project     : RIPL/SIMU
# Author      : Paul Roukema
# Created     : May 26, 2021
# Description : Compile script for axilite demo
#
#---------------------------------------------------------------------------//


puts stdout "==============compile_all.tcl================.\n"

# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {


# CORE
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./cores/xilinx/glbl.v"

# RTL
simu_vlog -sv -incr -cover -timescale $TCTIMESCALE "$SIMDIR/../sources/axilite_reg_if.sv"
simu_vlog -sv -incr -cover -timescale $TCTIMESCALE "$SIMDIR/../sources/demo_regs.sv"

# LIB/BFM
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/xilinx_axilite_vip_util_pkg.sv" -L xilinx_vip
simu_vlog -sv -incr -timescale $TCTIMESCALE -define SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/./libraries/lib_math.v"

# TB
simu_vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv" -L xilinx_vip
}

lappend ::EXTRA_LIBS xilinx_vip
# TC
eval $TC_COMP_INVOCATION -L xilinx_vip

# ##########################################################################################
