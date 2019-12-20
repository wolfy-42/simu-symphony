# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2018-05-12
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Xilinx xsim environment configuration functions and variables
#     IMPORTANT : Tool revision being tested with is listed in the build 
#                 script located in the run folder
#
# Updated       : 2018-06-19 / Jacob von Chorus
#                   Update for new scripts. Contains configurations for a test case
#                   to be run. This must be called from a test case as it uses the testcase's
#                   directory and name.
#
# Updated       : 2019-10-24 / Dessislav Valkov - single config file concept related changes
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW WTIH SIMULATOR SPECIFIC COMMANDS
# --------------------------------------------------------------------//
# See compile_all....tcl under any testcase for example compiler options

puts stdout "==============config_settings_vsim.tcl================\n"

# default simulator is Questa/Modelsim
set ::DEFAULT_SIMULATOR xsim

# Log to result_rtl

##################### Library Mapping ###########################
# Must be xsim.dir for xsim. Gets reset before a new compilation.
global SIM_LIBRARY_DIRNAME
set SIM_LIBRARY_DIRNAME xsim.dir

# proc ensure_fresh_lib {}
# Purpose: Procedure which ensures a fresh library is created.
# Inputs:
#        dir_name   --> Directory where libraries are stored, has to be "xsim.dir" for xsim
#        lib_name   --> Name of the library to be created, but not used for xsim
# Outputs: none.
proc ensure_fresh_lib {dir_name lib_name} {
    puts stdout "==============config_settings_vsim::ensure_fresh_lib================\n"

    if [file exists $dir_name] {
        if [catch [file delete -force $dir_name] result] {
            puts stderr "Could not delete the $dir_name directory"
            puts stderr $result
        } else {
            puts stdout "deleted the $dir_name directory"
        }

    }

    file mkdir $dir_name

    puts "Successfully Created $dir_name directory\n"

    return
}

# proc map_precompiled_lib_list {}
# Purpose: Maps precompiled libraries in precompiled_lib_list.tcl.
# Inputs: none.
# Outputs: none.
proc map_precompiled_lib_list {} {
    puts stdout "==============config_settings_vsim::map_precompiled_lib_list================\n"
    source $::PRECOMPLIBLIST
    # Get library lists for each simulator and select the one required.

    # Got through each library and map it.
    foreach lib $PRECOMPILED_LIB_LIST {
        set word_list [split $lib]
        # first word is library name, second is path
        # Open xsim.ini in append mode, created if it doesn't exist.
        set fp [open xsim.ini "a"]
        # Standard xsim.ini format lib=path
        puts $fp "[lindex $word_list 0]=[lindex $word_list 1]"
        close $fp
    }
}

##################### Test Case comiple ###########################
# Compile current test-case
set TC_COMP_INVOCATION {exec >&@stdout xvlog -sv -incr "$TCSUBDIR/$TCFILENAME.sv" }
set TC_COMP_INVOCATION_VERILOG {exec >&@stdout xvlog -incr "$TCSUBDIR/$TCFILENAME.v" }
set TC_COMP_INVOCATION_VHDL {exec >&@stdout xvhdl -2008 "$TCSUBDIR/$TCFILENAME.vhd" }

##################### Variable for extra top level unit e.g. glbl ##################
global EXTRA_UNITS
set EXTRA_UNITS ""

############################# Sim database Optimization #############################
global OPTIMIZATION_ON
global OPTIMIZATION_OFF
global OPTIMIZATION_INVOCATION

# Appended to simulation command if optimizations on or off
set OPTIMIZATION_ON ""
set OPTIMIZATION_OFF ""

set OPTIMIZATION_INVOCATION ""

############################# Simulator options setup #############################
global SIMULATOR_INVOCATION
global RUN_COMMAND

# Log and WLF to result_rtl
set SIMULATOR_INVOCATION {xsim $TCFILENAME -log "$TCSUBDIR/result_rtl/$TCFILENAME.log" -wdb "$TCSUBDIR/result_rtl/$TCFILENAME.wdb" -gui }

set RUN_COMMAND "run -all"

############################# Logging / TRANSCRIPTS #############################
global LOGGING_INVOCATION

set LOGGING_INVOCATION "log_wave -r /"
# The _transcript file {}_ command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
proc transcript_reset {name} {
}


############################# Coverage options setup #############################
global COVERAGE_ON
global COVERAGE_OFF
global COVERAGE_REPORT_INVOCATION
global COVERAGE_SAVE_INVOCATION
global COVERAGE_PARAMS
global COVERAGE_YES_PARAMS
global COVERAGE_NO_PARAMS

# Appended to simulation command if optimizations on or off
set COVERAGE_ON ""
set COVERAGE_OFF ""

set COVERAGE_PARAMS ""
set COVERAGE_YES_PARAMS ""
set COVERAGE_NO_PARAMS ""

set COVERAGE_REPORT_INVOCATION ""
set COVERAGE_SAVE_INVOCATION ""

############################# Coverage Merging and Reporting #####################################
# Coverage merging and reporting functions for regression. Placed here for easy modification.
# coverage is not supported by xsim
proc coverageMergeCmd {outFile inFile1 inFile2} {

    return
}
proc coverageReportCmd {outReport inCov} {

    return
}

############################ View Test Case ######################################
proc view_wave_log {view_wave wave_do tcSubDir tcFileName} {
    global REGRESSION

    if { ![info exists REGRESSION]} {
        set REGRESSION no
    }

    # If not in regression, either exit, or reopen in viewer mode
    if [string equal -nocase $REGRESSION no] {
        eval $::SIMULATOR_QUIT
        if {$view_wave == 1} {
            # Waveform viewer
            open_wave_database $tcSubDir/result_rtl/$tcFileName.wdb
            if [file exists $wave_do] {
                open_wave_config $wave_do
            }
        } else {
            puts stdout "Not opening waveform in simulator.\n"
        }
    }
}

############################## XSim does not support coverage #################################
set CMD_ARG_COVERAGE        0


# ##########################Quit simulation without closing entire program #####################
global SIMULATOR_QUIT
set SIMULATOR_QUIT "close_vcd -quiet; close_sim -quiet"

############################# Modelsim, Don't Hang During Regression Hack #####################

############################# Xsim, Elaborate #####################
# xsim has an additional elaboration step between compilation and simulation.
global XELAB_INVOCATION
set XELAB_INVOCATION "exec >&@stdout xelab -L UNISIMS_VER -L XILINXCORELIB_VER work.tb work.glbl -debug all"
proc preSimCommand {tcFileName tcTimeScale} {
    set elab_com $::XELAB_INVOCATION
    append elab_com " -s $tcFileName -timescale $tcTimeScale"
    eval $elab_com

    return;
}

##################### Ignored testcases setup - Black-listed testcases ##################
# proc getRegressionTCIgnoreList
# Purpose: Returns a list of all testcases (tc_example.tcl) which should NOT be 
#          included in the regression. To add TCs to this ignore list,
#          append the name of the testcases tcl script using the TCL lappend command.
# Inputs :
#       testcasesDir: Points to the local testcases directory.
# Outputs: regressionTCIgnoreList
proc getRegressionTCIgnoreList {testcasesDir} {
    puts stdout "==============config_settings_general::getRegressionTCIgnoreList================\n"
    set regressionTCIgnoreList ""

    # To add directories to this ignore list, simply append the name of the directory
    # using the TCL lappend command as shown in the next line.
    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_vivado/tc_xilinx_vivado_vsim.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_vivado/tc_xilinx_vivado_xsim.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_axi/tc_xilinx_axi.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_axis/tc_xilinx_axis.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_axilite/tc_xilinx_axilite.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_INTEL/tc_intel_quartus/tc_intel_quartus_mm_read_write.tcl

    return $regressionTCIgnoreList
}

############################## External Testcase Directory List ##########################
# proc getExternalTestcaseDirs
# Purpose: Returns a list of paths to external testcase directories, containing several modules folders inside
#          These are used in regression.
#          Paths can be relative to dev/sim/run, or absolute.
proc getExternalTestcaseDirs {} {
    puts stdout "==============config_settings_general::getExternalTestcaseDirs================\n"    
    set testcaseDirList ""

    # Local testcases
    lappend testcaseDirList $::TESTCASESDIR1
    lappend testcaseDirList $::TESTCASESDIR2
    lappend testcaseDirList $::TESTCASESDIR3
#    lappend testcaseDirList $::TESTCASESDIR_XILINX
#    lappend testcaseDirList $::TESTCASESDIR_INTEL

}