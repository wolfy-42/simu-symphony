# --------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testbench for clock and reset BFMs.
#               Intentionally fails for demonstration purposes.
#
#               Command Line Options: uses modified scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: tc_xilinx_vivado_vsim
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_xilinx_vivado_vsim
set TCSUBDIR $TESTCASESDIR_XILINX/tc_xilinx_vivado

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Vivado's 'launch_simulation -scripts_only -absolute_path' output: elaborate.do and compile.do.
# Specify the directory, and the name of the two files (they vary somewhat) below.
# Must be called WITHOUT precompiling the libraries in Vivado, otherwise the compile script
# will not compile the IP.
set vivadoSimScriptsExportDir $SIMDIR/../builds/vivado/projects/ipi_example.sim/sim_1/behav/questa
set vivadoCompileDo $vivadoSimScriptsExportDir/system_tb_compile.do
set vivadoElaborateDo $vivadoSimScriptsExportDir/system_tb_elaborate.do
# ##########################################################################################

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.

###########################################################################################
# VIVADO Questa IPI IMPORT
###########################################################################################
# Compile Vivado IPI and get libraries
# Must be after call to config_settings.tcl, this adjusts some of the invocations set there.
# Must also be after commandline argument parsing as this uses the optimization flag.
# If optimizations are used, the libraries and xil_defaultlib.glbl are passed to vopt and embedded
# in the optimized output. They are not passed again to vsim. If optimizations are not used, then
# everything is passed to vsim.
###########################################################################################
# Contains several procs.
source $TCSUBDIR/import_vivado_vsim.tcl
# Using Vivado's compile.do script, create a compile tcl script that can be called from simu.
adjust_vivado_compile_do $vivadoCompileDo $TCSUBDIR/vivado_compile.tcl
# Get a list of libraries that must be passed to vsim or vopt (eg. -L microblaze -L xil_defaultlib etc)
set lib_list [get_vivado_lib_args $vivadoElaborateDo]
# vivado has its own glbl design unit, get the design unit from Vivado's elaborate file. (typically xil_defaultlib.glbl)
set glbl_design_unit [get_vivado_glbl_design_unit $vivadoElaborateDo]

global SIMULATOR_INVOCATION
global OPTIMIZATION_INVOCATION
# Add the library arguments to either vopt or vsim depending on whether optimizations are enabled.
foreach lib $lib_list {
    if {$::CMD_ARG_OPTIMIZE > 0} {
        append OPTIMIZATION_INVOCATION " $lib"
    } else {
        append SIMULATOR_INVOCATION " $lib"
    }
}
# glbl required by vivado outputs. The glbl.v exported by Vivado is used, typically
# in the xil_defaultlib library.
if {$::CMD_ARG_OPTIMIZE > 0} {
    append OPTIMIZATION_INVOCATION " $glbl_design_unit"
} else {
    append SIMULATOR_INVOCATION " $glbl_design_unit"
}

# Required by this specific example: BRAM init file.
file copy -force $vivadoSimScriptsExportDir/base_mb_lmb_bram_0.mem ./
###########################################################################################
###########################################################################################

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE
