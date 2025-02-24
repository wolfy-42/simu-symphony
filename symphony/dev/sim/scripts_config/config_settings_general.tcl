#-----------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-10-04
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Common paths for simu.tcl when run in tclsh.
#
# Updated       : 2019-10-23 / Dessislav Valkov - merged all settings calls to this file
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW
# --------------------------------------------------------------------//

puts stdout "==============config_settings_general.tcl================\n"

# Global timescale for Verilog
#set TCTIMESCALE 1ns/100ps

############################# Global path settings #####################################
# General script parameters relative to sim/run/
# set SIMDIR         ..
set SIMDIR         [pwd]
set SIMDIR         [file dirname $SIMDIR]
set SCRPTCFGDIR    $::SIMDIR/scripts_config
set SCRPTLIBDIR    $::SCRPTCFGDIR/scripts_lib
set SCRPTTCOMMONDIR    $::SCRPTCFGDIR/tccommon_lib
set TESTCASESDIR_FIDUS_SV   $::SIMDIR/testcases_envFidus_sv_simMquestaXvivadoCxcelium
set TESTCASESDIR_FIDUS_SV_OLD  $::SIMDIR/testcases_envFidus_sv_simMquestaXvivado_old
set TESTCASESDIR_FIDUS_V    $::SIMDIR/testcases_envFidus_v_simMquestaXvivado
set TESTCASESDIR_FIDUS_VHDL $::SIMDIR/testcases_envFidus_vhdl_simMquestaXvivado
set TESTCASESDIR_XILINX_HLS $::SIMDIR/testcases_envXilinx_hls_simXvitisXvivado
set TESTCASESDIR_XILINX     $::SIMDIR/testcases_envXilinx_sv_simMquestaXvivado
set TESTCASESDIR_INTEL      $::SIMDIR/testcases_envIntel_sv_simMquesta
set TESTCASESDIR_OSVVM      $::SIMDIR/testcases_envOsvvm_vhdl_simMquesta
set CMD_LINE_OPTIONS_DEFAULT    $::SCRPTCFGDIR/config_cmd_line_options_default.tcl
set CMD_LINE_OPTIONS_AUTOGEN    $::SCRPTLIBDIR/auto_gen/cmd_line_options.tcl
set SIMU_SHELL_OPTIONS_AUTOGEN  $::SCRPTLIBDIR/auto_gen/simu_shell_options.tcl
set SETTINGS_SIM_XHLS           $::SCRPTCFGDIR/config_settings_xhls.tcl
set SETTINGS_SIM_VSIM           $::SCRPTCFGDIR/config_settings_vsim.tcl
set SETTINGS_SIM_XSIM           $::SCRPTCFGDIR/config_settings_xsim.tcl
set SETTINGS_SIM_ACTIVEHDL      $::SCRPTCFGDIR/config_settings_activehdl.tcl
set SETTINGS_SIM_XCELIUM        $::SCRPTCFGDIR/config_settings_xcelium.tcl
set SETTINGS_REGRESSION         $::SCRPTCFGDIR/config_settings_regression.tcl
set REGRESSION_RESULTS_DIR      $::SIMDIR/regression_results
set ARCHIVE_DIR                 $::REGRESSION_RESULTS_DIR/results_archive
set PRECOMPLIBLIST              $::SCRPTCFGDIR/config_precompiled_lib_list.tcl
set TCCOMMON_TCCOMPILESIMULATE  $::SCRPTTCOMMONDIR/tccommon_tc_compile_simulate.tcl
set TCCOMMON_TCCONFIG           $::SCRPTTCOMMONDIR/tccommon_tc_config.tcl
set BUILDSDIR                   ../../builds

############################ Read Commandline Options ###############################
# Command line options being read from two locations depending if working
# from TCL SIMU environment or from Tool TCL environment
source $CMD_LINE_OPTIONS_DEFAULT
if { [info exists ::IN_SIMU_ENVIRONMENT] || [string equal [lindex $::argv 0] IN_SIMU_ENVIRONMENT] } {
    puts stdout "==============config_settings_general SOURCING SIMU CMD LINE OPTIONS FROM AUTOGEN==============\n"
    source $SIMU_SHELL_OPTIONS_AUTOGEN
    source $CMD_LINE_OPTIONS_AUTOGEN
}
if { [info exists ::CMD_ARD_AUTO_SIMTOOL] && $::CMD_ARG_AUTO_SIMTOOL} {
    if { [llength [info commands version]] > 0 && [string first Vivado [version]] != -1} {
        set ::CMD_ARG_SIMTOOL xsim
        puts "Auto selecting simtool: xsim"
    } elseif { [llength [info commands vsim]] > 0 } {
        set ::CMD_ARG_SIMTOOL vsim
        puts "Auto selecting simtool: vsim"
    } else {
        puts "Not in a recognized simulator, falling back to CMD_ARG_SIMTOOL"
    }
}
set ::DEFAULT_SIMULATOR $::CMD_ARG_SIMTOOL
puts "The simulator selected by the command line argument is: $::DEFAULT_SIMULATOR"


# // black - 30
# // red - 31
# // green - 32
# // yellow - 33
# // blue - 34
# // magenta - 35
# // cyan - 36
# // lightgray - 37

# // \033[0m - is the default color for the console
# // \033[0;#m - is the color of the text, where # is one of the codes mentioned above
# // \033[1m - makes text bold
# // \033[1;#m - makes colored text bold**
# // \033[2;#m - colors text according to # but a bit darker
# // \033[4;#m - colors text in # and underlines
# // \033[7;#m - colors the background according to #
# // \033[9;#m - colors text and strikes it

#     static string colour_def = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0m"; // default consol colour
#     static string colour_tmp = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0m"; // temporary colour
#     static string colour_red = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;31m";
#     static string colour_dred = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;31m";
#     static string colour_green = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;32m";
#     static string colour_dgreen = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;32m"; // dark green
#     static string colour_yellow = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;33m"; // yellow
#     static string colour_blue = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;34m";
#     static string colour_dblue = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;34m";  // dark blue
#     static string colour_cyan = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;36m";
#     static string colour_dcyan = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;36m";
#     static string colour_purple = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;35m";
#     static string colour_dpurple = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;35m";
#     static string colour_brown = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;33m";
#     static string colour_dbrown = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[0;33m";
#     static string colour_bold = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;1m";
#     static string colour_inverse = (`CMD_ARG_COLOUR == 0) ? "" :  "\033[1;7m";

# set debug message colour to gray 
global debug_colour1
set debug_colour1 "\033\[0;37m"
# set debug message colour to light gray
global debug_colour2
set debug_colour2 "\033\[2;37m"

# set message colour to red
global red_colour
set red_colour "\033\[1;31m"
# set message colour to green
global green_colour
set green_colour "\033\[1;32m"
# set message colour to yellow
global yellow_colour
set yellow_colour "\033\[0;33m"

# set debug colour to default
global debug_colour_reset
set debug_colour_reset "\033\[0m"

# debug message print
proc puts_debug1 {msg} {
    if { ($::CMD_ARG_DEBUGMSG > 0) } {
        puts stdout "$::debug_colour1 $msg $::debug_colour_reset";
    }
}
proc puts_debug2 {msg} {
    if { ($::CMD_ARG_DEBUGMSG > 0) } {
        puts stdout "$::debug_colour2 $msg $::debug_colour_reset";
    }
}

############################ Common Libraries ###############################
# Common Utility functions
source $SCRPTLIBDIR/utils.tcl

############################# Regression Files Naming ###################################
# A list of testcases that are executed during regression. Multiple runs of regression use this
# list to run multiple testcases at the same time.
# Created at the beginning of regression, and removed after it is complete.
set SUPERLISTNAME "$REGRESSION_RESULTS_DIR/REGRESSION_TC_LIST.txt"
set SUPERLISTLOCK "$REGRESSION_RESULTS_DIR/_regression_tc_list.lock"

############################# Automated email notifications setup #############################
# Purpose: Sends a notification enable, if enabled, as configure below.
# Needs MIME and SMTP TCL packages located in tcllib - available in Questa, but has to be installed on RedHat
# Inputs:
#       subject: email subject
#       body:    email body
proc send_simulation_complete_email {subject body} {
    puts_debug2 "==============config_settings_general::send_simulation_complete_email================\n"
    ######################################
    # EDIT BELOW
    ######################################

    # Set to 1 to enable email notifications, 0 otherwise:
    set USE_EMAIL_NOTIFICATIONS 0

    # Set  to receive address
    set EMAIL_TO firstname.lastname@fidus.com

    # Set to from address (eg. firstname.lastname@zeus.fidus.ca)
    set EMAIL_FROM firstname.lastname@zeus.fidus.ca

    # Mail server to send with, localhost tested on zeus
    set EMAIL_SERVER localhost

    ############################# Email notification procedure #############################
    # DO NOT EDIT BELOW
    ######################################
    if {$USE_EMAIL_NOTIFICATIONS == 0} {
        return
    }
    package require smtp
    package require mime

     set token [mime::initialize -canonical text/plain -string $body]
     mime::setheader $token Subject $subject
     smtp::sendmessage $token -originator $EMAIL_FROM -recipients $EMAIL_TO -servers $EMAIL_SERVER
     mime::finalize $token
}

############################ Simulator relevant Configurations ###############################
# SETTINGS_SIM_DEFAULT is set below
# Some setting can be overwritten in the simulator specific config file called below.
global SETTINGS_SIM_DEFAULT
if {[string equal $::DEFAULT_SIMULATOR vsim]} {set ::SETTINGS_SIM_DEFAULT $SETTINGS_SIM_VSIM}
if {[string equal $::DEFAULT_SIMULATOR xsim]} {set ::SETTINGS_SIM_DEFAULT $SETTINGS_SIM_XSIM}
if {[string equal $::DEFAULT_SIMULATOR ahdl_gui] || [string equal $::DEFAULT_SIMULATOR ahdl_sh]} {
    set ::SETTINGS_SIM_DEFAULT $SETTINGS_SIM_ACTIVEHDL}
if {[string equal $::DEFAULT_SIMULATOR xm]}     {set ::SETTINGS_SIM_DEFAULT $SETTINGS_SIM_XCELIUM}


# Source the the HLS settings, the selected simulator settings, and the regression settings 

source $::SETTINGS_SIM_XHLS

puts "The simulator selected is: $::DEFAULT_SIMULATOR"
puts "The simulator configuration file used is: $SETTINGS_SIM_DEFAULT"
source $::SETTINGS_SIM_DEFAULT

source $::SETTINGS_REGRESSION


