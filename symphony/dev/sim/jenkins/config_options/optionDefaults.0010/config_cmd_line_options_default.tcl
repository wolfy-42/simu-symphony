# --------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
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
# -logging          : if set to 0, omits creation of WLF/WDB (vsim/xsim) or ASDB Active-HDL files.
set ::CMD_ARG_LOGGING 1

# -optimize         : if set to 1, creates optimized simulation models. Not available in xsim.
set ::CMD_ARG_OPTIMIZE 0

# -coverage         : if set to 0, omits code coverage information. Not available in xsim.
set ::CMD_ARG_COVERAGE 0

# -seed seedVal     : if set, sets and locks the seed to the set value for all test-cases across all modules. If blank, seed is randomly generated.
set ::CMD_ARG_SEED ""

# -simtool simTool  : Simulator vendor to vsim - for Questa/Modelsim, xsim - for Vivado, ahdl_gui/ahdl_sh - for avhdl.exe Active-HDL GUI TCL or vsimsa.bat TCL shells. Should not be blank.
set ::CMD_ARG_SIMTOOL "ahdl_sh"
########


#### Individual Testcase Specific ####
# -view             : if set to 1, opens simulator in viewer mode (questa or vivado gui).
set ::CMD_ARG_VIEW 0

# -compile          : if set to 0, disables compilation of libraries and test-bench. Ie. does not re-compile. The testcase .sv file is still compiled.
set ::CMD_ARG_COMPILE 1
########


#### Regression Specific ####
# -modname modName  : if set, runs regression on a single module directory with modName. If blank, all module are included.
set ::CMD_ARG_MODNAME ""
# -report           : if set, do not run regression, just recreate reports (regression results, and coverage).
set ::CMD_ARG_REPORT 0
########

# force always recompile TBD
