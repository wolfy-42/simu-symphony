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
vlog -sv -incr -L unisims_ver -timescale $TCTIMESCALE $::COVERAGE_PARAMS "$TCSUBDIR/axi_iic_10b_addr_slave/axi_iic_10b_addr_slave_sim_netlist.v" 

#vlib xpm
#vlib lib_pkg_v1_0_2
#vlib lib_cdc_v1_0_2
#vlib axi_lite_ipif_v3_0_4
#vlib interrupt_control_v3_1_4
#vlib axi_iic_v2_0_25
#vlib xil_defaultlib
#
#vmap xpm xpm
#vmap lib_pkg_v1_0_2 lib_pkg_v1_0_2
#vmap lib_cdc_v1_0_2 lib_cdc_v1_0_2
#vmap axi_lite_ipif_v3_0_4 axi_lite_ipif_v3_0_4
#vmap interrupt_control_v3_1_4 interrupt_control_v3_1_4
#vmap axi_iic_v2_0_25 axi_iic_v2_0_25
#vmap xil_defaultlib xil_defaultlib
#
#vlog -work xpm -64 -incr -sv \
#"/export/ssd_2019/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
#"/export/ssd_2019/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
#
#vcom -work xpm -64 -93 \
#"/export/ssd_2019/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \
#
#vcom -work lib_pkg_v1_0_2 -64 -93 \
#"$TCSUBDIR/axi_iic_10b_addr_slave/ipstatic/hdl/lib_pkg_v1_0_rfs.vhd" \
#
#vcom -work lib_cdc_v1_0_2 -64 -93 \
#"$TCSUBDIR/axi_iic_10b_addr_slave/ipstatic/hdl/lib_cdc_v1_0_rfs.vhd" \
#
#vcom -work axi_lite_ipif_v3_0_4 -64 -93 \
#"$TCSUBDIR/axi_iic_10b_addr_slave/ipstatic/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \
#
#vcom -work interrupt_control_v3_1_4 -64 -93 \
#"$TCSUBDIR/axi_iic_10b_addr_slave/ipstatic/hdl/interrupt_control_v3_1_vh_rfs.vhd" \
#
#vcom -work axi_iic_v2_0_25 -64 -93 \
#"$TCSUBDIR/axi_iic_10b_addr_slave/ipstatic/hdl/axi_iic_v2_0_vh_rfs.vhd" \
#
#vcom -work work -64 -93 \
#"$TCSUBDIR/axi_iic_10b_addr_slave/sim/axi_iic_10b_addr_slave.vhd" \




# CORE
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./cores/xilinx/glbl.v"

# BFM
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_reset_gen_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_clock_gen_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_i2c_bfms/fidus_i2c_master_if.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_i2c_bfms/fidus_i2c_master_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_axi4lite_mst_bfm.sv"
vlog -sv -incr -timescale $TCTIMESCALE +define+SEED_INITIAL_VALUE=$INITSEED "$SIMDIR/./libraries/lib_math.v"

# TB
vlog -sv -incr -timescale $TCTIMESCALE "$TCSUBDIR/tb.sv" 

}

# TC
eval $TC_COMP_INVOCATION -incdir $TCSUBDIR/i2c_slave/


# ##########################################################################################
