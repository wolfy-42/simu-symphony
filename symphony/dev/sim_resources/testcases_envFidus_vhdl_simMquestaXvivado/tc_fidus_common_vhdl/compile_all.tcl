# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2019-02-13
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Module-wide compilation commands used by test-case
#               simulation scripts for VHDL.
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

puts stdout "==============compile_all.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################
# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {


# RTL
simu_vcom -2008 -cover "$SIMDIR/../sources/module1.vhd"
simu_vcom -2008 -cover "$SIMDIR/../sources/top_simuvhdl.vhd"

# CORE
simu_vcom -2008 "$SIMDIR/cores/xilinx/glbl.vhd"


# LIBRARIES
simu_vcom -2008 "$SIMDIR/./libraries/txt_util.vhd"
simu_vcom -2008 "$SIMDIR/./libraries/seed_pkg.vhd"
simu_vcom -2008 "$SIMDIR/./libraries/random_lib.vhd"
simu_vcom -2008 "$SIMDIR/./libraries/sim_management_vhdl.vhd"
simu_vcom -2008 "$SIMDIR/./libraries/freq_time_pkg.vhd"
simu_vcom -2008 "$SIMDIR/./libraries/lib_math.vhd"

# BFMS
simu_vcom -2008 "$SIMDIR/./bfms/fidus_clock_gen_bfm.vhd"

# TB
simu_vcom -2008 "$TCSUBDIR/global_signal_pkg.vhd"
simu_vcom -2008 "$TCSUBDIR/tb.vhd"

}

# TC
eval $TC_COMP_INVOCATION_VHDL

# ##########################################################################################
