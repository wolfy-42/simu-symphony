# ---------------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
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

puts_debug1 "==============config_settings_xsim.tcl================\n"

# default simulator is Questa/Modelsim
set ::DEFAULT_SIMULATOR xsim

##################### Code compile ###########################
# timescale compile option - work in xelab but not in xvlog/xvhdl
set TIMESCALE_OPT "" 
set TIMESCALEELAB_OPT "-timescale" 
set TCTIMESCALE ""
set TCTIMESCALEELAB 1ns/100ps
set INCDIR_OPT "-i"
set DEFINE_OPT "-d"

# compile libs used
# TODO: check this var for libs if used anywhere
# set design libraries VSCMPL_LIBS
set VSCMPL_LIBS " simprims_ver xil_defaultlib"
# command for redirect to stdout, TCLSH interpreter needs it to show compile and simulation log
if {$::CMD_ARG_SIMVENTCL > -1} {
set REDIRECTSTD " >&@stdout "
} else {
set REDIRECTSTD " "
}

# Current test-case location, evaluated later during last step of execution (curly braces)
# global declaration is needed for regression runs
global TCSUBDIR
global CURRENT_TCSUBDIR
set CURRENT_TCSUBDIR {$::TCSUBDIR}
global TCFILENAME
global CURRENT_TCFILENAME
set CURRENT_TCFILENAME {$::TCFILENAME}

##################### Text logs clearing ###########################
# proc text_logs_init {}
# Purpose: Procedure which ensures a fresh compile/simulation logs
# Inputs none. - Uses the global variables for testcase name and the module folder name.
# Outputs: none.
proc text_logs_init {} {
    puts_debug2 "==============config_settings_xsim::text_logs_init================\n"

    # delete old logs
    puts "Delete old logs..." 
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.vhdl.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.vlog.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.elab.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.sim.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wlf]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cov]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.rep]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.coverage_report.rep]
    #file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.*]
    puts "Delete old logs comleted." 

}

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
    puts_debug2 "==============config_settings_xsim::ensure_fresh_lib================\n"
    if { ($::CMD_ARG_COMPILE == 0) || ($::CMD_ARG_RTLCOMPILE == 0) } {    
        puts stdout "Compiled HDL libraries are not deleted!"
    } else {  
        if {[file exists $dir_name]} {
            file delete -force $dir_name
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
    puts_debug2 "==============config_settings_xsim::map_precompiled_lib_list================\n"
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

##################### text logs ###########################
# The _transcript file {}_ command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
proc transcript_reset {name} {
}

############################# Modelsim/Questa simu compile functions #####################
# TB/TC compile log aggreagating to single file TODO: fix
##set VSCMPL_LOG " 2>&1 | tee compile.log; cat .tmp_simu_log >> xmvlog.log 2>/dev/null "
set VSCMPL_LOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log  2>/dev/null "
# TODO: fix this - the Xilinx logs are generated when calling the xilinx compile script fpga.sh geenrated by vivado simulation export
##set VSCMPL_XILINXLOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log; cp -f xmvhdl.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvhdl.log; cp -f xmvlog.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvlog.log 2>/dev/null "
set VSCMPL_XILINXLOG " "

# (TODO:fix not tested)to be used with xilinx simulation exported xsim *.sh script 
proc suxil {args} {
    # puts_debug2 "==============config_settings_xlog::suxil $args =================\n"

    # # add stdout redirect and rtl log concatenate to running log
    # set compile_command "$::REDIRECTSTD {*}$args [subst $::VSCMPL_XILINXLOG]"
    # puts "$compile_command"
    # #eval exec "$compile_command"
    # puts ""
    # # catch error during compile
    # catch {[eval exec "$compile_command"]} result 
    # if {$result eq "child process exited abnormally"} {
    #     puts "-----------------------------------catch error--------------------------------"
    #     # concatenate the log file with the error log, copy over other logs
    #     eval exec "cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log; cp -f xmvhdl.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvhdl.log; cp -f xmvlog.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvlog.log"      
    #     puts "Xilinx script Compile ERROR !"
    #     # exit compile
    #     return -level 2 -code error
    # }

    return;
}

# set vlog verilog/sv compile options
#set VSVLOG_OPTS "$REDIRECTSTD xmvlog -work fpga -64bit -messages -logfile $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log -update "
# TODO; port UVM support from the testcase call
set VSVLOG_OPTS "$REDIRECTSTD xvlog -incr "
# verilog compile command
proc suvlog {args} {
    puts_debug2 "==============config_settings_vlog::suvlog $args =================\n"

    set compile_command "$::VSVLOG_OPTS {*}$args "
    if {$::CMD_ARG_SIMVENTCL > -1} {
        # Linux bash use
        append compile_command " $::VSCMPL_LOG "}
    #puts [subst $compile_command]
    #puts ""
    # if run inside vivado or not, execute externally 
    if { ($::CMD_ARG_SIMVENTCL > -1) } {set extern "exec"} else {set extern ""}
    puts [subst $compile_command]
    puts ""    
    # catch error during compile
    catch {[eval $extern "$compile_command"]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        eval exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log       
        puts "suvlog Compile ERROR !"
        # exit compile
        return -level 2 -code error
    }

    return;
}

# set vcom vhdl compile options
#set VSVHDL_OPTS "$REDIRECTSTD xmvhdl -work fpga -64bit -messages -relax -logfile $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log -update "
set VSVHDL_OPTS "$REDIRECTSTD xvhdl -incr -2008 "
# vhdl compile command
proc suvhdl {args} {
    puts_debug2 "==============config_settings_vlog::suvhdl $args =================\n"

    set compile_command "$::VSVHDL_OPTS {*}$args "
    if {$::CMD_ARG_SIMVENTCL > -1} {
        # Linux bash use
        append compile_command " $::VSCMPL_LOG "}    
    #puts [subst $compile_command]
    #puts ""
    # catch error during compile
    # if run inside vivado or not, execute externally 
    if { ($::CMD_ARG_SIMVENTCL > -1) } {set extern "exec"} else {set extern ""}  
    puts [subst $compile_command]      
    puts ""
    catch {[eval $extern "$compile_command"]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        eval exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log       
        puts "suvhdl Compile ERROR !"
        # exit compile
        return -level 2 -code error
    }

    return;
}

############################# TODO:fix xsim elaborate #####################
set ::XSIM_INITFILE ""
#set ::XSIM_INITFILE "-initfile=xsim_ip.ini"
# -s key is for snapshot result of the elaboration
set ::XELAB_INVOCATION "$REDIRECTSTD xelab  -s work.tb_elab $::TIMESCALEELAB_OPT $::TCTIMESCALEELAB -L UNISIMS_VER -L XILINXCORELIB_VER work.tb -debug all -log $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.elab.log "
proc preSimCommand {} {
    puts_debug2 "==============config_settings_xsim::preSimCommand================\n"

    set elab_com $::XELAB_INVOCATION
    # -s key is for snapshot result of the elaboration
    #append elab_com " -s work.tb_elab $::TIMESCALEELAB_OPT $::TCTIMESCALEELAB "
    foreach unit $::EXTRA_UNITS {
        append elab_com " $unit "
    }
    #if {[llength $::EXTRA_LIBS]>0} {
        append elab_com " $::XSIM_INITFILE "
    #}
    foreach lib $::EXTRA_LIBS {
        append elab_com " -L $lib "
    }

    # optimize options
    if {$::CMD_ARG_OPTIMIZE > 0} {append simcmd " $::OPTIMIZATION_INVOCATION "
    } else                       {append simcmd ""}

    #eval $elab_com

    # catch error during compile
    # if run inside vivado or not, execute externally 
    if { ($::CMD_ARG_SIMVENTCL > -1) } {set extern "exec"} else {set extern ""}    
    puts stdout [subst $elab_com]
    puts ""   
    catch {[eval $extern "$elab_com"]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        #eval exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log       
        puts "xelab Compile ERROR !"
        # exit compile
        return -level 2 -code error
    }

    return;

}

############################# Sim database Optimization #############################
# Appended to simulation command if optimizations on or off
set OPTIMIZATION_ON ""
set OPTIMIZATION_OFF ""

############################# Elaboartion database Optimization (executed before simulation) #############################
# set elaboration options - max optimization
set VSELAB_OPTS " -O 3 "
set VSELAB_LIBS ""
set OPTIMIZATION_INVOCATION "$::VSELAB_OPTS "

# Variable for list of libraries, e.g. unisim 
# global EXTRA_LIBS
set EXTRA_LIBS ""

proc optimizeCommand {tcSubDir tcFileName tcTimeScale} {
    puts_debug2 "==============config_settings_xsim::optimizeCommand================\n"
}

############################# Simulator options setup #############################
# Variable for extra top level unit e.g. glbl 
# global EXTRA_UNITS
set EXTRA_UNITS ""

# set xmsim simulation options
set VSSIM_OPTS "$REDIRECTSTD xsim "
# Log to result_rtl
#set ::SIMULATOR_INVOCATION {vsim  -permit_unmatched_virtual_intf  -l "$tcSubDir/result_rtl/$tcFileName.log" -wlf "$tcSubDir/result_rtl/$tcFileName.wlf "}
set SIMULATOR_INVOCATION  "$VSSIM_OPTS work.tb_elab -log $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.log -t vsim_wavelog_coverage.tcl "

# simulation run command is empty becuse the "run" parameters are now in the TCL file called from the simulaton call function simCommand
set SIM_RUN_COMMAND ""

proc simCommand {} {
    puts_debug2 "==============config_settings_xsim::simCommand================\n"
    set simcmd $::SIMULATOR_INVOCATION

    # GUI mode to look at waveform  != CLI mode
    if {$::CMD_ARG_VIEW == 2} {
        append simcmd " -gui " }

    # waveform logging
    if {$::CMD_ARG_WAVELOGGING > 0} {
        append simcmd " -wdb $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wdb "   } 

    # optimize options
    if {$::CMD_ARG_OPTIMIZE > 0} {append simcmd " $::OPTIMIZATION_ON "
    } else                       {append simcmd " $::OPTIMIZATION_OFF $::EXTRA_UNITS "}

    # coverage options
    if {$::CMD_ARG_COVERAGE > 0} {append simcmd " $::COVERAGE_ON "
    } else                       {append simcmd " $::COVERAGE_OFF "}

    foreach lib $::EXTRA_LIBS {
        append simcmd " -L $lib"
    }

    # if run inside vivado or not, execute externally 
    if { ($::CMD_ARG_SIMVENTCL > -1) } {set extern "exec"} else {set extern ""}
    puts stdout [subst $simcmd]
    puts ""   
    eval $extern $simcmd    
}

proc generateSimTclFile {} {
    puts_debug2 "==============config_settings_vsim::generateSimTclFile================\n"

    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open vsim_wavelog_coverage.tcl w]

    # add wave logging parameters
    if {$::CMD_ARG_WAVELOGGING > 0} {            
        puts     "Wave log creation for vsim for all signals .tcl prep"
        putf $fp "#wave log creation for vsim for all signals"
        putf $fp "log_wave -r /* "
    } 

    # run simulation
    puts     "Run simulation until end .tcl prep"
    putf $fp "#run simulation until end"
    putf $fp "run -all"

    # Coverage reports saving - not in xsim
    if {$::CMD_ARG_COVERAGE > 0} {
        # puts stdout "Coverage report invocation .tcl prep"
        # putf $fp    "#Coverage report invocation .tcl prep"
        # puts stdout [subst $::COVERAGE_REPORT_INVOCATION]
        # putf $fp [subst $::COVERAGE_REPORT_INVOCATION]
        # puts stdout "\n"
        # puts stdout "Coverage database save invocation .tcl prep"  
        # putf $fp    "#Coverage database save invocation .tcl prep"  
        # puts stdout [subst $::COVERAGE_SAVE_INVOCATION]
        # putf $fp [subst $::COVERAGE_SAVE_INVOCATION]
        # puts stdout "\n"
        # puts stdout "Coverage .tcl prep complete\n"
        puts stdout "Coverage not available.\n"
    } else {
        puts stdout "No coverage selected.\n"
    }

    # exit simulation if not in GUI mode with simulator license use 
    if {$::CMD_ARG_VIEW != 2} {
        puts     "Exit simulation .tcl prep"        
        putf $fp "#exit simulation"
        putf $fp "close_vcd -quiet"
        putf $fp "close_sim -quiet"
        #putf $fp "quit -sim"
    } 

    # exit simulation if running in or not simulator vendor tcl
    if {$::CMD_ARG_SIMVENTCL > -1 && $::CMD_ARG_VIEW != 2} {
        puts     "Exit simulation .tcl prep"        
        putf $fp "#exit simulation"
        #putf $fp "exit"
        putf $fp "exit"
    }     

    close $fp

}

# Quit simulation without closing entire program 
global SIMULATOR_QUIT
# if running in terminal TCL interpreter then 'quit' command doesn't exist, 'quit' is only vsim TCL command
set SIMULATOR_QUIT "if {$::CMD_ARG_SIMVENTCL > 0} {
    puts stdout \"Quitting simulator ...\"
    close_vcd -quiet; close_sim -quiet
    }"
#set SIMULATOR_QUIT "if {$::CMD_ARG_SIMVENTCL == 1} {close_vcd -quiet; close_sim -quiet}"

############################ View Test Case Waveforms in GUI ######################################
# TODO fix proper
proc view_wave_log {view_wave wave_do tcSubDir tcFileName} {
    puts_debug2 "==============config_settings_xsim::view_wave_log================\n"
    global REGRESSION

    if { ![info exists REGRESSION]} {
        set REGRESSION no
    }

    # If not in regression, either exit, or reopen in viewer mode
    if [string equal -nocase $REGRESSION no] {
        eval $::SIMULATOR_QUIT
        if {$view_wave > 0} {

            # sim vendor tcl shell
            if { $::CMD_ARG_SIMVENTCL > 0 && $::CMD_ARG_VIEW == 1 } {
                # Waveform viewer from inside vivado TCL (use start_gui/stop_gui to bring the GUI)
                puts "open_wave_database [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wdb]"
                start_gui
                open_wave_database [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wdb]
                if [file exists $wave_do] {
                    puts "open_wave_config $wave_do"
                    open_wave_config $wave_do
                }
            } 

            # external tcl shell OR forced additional waveform GUI lounch
            if { $::CMD_ARG_SIMVENTCL == 0 || $::CMD_ARG_VIEW == 1.5 } {
                # Waveform viewer called in a separete window using one more vivado license  
                puts "xsim [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wdb] -gui"            
                exec xsim [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wdb] -gui
            }           


        } else {
            puts stdout "Not opening waveform in simulator.\n"
        }
    }
}

############################# Coverage options setup #############################
# no such option in xsim
set COVERAGE_PARAMS ""
set COVERAGE_YES_PARAMS ""
set COVERAGE_NO_PARAMS ""
set COVERAGE_PARAMS $COVERAGE_YES_PARAMS
if {$::CMD_ARG_COVERAGE == 0} {set COVERAGE_PARAMS $COVERAGE_NO_PARAMS}

# used by simulation command if optimizations in on or off
set COVERAGE_ON ""
set COVERAGE_OFF ""

# Called per testcase to save that simulation's coverage report and database
set COVERAGE_REPORT_INVOCATION ""
set COVERAGE_SAVE_INVOCATION "" 

# Coverage merging and reporting functions for regression. Placed here for easy modification.
proc coverageMergeCmd {outFile inFile1 inFile2} {

    return
}
proc coverageReportCmd {outReport inCov} {

    return
}