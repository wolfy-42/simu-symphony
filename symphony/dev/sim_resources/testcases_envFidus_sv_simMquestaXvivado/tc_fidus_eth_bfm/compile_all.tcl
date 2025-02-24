#===================================================================
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Filename : compile_all.tcl
#
# Project : Ethernet BFM
# Author : Bryan Piotto
# Created : 15/05/2023
#
# Description : Ethernet BFM testbench compilation file for simu.
#
#===================================================================

puts stdout "==============compile_all.tcl================.\n"

# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {

# Libraries
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_pkg.sv"
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./libraries/sim_management_verilog.v"

# BFMs
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_eth_bfms/receiver/rtl/eth_bfm_axi_pkg.sv"
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_eth_bfms/receiver/rtl/eth_bfm_if.sv"
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_eth_bfms/receiver/rtl/eth_base_pkg.sv"
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_eth_bfms/receiver/env/packet_bfm_env_pkg.sv"
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_eth_bfms/receiver/rtl/eth_bfm.sv"
simu_vlog -sv -timescale $TCTIMESCALE "$SIMDIR/./bfms/fidus_eth_bfms/generator/env/packet_tb_env_pkg.sv"

# TB
simu_vlog -sv -timescale $TCTIMESCALE -define SEED_INITIAL_VALUE=$INITSEED "$TCSUBDIR/tb.sv"


}

# TC
eval $TC_COMP_INVOCATION


# ##########################################################################################
