# --------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-11
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Default options used by run_testcase and run_regression in simu.tcl.
#               These take the place of command line arguments since vsim and tcl shells handle
#               arguments differently. Using this file instead promotes portability.
#
#               NOTE: Edits should be made to cmd_line_options_default.tcl as
#               it is copied to cmd_line_options.tcl by simu.tcl.
#
#               NOTE: If simu.tcl is not used, make edits in scripts_lib/auto_gen/cmd_line_options.tcl.
#
#               Comment Format: Simu.tcl looks for a specific comment structure
#               for printing help menus. Groups of options should be be in a line
#               that resembles "#### Header Test ####.
#               Each options needs a one line comment followed by the variable "set"
#               command on another single line. The comment should be of the form:
#               "# -arg              : Explanation text". There are exactly
#               19 characters (including whitespace) between the "#" and ":" characters.
#
# Updated       : date / author - comments
# --------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW
# --------------------------------------------------------------------//
 
puts stdout "==============config_cmd_line_options_default.tcl================\n"


#### Common Options ####
# Show color in the simulation trascript is set to 1
set ::CMD_ARG_COLOUR 1
# print debug messages in set to 1, to disable debug print set to 0
set ::CMD_ARG_DEBUGMSG 1

# -logging          : if set to 0, omits creation of waveform database WLF/WDB (vsim/xsim) or ASDB Active-HDL files. Speed-up simulation.
set ::CMD_ARG_WAVELOGGING 1

# -optimize         : if set to 1, creates optimized simulation models. Not available in xsim. Speed-up simulation.
set ::CMD_ARG_OPTIMIZE 1

# -coverage         : if set to 0, omits code coverage collection and reporting. Not available in xsim.
set ::CMD_ARG_COVERAGE 1

# -seed seedVal     : if set, sets and locks the seed to the set value for all test-cases across all modules. If blank, seed is randomly generated.
set ::CMD_ARG_SEED ""

# -simtool simTool  : Simulator vendor to:
#                     vsim - for Questa/Modelsim
#                     xsim - for Vivado
#                     xm for Cadence Xcelium
#                     ahdl_gui/ahdl_sh - for avhdl.exe Active-HDL GUI TCL or vsimsa.bat TCL shells
set ::CMD_ARG_SIMTOOL "vsim"

# Attempt to auto-detect active simulator first, tested only on xsim <> vsim autoswitch, disable for all others
set ::CMD_ARG_AUTO_SIMTOOL 0
########


#### Individual Testcase Specific ####
# -view/-view_off   : if set to 1, (enable also CMD_ARG_WAVELOGGING=1) it closes simulator and open the waveform viewer in viewer/GUI mode (questa or vivado or simvision GUI).
#                     xsim only can be set to 1.5 - Waveform viewer called in a separete window after simulation exiting, using one more vivado simulator license in viewer mode            
#                     if set to 2, it keeps the simulator open in viewer/GUI mode (questa or vivado or simvision GUI). DON"T USE THIS MODE BECUSE USES SIMULATOR LICENSE
set ::CMD_ARG_VIEW 0

# -NOTDEFINEDYET_TODO : set to 1 to run simu inside simulator vendor TCL intrepreter (simvison tcl, vsim tcl, vivado tcl, etc.)
#                       set to 0 if using on Linux TCLSH interpereter on bash terminal
#                       NOTE: vivado xsim tcl doesn't have sim tcl commands, only shell sim commands, but still this can be set to 0/1
set ::CMD_ARG_SIMVENTCL 1

# # -NOTDEFINEDYET_TODO : set to 1 to run simu on Windows (TODO: test), 0 for Linux. It will disable some linux bash commands like 'cat'/'cp'/'tee', which don't exist on Windows
# set ::CMD_ARG_WIND 0

# -compile/-compile_off     
#                   : if set to:
#                   : 0 - disables compilation of RTL libraries and test-bench. Ie. does not re-compile. Disables compiled libraryes deletion.
#                   : 1 - enables compilation of everything (RTL and test-bench) - deletes previously compiled libraries
#                   : The testcase .sv file is always compiled.
set ::CMD_ARG_COMPILE 1

# -NOTDEFINEDYET_TBD: if set to:
#                   : 0 - disables compilation of RTL. i.e. does not re-compile RTL DUT. Disables compiled library deletion. Test-bench is still compiled. Takes precedence over CMD_ARG_COMPILE
#                   : 1 - enables RTL compileation, doesn't compile test-bench, doesn't delete compiled libraries
#                   : The testcase .sv file is always compiled.
set ::CMD_ARG_RTLCOMPILE 1
########


#### Regression Specific ####
# -modname modName  : if set, runs regression on a single module directory with modName. If blank, all module are included.
set ::CMD_ARG_MODNAME ""
# -report           : if set, do not run regression, just recreate reports (regression results, and coverage).
set ::CMD_ARG_REPORT 0
########

#-use_uvm           : if set, UVM files are compiled and used in the simulation.
set ::CMD_ARG_UVM 0

