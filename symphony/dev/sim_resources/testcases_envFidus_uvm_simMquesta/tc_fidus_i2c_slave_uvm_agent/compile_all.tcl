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

# Slave module
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/i2c_slave/i2cSlave_define.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/i2c_slave/serialInterface.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/i2c_slave/registerInterface.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/i2c_slave/i2cSlave.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/i2c_slave/i2cSlaveTop.v"


# CORE
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./cores/xilinx/glbl.v"

# BFM
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_i2c_bfms/fidus_i2c_master_if.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_i2c_bfms/fidus_i2c_master_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axi4lite_mst_bfm.sv"
simu_vlog -sv -incr -timescale $TCTIMESCALE -define SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/./libraries/lib_math.v"


# temp if needs to check Master behaviour from Open Source
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/model/i2c_master_bit_ctrl.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/model/i2c_master_byte_ctrl.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/model/i2c_master_defines.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/model/i2c_master_top.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/model/wb_master_model.v"
simu_vlog -sv -incr -timescale $TCTIMESCALE -cover "$TCSUBDIR/model/multiByteReadWrite.v"

#UVM ENV,TB and Test in the uvm_filelist.txt
if {$::CMD_ARG_UVM > 0} {
  puts "\n\n\nCompiling UVM files.\n\n\n"
  simu_vlog -sv -incr -timescale $TCTIMESCALE -cover -f "$TCSUBDIR/uvm_filelist.txt"
}

# TB
if {$::CMD_ARG_UVM > 0} {
  simu_vlog -sv -incr -d UVM_TESTBENCH -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv"
} else {
  simu_vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv"
}

}

# TC
eval $TC_COMP_INVOCATION -incdir $TCSUBDIR/i2c_slave/


# ##########################################################################################
