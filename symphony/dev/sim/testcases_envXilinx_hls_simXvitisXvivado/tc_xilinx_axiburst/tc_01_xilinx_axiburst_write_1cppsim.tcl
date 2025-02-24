# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-05-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testcase for clock and reset BFMs.
#               Intentionally fails for demonstration purposes.
#
# Updated       : 2019-10-08 / Dessislav Valkov - simplified and extracted the common tasks
#               to separate files
# --------------------------------------------------------------------//

# package require logger
# log_file myfile.log

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
# TODO: make the folder&name auto detected
# hls_cppsim/hls_csynth/hls_cosim/hls_export
set TCTYPE "hls_cppsim"
set TCFILENAME tc_01_xilinx_axiburst_write
set TCSUBDIR $TESTCASESDIR_XILINX_HLS/tc_xilinx_axiburst
set HLSSCRIPTSDIR ../../builds/scripts/axiburst_write
source $::HLSSCRIPTSDIR/proj_paths.tcl
set RUNDIR [pwd]
# store the paths above in a file for vitis to access
autogenerate_simu_paths

puts_debug1 "==============$TCSUBDIR/$TCFILENAME.tcl================\n"
puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl..."

# TC_TYPE hls_cppcim/hls_cosim
#set TC_TYPE "hls_cppsim"
puts stdout "Executing $TCTYPE flow..."


# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
#append ::OPTIMIZATION_INVOCATION ""
#append ::SIMULATOR_INVOCATION ""

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE

# puts stdout "Create HLS project ..."

# cd ../../builds/scripts

# puts stdout "HLS Project Deleting..."
#eval exec $::REDIRECTSTD vitis_hls -f proj_delete.tcl
# eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_delete.tcl; puts "---------------------------"



# puts stdout "HLS Project Creation..."
# eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_create.tcl


# puts stdout "HLS Project Deleting..."
# catch {[eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_delete.tcl]} result 
# if {$result eq "child process exited abnormally"} {
#     puts "-----------------------------------catch error--------------------------------"
#     # concatenate the log file with this error log
#     puts "Deleting Project ERROR !"
#     # exit compile
#     puts "cd from builds/vitis/project to sim/run folder"
#     eval exec $::REDIRECTSTD pwd
#     cd ../../sim/run
#     eval exec $::REDIRECTSTD pwd
#     return -level 2 -code error
# }

# puts stdout "HLS Project Creation..."
# catch {[eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_create.tcl]} result 
# if {$result eq "child process exited abnormally"} {
#     puts "-----------------------------------catch error--------------------------------"
#     # concatenate the log file with this error log
#     puts "Creating Project ERROR !"
#     # exit compile
#     puts "cd from builds/vitis/project to sim/run folder"
#     eval exec $::REDIRECTSTD pwd
#     cd ../../sim/run
#     eval exec $::REDIRECTSTD pwd
#     return -level 2 -code error
# }

# puts stdout "HLS RTL adding ..."
# eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_rtl.tcl
# puts stdout "HLS TB & TC adding ..."
# eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_tbtc.tcl

# puts stdout "HLS RTL adding ..."
# catch {[eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_rtl.tcl]} result 
# if {$result eq "child process exited abnormally"} {
#     puts "-----------------------------------catch error--------------------------------"
#     # concatenate the log file with this error log
#     puts "Adding HLS RTL to Project ERROR !"
#     # exit compile
#     puts "cd from builds/vitis/project to sim/run folder"
#     eval exec $::REDIRECTSTD pwd
#     cd ../../sim/run
#     eval exec $::REDIRECTSTD pwd
#     return -level 2 -code error
# }


# puts stdout "HLS TB & TC adding ..."   
# catch {[eval exec $::REDIRECTSTD vitis-run --mode hls --tcl proj_tbtc.tcl]} result 
# if {$result eq "child process exited abnormally"} {
#     puts "-----------------------------------catch error--------------------------------"
#     # concatenate the log file with this error log
#     puts "Adding TB and TC to Project ERROR !"
#     # exit compile
#     puts "cd from builds/vitis/project to sim/run folder"
#     eval exec $::REDIRECTSTD pwd
#     cd ../../sim/run
#     eval exec $::REDIRECTSTD pwd
#     return -level 2 -code error
# }

# puts stdout "CSIM design ..."
# eval exec $::REDIRECTSTD vitis-run --mode hls --tcl hls_run_csim.tcl



# puts stdout "C++ SIM design ..."
# catch {[eval exec $::REDIRECTSTD vitis-run --mode hls --tcl hls_run_csim.tcl]} result 
# if {$result eq "child process exited abnormally"} {
#     puts "-----------------------------------catch error--------------------------------"
#     # concatenate the log file with this error log
#     puts "C++ sim Compile ERROR !"
#     # exit compile
#     puts "cd from builds/vitis/project to sim/run folder"
#     eval exec $::REDIRECTSTD pwd
#     cd ../../sim/run
#     eval exec $::REDIRECTSTD pwd
#     return -level 2 -code error
# }

# # puts stdout "CoSIM RTL design ..."
# catch {[eval exec $::REDIRECTSTD vitis-run --mode hls --tcl hls_run_cosim.tcl]} result 
# if {$result eq "child process exited abnormally"} {
#     puts "-----------------------------------catch error--------------------------------"
#     # concatenate the log file with this error log
#     puts "CoSim syntesized RTL Compile ERROR !"
#     # exit compile
#     puts "cd from builds/vitis/project to sim/run folder"
#     eval exec $::REDIRECTSTD pwd
#     cd ../../sim/run
#     eval exec $::REDIRECTSTD pwd
#     return -level 2 -code error
# }

# puts stdout "CoSIM design ..."
# eval exec $::REDIRECTSTD vitis-run --mode hls --tcl hls_run_cosim.tcl

# cd ../../sim/run

#csim_design
#csynth_design
#cosim_design
#export_design -format ip_catalog

#write_ini ./dct-build.cfg
#write_ini project1.ini -all=true
#config_compile -pipeline_loops 30
#config_csim [OPTIONS]
#config_cosim [OPTIONS]