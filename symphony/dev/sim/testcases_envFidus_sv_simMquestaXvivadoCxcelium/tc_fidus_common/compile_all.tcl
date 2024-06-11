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

puts stdout "==============compile_all.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################s

# When compile is specified, everything is recompiled, and libraries are deleted
if {$::CMD_ARG_COMPILE > 0} {
# when RTL compilatrion is enabled, RTL is recompiled, and libraries are deleted
if {$::CMD_ARG_RTLCOMPILE > 0} {

# RTL
puts "Compile RTL..."

# old references to call bash script generted by vivado simlation export
###eval "$EXEC_ARGS ./fpga.sh -step compile [subst $::XMCMPL_XILINXLOG]"
##eval exec "$REDIRECTSTD ./fpga.sh -step compile [subst $::XMCMPL_XILINXLOG]"

# use the line below to call the vivado simulation exported bash script
#suxil "./fpga.sh -step compile"

#xmvlog -work xcelium.d -sv -vtimescale $TCTIMESCALE "$SIMDIR/../sources/include_parameters.v" 2>&1 | tee compile.log; cat .tmp_log > xmvlog.log 2>/dev/null
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/../sources/include_parameters.v"
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $COVERAGE_PARAMS $SIMDIR/../sources/module1.v $INCDIR_OPT $SIMDIR/../sources "
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $COVERAGE_PARAMS $SIMDIR/../sources/top_simuverilog.v $INCDIR_OPT $SIMDIR/../sources "
}

# CORE
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/./cores/xilinx/glbl.v"

# BFM
puts "Compile BFM..."
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/./libraries/sim_management_pkg.sv"
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/./libraries/sim_management_verilog.v"
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $SIMDIR/./bfms/fidus_axi4lite_mst_bfm.sv"
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $DEFINE_OPT SEED_INITIAL_VALUE=$INITSEED $SIMDIR/./libraries/lib_math.v"

# TB
puts "Compile TB..."
suvlog  "-sv $TIMESCALE_OPT $TCTIMESCALE $TCSUBDIR/tb.sv"

}

# TC

# old references
###eval $TC_COMP_INVOCATION
##eval "$XMVLOG_OPTS -sv -vtimescale $TCTIMESCALE $TC_COMP_INVOCATION"
#suvlog "-sv $TIMESCALE_OPT $TCTIMESCALE [subst $TC_COMP_INVOCATION]"
puts "Compile TC..."
suvlog "-sv $TIMESCALE_OPT $TCTIMESCALE $DEFINE_OPT TCFILENAME=$TCFILENAME $TCSUBDIR/$TCFILENAME.sv"


# ##########################################################################################
