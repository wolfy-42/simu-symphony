# --------------------------------------------------------------------//
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : VIP Simu SystemVerilog
# Author        : Jacob von Chorus
# Created       : 2018-06-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Test bench for the Vivado IPI system.
#
#               Usage: tc_name.tcl
#               Command Line Options: Modify scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: tc_xilinx_vivado_xsim
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_xilinx_vivado_xsim
set TCSUBDIR $TESTCASESDIR_XILINX/tc_xilinx_vivado

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Vivado's 'launch_simulation -scripts_only -absolute_path' output: xsim.ini, elaborate.sh and compile.sh.
# Specify the directory, and the name of the two files (they vary somewhat) below.
# Must be called WITHOUT precompiling the libraries in Vivado, otherwise the compile script
# will not compile the IP.
set vivadoSimScriptsExportDir $SIMDIR/../builds/vivado/projects/ipi_example.sim/sim_1/behav/xsim
set vivadoXsimIni $vivadoSimScriptsExportDir/xsim.ini
set vivadoCompileSh $vivadoSimScriptsExportDir/compile.sh
set vivadoElaborateSh $vivadoSimScriptsExportDir/elaborate.sh
# ##########################################################################################

# Test case configuration
source $TCCOMMON_TCCONFIG

###########################################################################################
# VIVADO IPI IMPORT
###########################################################################################
# Compile Vivado IPI and get libraries
# Must be after call to config_settings.tcl, this adjusts some of the invocations set there.
###########################################################################################
# Contains several procs.
source $TCSUBDIR/import_vivado_xsim.tcl
# Get a list of libraries that must be passed to vsim or vopt (eg. -L microblaze -L xil_defaultlib etc)
set lib_list [get_vivado_lib_args $vivadoElaborateSh]
# Using Vivado's compile.sh script, create a compile tcl script that can be called from simu.
adjust_vivado_compile_sh $vivadoCompileSh $TCSUBDIR/vivado_compile.tcl $vivadoXsimIni
# vivado has its own glbl design unit, get the design unit from Vivado's elaborate file. (typically xil_defaultlib.glbl)
set glbl_design_unit [get_vivado_glbl_design_unit $vivadoElaborateSh]

global XELAB_INVOCATION
# Add the library arguments to xelab.
foreach lib $lib_list {
    append XELAB_INVOCATION " $lib"
}
# glbl required by vivado outputs. The glbl.v exported by Vivado is used, typically
# in the xil_defaultlib library.
append XELAB_INVOCATION " $glbl_design_unit"

# Required by this specific example: BRAM init file.
file copy -force $vivadoSimScriptsExportDir/base_mb_lmb_bram_0.mem ./
###########################################################################################
###########################################################################################

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE
