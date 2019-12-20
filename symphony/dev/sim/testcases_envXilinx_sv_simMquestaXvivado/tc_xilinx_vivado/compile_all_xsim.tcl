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


# >&@stdout: tells xsim to print output to the console, otherwise errors are not printed.
# CORE
exec >&@stdout xvlog -sv -incr "$SIMDIR/cores/xilinx/glbl.v"

# BFM
exec >&@stdout xvlog -sv -incr "$SIMDIR/libraries/sim_management_pkg.sv"
exec >&@stdout xvlog -sv -incr "$SIMDIR/libraries/sim_management_verilog.v"
exec >&@stdout xvlog -sv -incr "$SIMDIR/bfms/fidus_reset_gen_bfm.sv"
exec >&@stdout xvlog -sv -incr "$SIMDIR/bfms/fidus_clock_gen_bfm.sv"
exec >&@stdout xvlog -sv -incr -d SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/libraries/lib_math.v"

# TB
exec >&@stdout xvlog -sv -incr "$TCSUBDIR/tb.sv"

# Uart rcvr wrapper; modified for sim_management_pkg.
exec >&@stdout xvlog -work xil_defaultlib -L work -sv -incr "$SIMDIR/../builds/source/uart_rcvr_wrapper.sv"

# Local copy of Vivado's compile.do script after being modified to suit simu.
source $TCSUBDIR/vivado_compile.tcl

}

# TC
eval $TC_COMP_INVOCATION

# ##########################################################################################
