# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-25
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Common test case structure for compile and simulate
#
# Updated       : 2019-10-25 / author - comment
# --------------------------------------------------------------------//

puts_debug1 "==============tccommon_tc_compile_simulate.tcl================\n"
puts stdout "Executing compile flow ..."

if { ![info exists ::TCTYPE] } {
    puts stdout "Executing HDL compile flow ..."

    ############################## Run HDL Simulation #############################################
    # Print config options/settings for information after being modified
    source $SCRPTTCOMMONDIR/tccommon_print_config_options.tcl
    # Create or refresh sim lib 
    source $SCRPTTCOMMONDIR/tccommon_refresh_simlibs.tcl
    # Compile RTL, TB, BFMs, DUT, libs
    source $SCRPTTCOMMONDIR/tccommon_execute_compile_all.tcl
    # Optimize compiled RTL if needed.
    source $SCRPTTCOMMONDIR/tccommon_execute_optimization.tcl
    # Prepare the sim commands in .tcl file to be used by the simulator
    generateSimTclFile
    # Call prSimCommand to do any necessary simulator-specific pre simulation prep - for example "onbrake {resume}"
    preSimCommand 
    simCommand 
    # Close current log file and open new one just to be sure the old was closed.
    transcript_reset "transcript.log"
    # Exit simulator to release the license
    eval $::SIMULATOR_QUIT
    # When the simulator license is released then Reopens in viewer mode if the argument is selected and if not in regression
    view_wave_log $::CMD_ARG_VIEW $TCSUBDIR/wave.do $TCSUBDIR $TCFILENAME

    unset INITSEED

    puts stdout "Executed HDL compile flow ..."

} elseif {[string equal $::TCTYPE "hls_cppsim"] 
    || [string equal $::TCTYPE "hls_csynth"] 
    || [string equal $::TCTYPE "hls_cosim"]
    || [string equal $::TCTYPE "hls_export"]} {
    puts stdout "Executing HLS compile flow ..."

    ############################## Run HLS Simulation #############################################
    # Print config options/settings for information after being modified
    # source $SCRPTTCOMMONDIR/tccommon_print_config_options.tcl
    #TODO fix

    # prepare paths
    generateTcPathsTclFile

    # Create or refresh sim lib - delete old project 
    source $SCRPTTCOMMONDIR/tccommon_refresh_simlibs.tcl
    #hls_ensure_fresh_proj

    # proj create RTL, TB, BFMs, DUT, libs
    # source $SCRPTTCOMMONDIR/tccommon_execute_compile_all.tcl
    hls_proj_create
    hls_proj_tbtc


    # # Prepare the sim commands in .tcl file to be used by the simulator 
    # generateSimTclFile

    if {[string equal $::TCTYPE "hls_cppsim"] 
    || [string equal $::TCTYPE "hls_csynth"] 
    || [string equal $::TCTYPE "hls_cosim"]
    || [string equal $::TCTYPE "hls_export"]} {
    puts stdout "########################Executing HLS CppSim flow...########################"

    simu_run_cppsim

    puts stdout "########################Executed HLS CppSim flow########################"

    }

    if {[string equal $::TCTYPE "hls_csynth"] 
    || [string equal $::TCTYPE "hls_cosim"] 
    || [string equal $::TCTYPE "hls_export"]} {
    puts stdout "########################Executing HLS CSynth flow...########################"

    simu_run_csynth

    puts stdout "########################Executed HLS CSynth flow########################"

    }

    if {[string equal $::TCTYPE "hls_cosim"] 
    || [string equal $::TCTYPE "hls_export"]} {
    puts stdout "########################Executing HLS CoSim flow...########################"

    simu_run_cosim

    puts stdout "########################Executed HLS CoSim flow########################"

    }

    if {[string equal $::TCTYPE "hls_export"]} {
    puts stdout "########################Executgin HLS Export flow...########################"

    simu_run_export

    puts stdout "########################Executed HLS Export flow########################"

    }


    # # Close current log file and open new one just to be sure the old was closed.(NA)
    # transcript_reset "transcript.log"
    # # Exit simulator to release the license (NA)
    # eval $::SIMULATOR_QUIT


    # # When the simulator license is released then Reopens in viewer mode if the argument is selected and if not in regression
    # view_wave_log $::CMD_ARG_VIEW $TCSUBDIR/wave.do $TCSUBDIR $TCFILENAME

    puts stdout "####Executed HLS compile flow####"

    puts stdout "########################Parsing HLS flow status...########################"
    parsing_hls_flow_status



}


########################### Cleanup ##########################################
# Clean up variables, for safety.
set TCTYPE 1
unset TCTYPE
unset TCFILENAME
unset TCSUBDIR
#unset INITSEED
unset TCTIMESCALE

puts stdout "-----------Completed compile flow-----------"
