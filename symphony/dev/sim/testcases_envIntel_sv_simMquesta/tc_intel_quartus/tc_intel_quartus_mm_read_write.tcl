# --------------------------------------------------------------------//
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2019-02-14
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template for intel qsys.
#
#               Command Line Options: uses modified scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: tc_intel_quartus_mm_read_write
#
#               Tested in 18.1 standard.
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_intel_quartus_mm_read_write
set TCSUBDIR $TESTCASESDIR_INTEL/tc_intel_quartus

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
append ::OPTIMIZATION_INVOCATION " -L work -L work_lib -L altera_common_sv_packages -L error_adapter_0 -L avalon_st_adapter -L rsp_mux -L cmd_mux -L cmd_demux -L pio_0_s1_burst_adapter -L router_001 -L router -L pio_0_s1_agent_rsp_fifo -L pio_0_s1_agent -L mm_master_bfm_0_m0_agent -L pio_0_s1_translator -L mm_master_bfm_0_m0_translator -L mm_interconnect_0 -L pio_0 -L mm_master_bfm_0 -L intel_avalon_example_system_inst_reset_bfm -L intel_avalon_example_system_inst_pio_0_external_connection_bfm -L intel_avalon_example_system_inst_clk_bfm -L intel_avalon_example_system_inst -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver"
append ::SIMULATOR_INVOCATION " -L work -L work_lib -L altera_common_sv_packages -L error_adapter_0 -L avalon_st_adapter -L rsp_mux -L cmd_mux -L cmd_demux -L pio_0_s1_burst_adapter -L router_001 -L router -L pio_0_s1_agent_rsp_fifo -L pio_0_s1_agent -L mm_master_bfm_0_m0_agent -L pio_0_s1_translator -L mm_master_bfm_0_m0_translator -L mm_interconnect_0 -L pio_0 -L mm_master_bfm_0 -L intel_avalon_example_system_inst_reset_bfm -L intel_avalon_example_system_inst_pio_0_external_connection_bfm -L intel_avalon_example_system_inst_clk_bfm -L intel_avalon_example_system_inst -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver"

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE