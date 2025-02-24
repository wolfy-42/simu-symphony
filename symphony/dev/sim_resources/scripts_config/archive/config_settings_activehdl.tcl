# ---------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-09-06
# ---------------------------------------------------------------------------//
# ---------------------------------------------------------------------------//
# Description   : Active-HDL vsim environment configuration functions and variables
#     IMPORTANT : Tool revision being tested with is listed in the build
#                 script located in the run folder
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW WTIH SIMULATOR SPECIFIC COMMANDS
# --------------------------------------------------------------------//
# See compile_all....tcl under any testcase for example compiler options

puts stdout "==============config_settings_activehdl.tcl================\n"

# default simulator is Active-HDL only on Windows
set ::DEFAULT_SIMULATOR ahdl_sh

##################### Library Mapping ###########################
# Gets reset before a new compilation.
global SIM_LIBRARY_DIRNAME
set SIM_LIBRARY_DIRNAME asim

# proc ensure_fresh_lib {}
# Purpose: Procedure which ensures a fresh library is created.
# Inputs:
#        dirName --> Directory where libraries are stored, has to be "xsim.dir" for xsim
#        name   --> Name of the library to be created.
# Outputs: none.
proc ensure_fresh_lib {dir_name name} {
    puts stdout "==============config_settings_activehdl::ensure_fresh_lib================\n"

    # When in Active-HDL GUI environment
    if {[string equal $::CMD_ARG_SIMTOOL ahdl_gui]} {
        if [file exists $dir_name.aws] {

            if [catch [workspace close] result] {
                puts stderr "Workspace was not oppen"
            }

            if [catch [file delete -force $dir_name.aws] result] {
                puts stderr "Could not delete the $dir_name.aws file"
                puts stderr $result
            } else {
                puts stdout "deleted the $dir_name.aws file"
            }
        }
    }

    if [file exists $dir_name] {
        if [catch [file delete -force $dir_name] result] {
            puts stderr "Could not delete the $dir_name directory"
            puts stderr $result
        } else {
            puts stdout "deleted the $dir_name directory"
        }

    }

    file mkdir $dir_name

    set savedDir [pwd]
    puts stdout "PWD is $savedDir"

    # When using the GUI TCL shell by running avhdl.exe
    # workspace and design creation needs the full path to _run1234, otherwise it is created in the run folder
    if {[string equal $::CMD_ARG_SIMTOOL ahdl_gui]} {
        workspace create $savedDir/$dir_name
        design create -a $dir_name $savedDir
        puts "Successfully Created $dir_name workspace and design in GUI mode.\n"
    }
    # When using a command-line vsimsa.bat shell
    if {[string equal $::CMD_ARG_SIMTOOL ahdl_sh]} {
        alib $dir_name/$name
        set worklib $name
        puts "Successfully Created $dir_name/$name library directory in shell mode.\n"
    }

    puts "Successfully Created $dir_name directory\n"

    return
}


# proc map_precompiled_lib_list {}
# Purpose: Maps precompiled libraries in precompiled_lib_list.tcl.
# Inputs: none.
# Outputs: none.
proc map_precompiled_lib_list {} {
    puts stdout "==============utils::map_precompiled_lib_list================\n"
    source $::PRECOMPLIBLIST
    # Get library lists for each simulator and select the one required.

    # Got through each library and map it.
    foreach lib $PRECOMPILED_LIB_LIST {
    #    set word_list [split $lib]
    #    # first word is library name, second is path
    #    vmap [lindex $word_list 0] [lindex $word_list 1]
    }
}

##################### Test Case comiple ###########################
# Compile current test-case
set TC_COMP_INVOCATION {simu_vlog -sv -incr -timescale $TCTIMESCALE $TCSUBDIR/$TCFILENAME.sv }
set TC_COMP_INVOCATION_VERILOG {simu_vlog -incr -timescale $TCTIMESCALE $TCSUBDIR/$TCFILENAME.v }
set TC_COMP_INVOCATION_VHDL {simu_vcom -2008 $TCSUBDIR/$TCFILENAME.vhd }
##################### Variable for extra top level unit e.g. glbl ##################
global EXTRA_UNITS
set EXTRA_UNITS ""

##################### Variable for list of libraries, e.g. unisim ##################
global EXTRA_LIBS
set EXTRA_LIBS ""

############################# Sim database Optimization #############################
global OPTIMIZATION_ON
global OPTIMIZATION_OFF
global OPTIMIZATION_INVOCATION

# Appended to simulation command if optimizations on or off. No vopt function in Active-HDL
set OPTIMIZATION_ON ""
set OPTIMIZATION_OFF ""

set OPTIMIZATION_INVOCATION ""

############################# Simulator options setup #############################
global SIMULATOR_INVOCATION
global RUN_COMMAND

# Log and ASDB to result_rtl
set SIMULATOR_INVOCATION {vsim +access +r tb -asdb \"$tcSubDir/result_rtl/$tcFileName.asdb\" -PL pmi_work -L ovi_lifmd }
#set SIMULATOR_INVOCATION {vsim +access +r -l \"$TCSUBDIR/result_rtl/$TCFILENAME.log\" -asdb \"$TCSUBDIR/result_rtl/$TCFILENAME.asdb\" -PL pmi_work -L ovi_lifmd }

set RUN_COMMAND "run -all"

############################# Logging / TRANSCRIPTS #############################
global LOGGING_INVOCATION

set LOGGING_INVOCATION "log -mem -rec /*"

# The _transcript file {}_ command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
proc transcript_reset {name} {
    puts stdout "==============config_settings_activehdl::transcript_reset================\n"
    transcript to {}
    transcript to $name
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

# Appended to simulation invocation command if optimizations on or off. Coverage is enabled with -cc but can't be used together with -profiler
set COVERAGE_ON { -cc -cc_dest \"$TCSUBDIR/result_rtl/$TCFILENAME.coverage_report.rep\" }
set COVERAGE_OFF ""

# actually -dbg is added to the compiler invocation command
set COVERAGE_PARAMS ""
set COVERAGE_YES_PARAMS " -dbg "
# Passed to vlog when not using coverage.
set COVERAGE_NO_PARAMS ""

# Called per testcase to save that simulation's coverage. The example is for toggle coverage TBD conflict with the report during simulation. TBD Not tested.
set COVERAGE_REPORT_INVOCATION {toggle -toggle_type full -nosingle_edge -unknown_edge escape -rec -xml -o \"$TCSUBDIR/result_rtl/$TCFILENAME.coverage_report.xml\" -report all -type {/dut/*} }
set COVERAGE_SAVE_INVOCATION {}

############################# Coverage Merging and Reporting #####################################
# Coverage merging and reporting functions for regression. Placed here for easy modification. TBD correct calls for Active-HDL not impemented.
proc coverageMergeCmd {outFile inFile1 inFile2} {
    puts stdout "==============config_settings_activehdl::coverageMergeCmd================\n"
#    vcover merge -out $outFile $inFile1 $inFile2
    return
}
proc coverageReportCmd {outReport inCov} {
    puts stdout "==============config_settings_activehdl::coverageReportCmd================\n"
#    vcover report $inCov -file $outReport
    return
}

############################ View Test Case ######################################
# TBD correct call for Active-HDL not implemented yet.
proc view_wave_log {view_wave wave_do tcSubDir tcFileName} {
    puts stdout "==============config_settings_activehdl::view_wave_log================\n"
    global REGRESSION

    if { ![info exists REGRESSION]} {
        set REGRESSION no
    }

    # If not in regression, either exit, or reopen in viewer mode
    if [string equal -nocase $REGRESSION no] {
#        eval $::SIMULATOR_QUIT
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
#set SIMULATOR_QUIT "quit -sim"
set SIMULATOR_QUIT "endsim"

############################# Modelsim, Don't Hang During Regression Hack #####################
# Without this, script execution halts during a regression. TBD if needed in Active-HDL
proc preSimCommand {tcSubDir tcFileName tcTimeScale} {
    puts stdout "==============config_settings_activehdl::preSimCommand================\n"
    onerror {resume}
    return;
}

proc optimizeCommand {tcSubDir tcFileName tcTimeScale} {
    puts stdout "==============config_settings_activehdl::optimizeCommand================\n"

}

proc simCommand {tcSubDir tcFileName tcTimeScale} {
    puts stdout "==============config_settings_activehdl::simCommand================\n"
    set simcmd $::SIMULATOR_INVOCATION

    if {$::CMD_ARG_OPTIMIZE > 0} {append simcmd " $::OPTIMIZATION_ON "
    } else                     {append simcmd " $::OPTIMIZATION_OFF $::EXTRA_UNITS"}
    if {$::CMD_ARG_COVERAGE > 0} {append simcmd " $::COVERAGE_ON"
    } else                     {append simcmd " $::COVERAGE_OFF"}
    foreach lib $::EXTRA_LIBS {
        append simcmd " -L $lib"
    }

    eval $simcmd
}
