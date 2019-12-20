#!/usr/bin/env tclsh
# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-12
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : Helper script for running simu. Contains commands for simulator selection,
#               running regression, configuration command line options, etc.
#
#               Usage:
#                   From bash: ./simu.tcl
#                   From tclsh or vsim or xsim: source simu.tcl
#
#  Revisions
#  ---------
#  4.4:
#   - separated verilog and systemverilog testcases
#   - clean_simu cleans all testcase directories
#   - testcase scripts greatly simplified using resuable library code
#
#  4.5
#   - integrated vhdl into simu
#   - renamed simu directories to reflect systemverilog, verilog, and vhdl all being integrated
#   - renamed test case superlist for regression
#   - updated intel testcase to use new scripts format; tested in 18.1 standard
#   - updated xilin_vip TCs to 2018.2
#   - added start time, end time, and duration to regression superlist; added duration to regression log
#   - added create dependency script
#
# Updated       : 2019-11-14 / Des Valkov
#  4.6 
#   - integrated all configuration scripts into one called at the beginning of the TCL script
#   - renamed the testcases folders to reflect the simulation options
#   - added Active-HDL simulator support, but not part of the automated Jenkins regressions
#   - added a simulator selecting parameter to the command line options   
# 
# ----------------------------------------------------------------------//

puts stdout "==============simu.tcl================.\n"

# Determine what is running the script: vish for vsim; vivado for xsim; tclsh for tclsh
set interpreter_name    [file tail [info nameofexecutable]]
# The script name is used to open it and parse the documentation.
set SCRIPT_NAME [info script]
# Remove the config options autogen files, used to store SIMU shell related config data
if [file exists $::SIMU_SHELL_OPTIONS_AUTOGEN] {
    if [catch [file delete -force $::SIMU_SHELL_OPTIONS_AUTOGEN] result] {
        puts stderr "Could not delete the $SIMU_SHELL_OPTIONS_AUTOGEN "
        puts stderr $result
    } else {
        puts stdout "Deleted the $SIMU_SHELL_OPTIONS_AUTOGEN "
    }
}
# Command below fails in Active-hdl
set fp [open $::SIMU_SHELL_OPTIONS_AUTOGEN w]
close $fp
if [file exists $::CMD_LINE_OPTIONS_AUTOGEN] {
    if [catch [file delete -force $::CMD_LINE_OPTIONS_AUTOGEN] result] {
        puts stderr "Could not delete the $CMD_LINE_OPTIONS_AUTOGEN "
        puts stderr $result
    } else {
        puts stdout "Deleted the $CMD_LINE_OPTIONS_AUTOGEN "
    }
}
# Command below fails in Active-hdl
set fp [open $::CMD_LINE_OPTIONS_AUTOGEN w]
close $fp

################################## functions #######################################

# proc select_simulator {}
# Usage: select_simulator sim_name
#               -> Selects a simulator.
# Purpose: Selects the supplied simulator by automatically renaming the required configuration
#          scripts and setting a global variable so run_regression and run_testcase invoke the
#          right simulator.
#
# Inputs:
#       sim: Name of the simulator.
# Supported Simulators:
#       vsim
#       xsim
#       ahdl_gui - not functional from simu
#       ahdl_sh - not functional from simu
proc select_simulator {sim} {
    set SELECTED_SIMULATOR null

    if {[string equal -nocase $sim "vsim"] == 1} {
        set SELECTED_SIMULATOR vsim
        puts stdout "Selected: $sim"
    } elseif {[string equal -nocase $sim "xsim"] == 1} {
        set SELECTED_SIMULATOR xsim
        puts stdout "Selected: $sim"
    } elseif {[string equal -nocase $sim "ahdl_gui"] == 1} {
        set SELECTED_SIMULATOR ahdl_gui
        puts stdout "Selected: $sim"        
    } elseif {[string equal -nocase $sim "ahdl_sh"] == 1} {
        set SELECTED_SIMULATOR ahdl_sh
        puts stdout "Selected: $sim"        
    } else {
        puts stdout "Invalid simulator: $sim"
    }

    # store the simulator selected in a file 
    file mkdir [file dirname  $::SIMU_SHELL_OPTIONS_AUTOGEN]
    # Write cmd line option overrides if necessary to autogen.
    set fp [open $::SIMU_SHELL_OPTIONS_AUTOGEN w]
    puts $fp "set ::CMD_ARG_SIMTOOL \"$SELECTED_SIMULATOR\""
    close $fp

    puts stdout "==============simu::_set_sim_args Sourcing SIMU shell options from autogen==============\n"
    source $::SIMU_SHELL_OPTIONS_AUTOGEN
    set ::DEFAULT_SIMULATOR $::CMD_ARG_SIMTOOL

}

# proc run_testcase {}
# Usage: run_testcase ../testcases/tc_case/tc_case.tcl -arg -arg -arg
#               -> Run the supplied testcase with zero or more arguments.
# Purpose: Invokes the selected simulator with the supplied testcase. Arguments passed to this command
#          are parsed and scripts_lib/auto_gen/cmd_line_options.tcl is modified accordingly. If the testcase
#          is invalid, or no simulator is selected/detected, then this function prints an error.
# Underlying Call: vsim -c -do ../testcases/tc_case/tc_cast.tcl
#                  vivado -mode batch -source ../testcases/tc_case/tc_case.tcl
#
# Inputs:
#       testcase:   Path, relative to run/, to the testcase tcl script.
#       args:       Arbritray length list of options to be passed to the testcase via cmd_line_arguments.tcl.
# Supported Arguments:
#       -logging/-logging_off:    Disable waveform logging from the simulator.
#       -optimize/-optimize_off:  Enable optimizations.
#       -coverage/-coverage_off:  Enable coverage collection.
#       -view/-view_off:          Open the simulator in viewer mode. Must be executed from a GUI context.
#       -compile/-compile_off:    Only compile the testcase .sv file. Do not compile RTL, libraries, BFMs, etc.
#       -seed <seed>:             Select a seed for random number generation.
#       -simtool <name>:          The tool name can be vsim, xsim, ahdl_gui, ahdl_sh (ahdl_...  - not functional from simu)
#       -notrace_off:             Vivado specific, run Vivado xsim with notrace enabled (default) - results in a clean report. Otherwise xsim echoes every script line.
#
#       If no command line options are passed, scripts_config/config_cmd_line_options_defaults.tcl is
#       copied to cmd_line_options.tcl.
proc run_testcase {testcase args} {
    puts stdout "==============simu::run_testcase==============\n"

    set validForm [regexp {tc.*\/tc.*\.tcl$} $testcase]
    set exists [file exists $testcase]

    if {$validForm == 0 || $exists == 0} {
        puts stdout "Invalid testcase: $testcase"
        return
    }

    _set_sim_args $args

    # "set" commands to pass to simulator
    set variable_list_vsim  "set IN_SIMU_ENVIRONMENT 0;set DEFAULT_SIMULATOR $::DEFAULT_SIMULATOR"

    # If already in a simulation environment, use "source",
    # otherwise a selected simulation environment has to be brought up.
    if {$::DEFAULT_SIMULATOR eq "vsim"} {
        if {[regexp {\-view} $args] } {
            exec >&@stdout vsim -do "$variable_list_vsim;do $testcase"
        } else {
            exec >&@stdout vsim -c -do "$variable_list_vsim;do $testcase;quit"
        }
            #set wlfName "[file dirname $testcase]/result_rtl/[file tail [file rootname $testcase]].wlf"
            #exec >&@stdout vsim -view $wlfName
    } elseif {$::DEFAULT_SIMULATOR eq "ahdl_gui" || $::DEFAULT_SIMULATOR eq "ahdl_sh"} {
        if {[regexp {\-view} $args] } {
            exec >&@stdout vsim -do "$variable_list_vsim;do $testcase"
        } else {
            exec >&@stdout vsim -c -do "$variable_list_vsim;do $testcase;quit"
        }    
    } elseif {$::DEFAULT_SIMULATOR eq "xsim"} {
        if {[regexp {\-view} $args] } {
            if {[regexp {\-notrace_off} $args] } {
                exec >&@stdout vivado -mode gui -source $testcase -tclargs IN_SIMU_ENVIRONMENT $::DEFAULT_SIMULATOR                
            } else {
                exec >&@stdout vivado -notrace -mode gui -source $testcase -tclargs IN_SIMU_ENVIRONMENT $::DEFAULT_SIMULATOR
            }
        } else {
            if {[regexp {\-notrace_off} $args] } {
                exec >&@stdout vivado -mode batch -source $testcase -tclargs IN_SIMU_ENVIRONMENT $::DEFAULT_SIMULATOR                
            } else {
                exec >&@stdout vivado -notrace -mode batch -source $testcase -tclargs IN_SIMU_ENVIRONMENT $::DEFAULT_SIMULATOR
            }
        }
    } else {
        puts stdout "No simulator selected, run \"select_sumulator\"."
    }
}

# proc run_regression {}
# Usage: run_regression -arg -arg -arg
#               -> Run regression with zero or more arguments.
# Purpose: Invokes a regression test with the selected simulator. Arguments passed to this command
#          are parsed and scripts_lib/auto_gen/cmd_line_options.tcl is modified accordingly. Regression
#          results are compiled into regression_results/ after all testcases complete. A copy of the
#          results is placed in a timestamped directory in regression_results/results_archive/.
# Underlying Call: vsim -c -do ../scripts_config/run_regression.tcl
#                  vivado -mode batch -source ../scripts_config/run_regression.tcl
#
# Inputs:
#       args: Arbritray length list of options to be passed to the regression via cmd_line_arguments.tcl.
# Supported Arguments:
#       -logging/-logging_off:    Disable waveform logging from the simulator.
#       -optimize/-optmize_off:   Enable optimizations.
#       -coverage/-coverage_off:  Enable coverage collection.
#       -modname <module_name>:   Only execute testcases from a single module directory (eg. tc_common/).
#       -simtool <name>:          The tool name can be vsim, xsim, ahdl_gui, ahdl_sh (ahdl_...  - not functional from simu)
#       -seed <seed>:             Select a seed for random number generation.
#       -repot/-report_off:       When set it doesn't run regression but only regenerates the reports (regression results and coverage)
#       -notrace_off:             Vivado specific, run Vivado xsim with notrace enabled (default) - results in a clean report. Otherwise xsim echoes every script line.
#
#       If no command line options are passed, scripts_config/config_cmd_line_options_defaults.tcl is
#       copied to cmd_line_options.tcl.
proc run_regression {args} {
    puts stdout "==============simu::run_regression==============\n"

    set regression_script $::SCRPTCFGDIR/run_regression.tcl
    _set_sim_args $args

    # "set" commands to pass to simulator
    set variable_list  "set IN_SIMU_ENVIRONMENT 0;set DEFAULT_SIMULATOR $::DEFAULT_SIMULATOR"

    # If already in a simulation environment, use "source",
    # otherwise a selected simulation environment has to be brought up.
    if {$::DEFAULT_SIMULATOR eq "vsim"} {
        exec >&@stdout vsim -c -do "$variable_list;do $regression_script;quit"
    } elseif {$::DEFAULT_SIMULATOR eq "ahdl_gui" || $::DEFAULT_SIMULATOR eq "ahdl_sh"} {
        exec >&@stdout vsim -c -do "$variable_list;do $regression_script;quit"
    } elseif {$::DEFAULT_SIMULATOR eq "xsim"} {
        if {[regexp {\-notrace_off} $args] } {
            exec >&@stdout vivado -mode batch -source $regression_script -tclargs IN_SIMU_ENVIRONMENT $::DEFAULT_SIMULATOR
        } else {
            exec >&@stdout vivado -notrace -mode batch -source $regression_script -tclargs IN_SIMU_ENVIRONMENT $::DEFAULT_SIMULATOR
        }
    } else {
        puts stdout "No simulator selected, run \"select_sumulator\"."
    }
}

# proc regression_results_print {}
# Usage: regression_results_print
#               -> Reread and print the latest regression results if they exist.
# Purpose: Prints the pass/fail list normally output at the end of regression.
proc regression_results_print {} {
    if [catch {open $::REGRESSION_RESULTS_DIR/regression_results_all.log r} fp] {
        puts stdout "No regression results to display."
        return
    }

    set results [read $fp]
    close $fp

    puts stdout $results
}

# proc regression_results_parse {}
# Usage: regression_results_parse
#               -> Recreates the regression pass/fail summary.
# Purpose: Reparses all log files in result_rtl to recreate the pass/fail
#          summary that can be printed with regression_results_print.
#
# Output File: regression_results_all.log
proc regression_results_parse {} {
    run_regression -report -notrace
}

# proc regression_coverage_print {}
# Usage: regression_coverage_print
#               -> Print the merged coverage report if it exists.
# Purpose: Prints the merged coverage report produce during regression
#          or by regression_coverage_print.
proc regression_coverage_print {} {
    if [catch {open $::REGRESSION_RESULTS_DIR/regression_coverage_all.cov.rep r} fp] {
        puts stdout "No regression results to display."
        return
    }

    set results [read $fp]
    close $fp

    puts stdout $results
}

# proc regression_coverage_parse {}
# Usage: regression_coverage_parse
#               -> Remerges regression coverage.
# Purpose: Remerges coverage.
# Output Files: regression_coverage_all.cov     -> vsim "vcover" format.
#               regression_coverage_all.cov.rep -> Human readable text report.
proc regression_coverage_parse {} {
    run_regression -report -coverage -notrace
}

# proc config_print {}
# Usage: config_print
#               -> Prints the default command line arguments passed to testcases and regression.
# Purpose: Prints the default command line arguments passed to testcases and regression.
proc config_print {} {
    set fp [open $::SCRPTCFGDIR/$::CMD_LINE_OPTIONS_DEFAULT r]

    # Don't start search for "# -" until the script has detected the first header.
    set begun 0
    while {[gets $fp line] >= 0} {
        # Detect command group headers (eg. #### Common Options).
        if {[regexp {^####\s} $line]} {
            puts stdout "\n$line"
            set begun 1
        }
        if {$begun} {
            # Detect command option comments (eg. "# -arg")
            if [regexp {^#\s\-} $line] {
                puts stdout [regsub {^#\s} $line {}]
                gets $fp line
                # Get value variable is set to
                puts stdout "           Default: [regexp -inline {\S*$} $line]"
            }
        }
    }
}

# proc compile_xilinx_libs {args}
# Usage: compile_xilinx_libs
#               -> Compile Xilinx Unisim libraries for Xilinx IP simulation.
# Purpose: Compiles the Xilinx Unisim simulation libraries. Required before executing any vsim vivado testcases.
#          xsim vivado uses libraries from Vivado's install so nothing needs to be compiled.
#          Only needs to be executed once, or when run/xsimlib is deleted.
# Inputs: the input takes a variable list of arguments, passing no arguments is acceptable
#       - ip: If passed, all ip are compiled, otherwise just the unisim libraries are compiled.
#       - path=<path name>: Specify the output path. If not passed, the default is ./xsimlib.
#
proc compile_xilinx_libs {args} {
    exec >&@stdout vivado -mode batch -notrace -source $::SCRPTLIBDIR/compile_xilinx_libs.tcl -tclargs $args
}

# proc vivado_get_lib_args {}
# Usage: vivado_get_lib_args elaborate.do import_script
#               -> Parses elaborate.do (vsim) or elaborate.sh (xsim) and prints the required libraries.
# Purpose: Running "launch_simulation -scripts_only -absolute_path" in Vivado
#          produces simualation scripts for either vsim or xsim. This procedure
#          extracts "-L lib_name" arguments from the elaborate script and prints
#          the list.
#          Note: vsim simulation scripts contain an elaborate.sh script, ignore it.
#
# Inputs:
#       elaborate_script_path: Pass the path to the script generated by Vivado that resembles
#                           "elaborate.do" for vsim, or "elaborate.sh" for xsim.
#       import_script: Path to testbench specific import_vivado.tcl conversion script
proc vivado_get_lib_args {elaborate_script_path import_script} {
    if {$::DEFAULT_SIMULATOR eq "vsim"} {
        source $::SCRPTLIBDIR/utils.tcl
        source $import_script
        set lib_list [get_vivado_lib_args $elaborate_do_path]
        puts stdout $lib_list

    } elseif {$::DEFAULT_SIMULATOR eq "xsim"} {
        source $::SCRPTLIBDIR/utils.tcl
        source $import_script
        set lib_list [get_vivado_lib_args $elaborate_do_path]
        puts stdout $lib_list
    } else {
        puts stdout "No simulator selected, run \"select_sumulator\"."
    }
}

# proc vivado_vsim_adjust_compile_do
# Usage: vivado_vsim_adjust_compile_do compile_do_path comp_script_out import_script
#               -> Parse compile.do and create a compilation script for a testbench.
# Purpose: Copies Vivado generated compile.do script to a local file and modifies it to
#          work with a testbench.
#          The modifications remove creation of msim and work, simu handles these.
#          They also remove the absolute paths from the library locations in vmap,
#          and replace with msim/<library>.
#          Note: This is a vsim only function, xsim has a different version.
# Inputs:
#       compile_do_path: Path to compile.do file produced by Vivado.
#       comp_script_out: Location where adjusted output script will be saved.
#       import_script: Path to testbench specific import_vivado.tcl conversion script
proc vivado_vsim_adjust_compile_do {compile_do_path comp_script_out import_script} {
    if {$::DEFAULT_SIMULATOR eq "vsim"} {
        source $::SCRPTLIBDIR/utils.tcl
        source $import_script

        # Normally supplied by the testcases.
        global sim_library_dirname
        set sim_library_dirname msim
        adjust_vivado_compile_do $compile_do_path $comp_script_out

    } else {
        puts stdout "vsim not selected, run \"select_sumulator\"."
    }
}

# proc vivado_xsim_adjust_compile_sh
# Usage: vivado_xsim_adjust_compile_sh compile_sh_path comp_script_out  vivado_xsim_ini import_script
#               -> Parse compile.sh and create a compilation script for a testbench.
# Purpose: Copies Vivado's compile.sh script to a local file and modifies it to
#          work with a testbench. Copies xsim.ini to the cwd (run/), and the .prj
#          files (parsed from compile.sh) to the same directory as comp_script_out.
#          Note: This is an xsim only function, vsim has a different version.
# Inputs:
#       compile_sh_path: Path to compile.sh file produced by Vivado.
#       comp_script_out: Location where adjusted output script will be saved.
#       vivado_xsim_ini: Location of xsim.ini which must be copied to run/ folder.
#       import_script: Path to tesbench specific import_vivado.tcl conversion script
proc vivado_xsim_adjust_compile_sh {compile_sh_path comp_script_out vivado_xsim_ini import_script}  {
    if {$::DEFAULT_SIMULATOR eq "xsim"} {
        source $::SCRPTLIBDIR/utils.tcl
        source $import_script
        adjust_vivado_compile_sh $compile_sh_path $comp_script_out $vivado_xsim_ini

    } else {
        puts stdout "xsim not selected, run \"select_sumulator\"."
    }
}

# proc vivado_get_glbl_design_unit {}
# Usage: vivado_get_glbl_design_unit elaborate.do import_script
#               -> Parses elaborate.do (vsim) or elaborate.sh (xsim) and prints the name of the glbl design unit.
# Purpose: Running "launch_simulation -scripts_only -absolute_path" in Vivado
#          produces simualation scripts for either vsim or xsim. This procedure returns
#          the name (lib.glbl) of the glbl design unit that must be passed to xsim, vsim, or vopt.
#          Note: vsim simulation scripts contain an elaborate.sh script, ignore it.
#
# Inputs:
#       elaborate_script_path: Pass the path to the script that resembles
#                           "elaborate.do" for vsim, or "elaborate.sh" for xsim.
#       import_script: Path to tesbench specific import_vivado.tcl conversion script
proc vivado_get_glbl_design_unit {elaborate_script_path import_script} {
    if {$::DEFAULT_SIMULATOR eq "vsim"} {
        source $::SCRPTLIBDIR/utils.tcl
        source $import_script
        set glbl_name [get_vivado_glbl_design_unit $elaborate_do_path]
        puts stdout $glbl_name

    } elseif {$::DEFAULT_SIMULATOR eq "xsim"} {
        source $::SCRPTLIBDIR/utils.tcl
        source $import_script
        set glbl_name [get_vivado_glbl_design_unit $elaborate_do_path]
        puts stdout $glbl_name
    } else {
        puts stdout "No simulator selected, run \"select_sumulator\"."
    }
}


# proc clean_simu {}
# Usage: clean_simu
#               -> Deletes simulation files.
# Purpose: Deletes files created during simulations and simulation results.
proc clean_simu {} {
    # __fake_file is a non-existant file that prevents "file delete" from complaining
    # if [glob] return an empty string. Otherwise "file delete" complains of not enough arguments.
    # It ignores __fake_file.
    # Get list of testcase directories and delete their result directories.
    set test_case_dir_list [getExternalTestcaseDirs]
    foreach test_case_dir $test_case_dir_list {
        file delete -force __fake_file {*}[glob -nocomplain -join -dir $test_case_dir * result_rtl]
    }

    file delete -force __fake_file {*}[glob -nocomplain -dir ../regression_results reg*]
    file delete -force __fake_file {*}[glob -nocomplain -dir ../regression_results _reg*]
    file delete -force __fake_file {*}[glob -nocomplain -dir ../regression_results REG*]
    file delete -force __fake_file {*}[glob -nocomplain -dir ../regression_results/results_archive reg*]

    file delete -force -- __fake_file msim
    file delete -force -- __fake_file xsim.dir
    file delete -force -- __fake_file xsim.ini
    file delete -force -- __fake_file .Xil
    file delete -force -- __fake_file compile_simlib.log
    file delete -force -- __fake_file SIM_REPORT.LOG
    file delete -force __fake_file {*}[glob -nocomplain .cxl*]
    file delete -force __fake_file {*}[glob -nocomplain _run*]
    file delete -force __fake_file {*}[glob -nocomplain -dir .. _run*]

    file delete -force __fake_file {*}[glob -nocomplain vivado*]
    file delete -force __fake_file {*}[glob -nocomplain webtalk*]
    file delete -force __fake_file {*}[glob -nocomplain transcript*]
    file delete -force __fake_file {*}[glob -nocomplain xelab*]
    file delete -force __fake_file {*}[glob -nocomplain xvlog*]
    file delete -force __fake_file {*}[glob -nocomplain xvhdl*]
}

# proc _set_sim_args {}
# Usage: _set_sim_args -arg -arg -arg
#               -> Called by other functions.
# Purpose: Helper function used by run_testcase and run_regression to parse command line arguments
#          and modify scripts_lib/auto_gen/cmd_line_options.tcl appropiately.
#
# Inputs:
#       args: Arbritrary length list of arguments passed on the commmand line.
proc _set_sim_args {args} {
    file mkdir [file dirname  $::CMD_LINE_OPTIONS_AUTOGEN]
    # Write cmd line option overrides if necessary to autogen.
    set fp [open $::CMD_LINE_OPTIONS_AUTOGEN w]

    if {[regexp {\-logging} $args] } {
        puts $fp {set ::CMD_ARG_LOGGING 1}
    } 
    if {[regexp {\-logging_off} $args] } {
        puts $fp {set ::CMD_ARG_LOGGING 0}
    }

    if {[regexp {\-optimize} $args] } {
        puts $fp {set ::CMD_ARG_OPTIMIZE 1}
    } 
    if {[regexp {\-optimize_off} $args] } {
        puts $fp {set ::CMD_ARG_OPTIMIZE 0}
    } 

    if {[regexp {\-coverage} $args] } {
        puts $fp {set ::CMD_ARG_COVERAGE 1}
    } 
    if {[regexp {\-coverage_off} $args] } {
        puts $fp {set ::CMD_ARG_COVERAGE 0}
    } 

    if {[regexp {\-view} $args] } {
        puts $fp {set ::CMD_ARG_VIEW 1}
    } 
    if {[regexp {\-view_off} $args] } {
        puts $fp {set ::CMD_ARG_VIEW 0}
    } 

    if {[regexp {\-compile} $args] } {
        puts $fp {set ::CMD_ARG_COMPILE 1}
    }
    if {[regexp {\-compile_off} $args] } {
        puts $fp {set ::CMD_ARG_COMPILE 0}
    }

    if {[regexp {\-modname\s\S*} $args] } {
        set modName [regexp -inline \\-modname\\s\\w* $args]
        set modName [regsub \\-modname\\s $modName ""]
        set modName [string trim $modName "{}"]
        puts $fp "set ::CMD_ARG_MODNAME \"$modName\""
    }   

    if {[regexp {\-simtool\s\S*} $args] } {
        set simTool [regexp -inline \\-simtool\\s\\w* $args]
        set simTool [regsub \\-simtool\\s $simTool ""]
        set simTool [string trim $simTool "{}"]
        puts $fp "set ::CMD_ARG_SIMTOOL \"$simTool\""
    } 

    if {[regexp {\-seed\s\S*} $args] } {
        set seedVal [regexp -inline \\-seed\\s\\d* $args]
        set seedVal [regsub \\-seed\\s $seedVal ""]
        set seedVal [string trim $seedVal "{}"]
        puts $fp "set ::CMD_ARG_SEED \"$seedVal\""
    } 

    if {[regexp {\-report} $args] } {
        puts $fp {set ::CMD_ARG_REPORT 1}
    } 
    if {[regexp {\-report_off} $args] } {
        puts $fp {set ::CMD_ARG_REPORT 0}
    }

    close $fp

    # updating the simtool option because is used in simu
    # the rest of the options are only relevant during TC execution
    puts stdout "==============simu::_set_sim_args Sourcing SIMU CMD LINE options from just written autogen==============\n"
    source $::CMD_LINE_OPTIONS_AUTOGEN
    # also update the simu shell function select_simulator
    if { [info exists simTool] } {
        puts "The simulator is selected in SIMU by a command-line option."
        select_simulator $::CMD_ARG_SIMTOOL
    } 
    puts stdout "Simulator selection is $::DEFAULT_SIMULATOR\n"    

}


####### Documentation Related Functions #######
# proc _simu_cmd_summary {}
# Usage: _simu_cmd_summary
#               -> Called during script's initial run.
# Purpose: Prints a list of commands with a brief description.
proc _simu_cmd_summary {} {
    puts stdout "\n###### Simu Command Summary: ######\n"
    set fp [open $::SCRIPT_NAME r]

    while {[gets $fp line] >= 0} {
        if {[regexp {Usage\:\s\w*} $line]} {
            set cmdName [regsub {#\sUsage\:\s} $line ""]
            if {[regexp {^_} $cmdName]} {
                continue
            }
            puts stdout $cmdName
            gets $fp line
            puts stdout "[string map {# ""} $line]\n"
        }
    }
    close $fp
    puts stdout ""
}

# proc help_simu {}
# Usage: help_simu
#               -> Prints a detailed help message.
# Purpose: Prints a detailed description of all simu commands in this script.
proc help_simu {} {
    puts stdout "\n######################## SIMU COMMAND DESCRIPTIONS: ########################\n"
    set fp [open $::SCRIPT_NAME r]

    while {[gets $fp line] >= 0} {
        if {[regexp {\#\sproc\s} $line]} {
            set description [regsub {\#\sproc\s} $line ""]
            if {[regexp {^_} $description]} {
                continue
            }
            set description [regsub {\s\S*$} $description ""]
            set description "############ $description ############\n"
            while {[gets $fp desc_line] >= 0} {
                if {[regexp {^proc\s} $desc_line]} {
                    break
                }
                append description "[string map {# ""} $desc_line]\n"
            }
            puts -nonewline stdout $description
            puts stdout "##############################\n"
        }
    }
    close $fp
    puts stdout ""

    set multithread_msg "############ MULTI-THREADED EXECUTION: ############\
                        \nMultiple instances of regression can be run concurrently by executing run_regression in separate terminal instances.\
                        \nThe scripts handle reserving and executing testcases from a superlist. The regression script copies its run directory\
                        \nto a temporary unique directory so that simulation libraries from each simulator instance do not collide. These directories\
                        \nare prefixed with _run and are cleaned up at the end of regression.\
                        \n##############################\n"
    puts stdout $multithread_msg

    set vivado_msg "############ Xilinx vivado Import: ############\
                \nVivado can output simulation scripts for vsim or xsim using: launch_simulation -scripts_only -absolute_path\
                \nThis must be run WITHOUT precompiling the simulation libraries from within Vivado, otherwise \"launch_simulation...\"\
                \ndoes not produce compilations commands for the IP required. Unisim is precompiled under simu using\
                \n./scripts_lib/compile_xilinx_libs.tcl. See that file for details.\
                \n##############################\n"
    puts stdout $vivado_msg

    set underlying_call "############ Underlying Simu Calls: ############\
                        \nrun_testcase:\
                        \n      vsim -c -do ../testcases/tc_case/tc_cast.tcl\
                        \n      vivado -mode batch -source ../testcases/tc_case/tc_case.tcl\
                        \nrun_regression:\
                        \n      vsim -c -do ../scripts_lib/run_regression.tcl\
                        \n      vivado -mode batch -source ../scripts_lib/run_regression.tcl\
                        \n##############################\n"
    puts stdout $underlying_call

    _simu_cmd_summary
}


## Automation - if inside a simulator's TCL shell, select that simulator.
#if {$interpreter_name eq "vish"} {
#    select_simulator vsim
#    puts "Selected vsim becuse in vish"
#}
#if {$interpreter_name eq "vivado"} {
#    select_simulator xsim
#    puts "Selected xsim becuse in Vivado"
#} 

# Run usage summary
help_simu

puts stdout "SIMU Revision: 4.6"

## Start an interactive readline session. This provides a nicer command line
## interface than tclsh: recalling history, command completion, path completion, etc.
## It is commented out TBD becuse it crashed the console when pressing ctrl-C 
proc simu_shell {} {
    source $::SCRPTLIBDIR/tclreadline2.tcl
    package require TclReadLine
    TclReadLine::interact
}

# alternative lite shell
proc simu_shell2 {} {
if {![info exists tcl_prompt1]} {
    set tcl_prompt1 {puts -nonewline "% ";flush stdout}
}
if {![info exists tcl_prompt2]} {
    # Note that tclsh actually defaults to not printing anything for this prompt
    set tcl_prompt2 {puts -nonewline "> ";flush stdout}
}

set script ""
set prompt $tcl_prompt1    
while {![eof stdin]} {
    eval $prompt;                        # Print the prompt by running its script
    if {[gets stdin line] >= 0} {
        append script $line "\n";        # The newline is important
        if {[info complete $script]} {   # Magic! Parse for syntactic completeness
            if {[catch $script msg]} {   # Evaluates the script and catches the result
                puts stderr $msg
            } elseif {$msg ne ""} {      # Don't print empty results
                puts stdout $msg
            }
            # Accumulate the next command
            set script ""
            set prompt $tcl_prompt1
        } else {
            # We have a continuation line
            set prompt $tcl_prompt2
        }
    }

    #proc enableRaw {{channel stdin}} {
    #  exec /bin/stty raw -echo <@$channel
    #}
    #proc disableRaw {{channel stdin}} {
    #  exec /bin/stty -raw echo <@$channel
    #}
    #
    ## using ESC instead of CTRL-C
    #enableRaw
    #set c [scan [read stdin 1] %c]
    #disableRaw
    #if {$c == 27} { break }
}
}
