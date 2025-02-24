# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-13
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : Readme
#
# Updated       : date / author - comments
# -----------------------------------------------------------------------//

Simu uses several scripts for settings: config_settings_*.tcl and config_cmd_line_options_default.tcl

The settings files are stored per-simulator as config_settings_{v/x}sim.tcl. Depending on the chosen simulator, the appropiate scripts are copied to scripts_lib/auto_gen and sourced by the rest of simu. simu.tcl under run/ handles copying the settings files with the select_simulator command.

1. config_settings_*.tcl contains the simulator invocation, optimization invocation, coverage, etc.
This script is sourced by each testcase as it requires the testcase name and subdirectory. They contains the location of scripts_lib and the testcase folders. They contains the testcases directory list, and the testcase ignore list for regression. It also contains some procs specific to running regression. This script is sourced by run_regression.tcl and by each
testcase. 

2. config_cmd_line_options_default.tcl contains the default command line options passed to testcases and
regression. It is copied to cmd_line_options.tcl before it is modified by simu.tcl with additional
command line options passed there.
The cmd_line_options.tcl script is sourced by run_regression.tcl and by each testcase. 

Simulator Selection:
    Each of config_settings and regression_settings comes in (currently) two flavours: vsim and xsim. To select a simulator rename (copy) the appropiate
    scripts to config_settings.tcl and regression_settings.tcl.
    eg) config_settings_vsim.tcl -> config_settings.tcl
        regression_settings_vsim.tcl -> config_settings.tcl

    run/simu.tcl handles file renaming with the select_simulator procedure.

Modifying Settings:
    Modify the simulator specific scripts: config_settings_vsim.tcl, regression_settings_xsim.tcl, etc.
    config_settings.tcl and regression_settings.tcl are created by renaming their simulator specific versions.

Compile Scripts:
    Each testcase directory contains a compile_all_<simulator>.tcl script. These must be written for the appropiate simulators (vsim and xsim at this time).
    The appropiate compile script is automatically selected and sourced based on the chosen config_settings. Ie. do not rename the compile scripts to compile_all.tcl.
    The selelection is done in each testcase script. Adding simulators would require extending this selection statement.

Command Line Options:
    Arguments are passed to testcase .tcl scripts and run_regression.tcl through cmd_line_options.tcl. See the file for available options. When simu.tcl
    is used, command line arguments passed to run_regression and run_testcase are parsed and cmd_line_options.tcl is modified accordingly. If no command
    line options are passed to run_testcase or run_regression, simu.tcl copies cmd_line_options_default.tcl to cmd_line_options.tcl. The desired default
    testcase/regression options can be set in this file.


