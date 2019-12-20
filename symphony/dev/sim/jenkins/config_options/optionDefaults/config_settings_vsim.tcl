# ---------------------------------------------------------------------------//
# Copyright (C) 2006 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2006-05-12 
# ---------------------------------------------------------------------------//
# ---------------------------------------------------------------------------//
# Description   : Mentor vsim environment configuration functions and variables
#     IMPORTANT : Tool revision being tested with is listed in the build 
#                 script located in the run folder
#
# Updated       : 2018-10-10 / Dessislav Valkov - significant scripts rearanging related
# Updated       : 2019-10-24 / Dessislav Valkov - single config file concept related changes
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW WTIH SIMULATOR SPECIFIC COMMANDS
# --------------------------------------------------------------------//
# See compile_all....tcl under any testcase for example compiler options

puts stdout "==============config_settings_vsim.tcl================\n"

# default simulator is Questa/Modelsim
set ::DEFAULT_SIMULATOR vsim

##################### Library Mapping ###########################
# Must be xsim.dir for xsim. Gets reset before a new compilation.
global SIM_LIBRARY_DIRNAME
set SIM_LIBRARY_DIRNAME msim

# proc ensure_fresh_lib {}
# Purpose: Procedure which ensures a fresh library is created.
# Inputs:
#        dir_name   --> Directory where libraries are stored, has to be "xsim.dir" for xsim
#        lib_name   --> Name of the library to be created.
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

    # in questa, vlib and vmap
    vlib $dir_name/$lib_name
    vmap $lib_name $dir_name/$lib_name
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
        vmap [lindex $word_list 0] [lindex $word_list 1]
    }
}

##################### Test Case comiple ###########################
# Compile current test-case
set TC_COMP_INVOCATION {vlog -sv -incr -timescale $TCTIMESCALE $TCSUBDIR/$TCFILENAME.sv }
set TC_COMP_INVOCATION_VERILOG {vlog -incr -timescale $TCTIMESCALE $TCSUBDIR/$TCFILENAME.v }
set TC_COMP_INVOCATION_VHDL {vcom -2008 $TCSUBDIR/$TCFILENAME.vhd }

##################### Variable for extra top level unit e.g. glbl ##################
global EXTRA_UNITS
set EXTRA_UNITS ""
############################# Sim database Optimization #############################
global OPTIMIZATION_ON
global OPTIMIZATION_OFF
global OPTIMIZATION_INVOCATION

# Appended to simulation command if optimizations on or off
set OPTIMIZATION_ON "work.tb_opt"
set OPTIMIZATION_OFF "work.tb -novopt"

set OPTIMIZATION_INVOCATION "vopt +acc tb -o tb_opt"

############################# Simulator options setup #############################
global SIMULATOR_INVOCATION
global RUN_COMMAND

# Log and WLF to result_rtl
set SIMULATOR_INVOCATION {vsim -l "$TCSUBDIR/result_rtl/$TCFILENAME.log" -wlf "$TCSUBDIR/result_rtl/$TCFILENAME.wlf"}

set RUN_COMMAND "run -all"

############################# Logging / TRANSCRIPTS #############################
global LOGGING_INVOCATION

set LOGGING_INVOCATION "log -r /*"
# The _transcript file {}_ command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
proc transcript_reset {name} {
    puts stdout "==============config_settings_vsim::transcript_reset================\n"
    transcript file {}
    transcript file $name
    puts stdout "Transcript is closed and reopened"
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
set COVERAGE_ON "-coverage"
set COVERAGE_OFF ""

set COVERAGE_PARAMS ""
set COVERAGE_YES_PARAMS "+cover=bcefsx"
# Passed to vlog when not using coverage.
set COVERAGE_NO_PARAMS "-time"

# Called per testcase to save that simulation's coverage.
set COVERAGE_REPORT_INVOCATION {coverage report -file "$TCSUBDIR/result_rtl/$TCFILENAME.coverage_report.rep"}
set COVERAGE_SAVE_INVOCATION {coverage save "$TCSUBDIR/result_rtl/$TCFILENAME.cov" }

############################# Coverage Merging and Reporting #####################################
# Coverage merging and reporting functions for regression. Placed here for easy modification.
proc coverageMergeCmd {outFile inFile1 inFile2} {
    puts stdout "==============config_settings_vsim::coverageMergeCmd================\n"
    vcover merge -out $outFile $inFile1 $inFile2
    return
}
proc coverageReportCmd {outReport inCov} {
    puts stdout "==============config_settings_vsim::coverageReportCmd================\n"
    vcover report $inCov -file $outReport
    return
}

############################ View Test Case ######################################
proc view_wave_log {view_wave wave_do tcSubDir tcFileName} {
    puts stdout "==============config_settings_vsim::view_wave_log================\n"
    global REGRESSION

    if { ![info exists REGRESSION]} {
        set REGRESSION no
    }

    # If not in regression, either exit, or reopen in viewer mode
    if [string equal -nocase $REGRESSION no] {
        eval $::SIMULATOR_QUIT
        if {$view_wave == 1} {
            vsim -view $tcSubDir/result_rtl/$tcFileName.wlf

            # Waveform viewer
            if [file exists $wave_do] {
                do $wave_do
            }
        } else {

            puts stdout "Not opening waveform in simulator.\n"
       }
    }
}

############################### Quit simulation without closing entire program #########################
global SIMULATOR_QUIT
set SIMULATOR_QUIT "quit -sim"


############################# Modelsim, Don't Hang During Regression Hack #####################

# Without this, script execution halts during a regression
proc preSimCommand {tcFileName tcTimeScale} {
    puts stdout "==============config_settings_vsim::preSimCommand================\n"
    onbreak {resume}
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
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_vivado/tc_xilinx_vivado_vsim.tcl
    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_vivado/tc_xilinx_vivado_xsim.tcl
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