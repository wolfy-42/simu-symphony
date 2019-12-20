# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
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

puts stdout "==============compile_all_vsim.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################
# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {


# RTL
exec >&@stdout xvhdl -2008 "$SIMDIR/../sources/module1.vhd"
exec >&@stdout xvhdl -2008 "$SIMDIR/../sources/top_simuvhdl.vhd"

# CORE
exec >&@stdout xvhdl -2008 "$SIMDIR/cores/xilinx/glbl.vhd"


# LIBRARIES
exec >&@stdout xvhdl -2008 "$SIMDIR/./libraries/txt_util.vhd"
exec >&@stdout xvhdl -2008 "$SIMDIR/./libraries/seed_pkg.vhd"
exec >&@stdout xvhdl -2008 "$SIMDIR/./libraries/random_lib.vhd"
exec >&@stdout xvhdl -2008 "$SIMDIR/./libraries/sim_management_vhdl.vhd"
exec >&@stdout xvhdl -2008 "$SIMDIR/./libraries/freq_time_pkg.vhd"
exec >&@stdout xvhdl -2008 "$SIMDIR/./libraries/lib_math.vhd"

# BFMS
exec >&@stdout xvhdl -2008 "$SIMDIR/./bfms/fidus_clock_gen_bfm.vhd"

# TB
exec >&@stdout xvhdl -2008 "$TCSUBDIR/global_signal_pkg.vhd"
exec >&@stdout xvhdl -2008 "$TCSUBDIR/tb.vhd"

}

# TC
eval $TC_COMP_INVOCATION_VHDL

# ##########################################################################################
