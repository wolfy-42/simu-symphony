# ---------------------------------------------------------------------------//
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

puts_debug1 "==============config_settings_activehdl.tcl================\n"

# default simulator is Active-HDL only on Windows
set ::DEFAULT_SIMULATOR ahdl_sh

##################### Code compile ###########################
# timescale compile option
set TIMESCALE_OPT "-timescale" 
set TCTIMESCALE 1ns/100ps
set INCDIR_OPT "+incdir+"
set DEFINE_OPT "+define+"

# compile libs used
# TODO: check this var for libs if used anywhere
# set design libraries VSCMPL_LIBS
set VSCMPL_LIBS " "
# command for redirect to stdout, TCLSH interpreter need it to show compile and simulation log
if {$::CMD_ARG_SIMVENTCL == 1} {
set REDIRECTSTD " "
} else {
set REDIRECTSTD " >&@stdout "
}

# Current test-case location, evaluated later during last step of execution (using curly braces for delayied execution)
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
    puts_debug2 "==============config_settings_activehdl::text_logs_init TODO: fix================\n"

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
# Gets reset before a new compilation.
global SIM_LIBRARY_DIRNAME
set SIM_LIBRARY_DIRNAME asim

# proc ensure_fresh_lib {}
# Purpose: Procedure which ensures a fresh library is created.
# Inputs:
#        dir_name   --> Directory where libraries are stored, has to be "xsim.dir" for xsim
#        lib_name   --> Name of the library to be created.
# Outputs: none.
proc ensure_fresh_lib {dir_name lib_name} {
    puts_debug2 "==============config_settings_activehdl::ensure_fresh_lib================\n"
    if { ($::CMD_ARG_COMPILE == 0) || ($::CMD_ARG_RTLCOMPILE == 0) } {    
        puts stdout "Compiled HDL libraries are not deleted!"
    } else {  
        if {[file exists $dir_name.aws]} {
            file delete -force $dir_name.aws
            puts stdout "deleted the $dir_name.aws directory"
        }
    }

    file mkdir $dir_name

    set savedDir [pwd]
    puts stdout "PWD is $savedDir"

    # TODO: fix
    # if run inside vendor tcl then vlib and vmap are local commands, otherwise they are external commands 
    if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}
    #eval $extern vlib $dir_name/$lib_name
    #eval $extern vmap $lib_name $dir_name/$lib_name

    # When using the GUI TCL shell by running avhdl.exe
    # workspace and design creation needs the full path to _run1234, otherwise it is created in the run folder
    if {[string equal $::CMD_ARG_SIMTOOL ahdl_gui]} {
        workspace create $savedDir/$dir_name
        design create -a $dir_name $savedDir
        puts "Successfully Created $dir_name workspace and design in GUI mode.\n"
    }
    # When using a command-line vsimsa.bat shell
    if {[string equal $::CMD_ARG_SIMTOOL ahdl_sh]} {
        alib $dir_name/$lib_name
        set worklib $lib_name
        puts "Successfully Created $dir_name/$lib_name library directory in shell mode.\n"
    }

    puts "Successfully Created $dir_name directory\n"
    return
}

# proc map_precompiled_lib_list {}
# Purpose: Maps precompiled libraries in precompiled_lib_list.tcl.
# Inputs: none.
# Outputs: none.
proc map_precompiled_lib_list {} {
    puts_debug2 "==============config_settings_activehdl::map_precompiled_lib_list TODO: fix================\n"
    source $::PRECOMPLIBLIST
    # Get library lists for each simulator and select the one required.

    # Got through each library and map it.
    foreach lib $PRECOMPILED_LIB_LIST {
        set word_list [split $lib]
        # first word is library name, second is path

        # if run in questa, vlib and vmap are local, otherwise they are external commands
        if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}
        #$extern vmap [lindex $word_list 0] [lindex $word_list 1]
    }
}

##################### text logs ###########################
# The _transcript file {}_ command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
proc transcript_reset {name} {
    puts_debug2 "==============config_settings_activehdl::transcript_reset================\n"

    # if runing in tclsh the command 'transcript' is not preset
    if {$::CMD_ARG_SIMVENTCL == 1} {transcript to {} }

    # if runing in tclsh the command 'transcript' is not preset
    if {$::CMD_ARG_SIMVENTCL == 1} {transcript to $name }

    puts stdout "Transcript is closed and reopened"
}

############################# Modelsim/Questa simu compile functions #####################
# TODO: fis this - the Xilinx logs are generated when calling the xilinx compile script fpga.sh geenrated by vivado simulation export
##set VSCMPL_XILINXLOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log; cp -f xmvhdl.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvhdl.log; cp -f xmvlog.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvlog.log 2>/dev/null "
set VSCMPL_XILINXLOG " "
# TODO: fix when TC created
# to be used with xilinx simulation exported vsim *.sh script 
proc suxil {args} {
    puts_debug2 "==============config_settings_activehdl::suxil $args TODO:fix =================\n"

    # add stdout redirect and rtl log concatenate to running log
    set compile_command "$::REDIRECTSTD {*}$args [subst $::VSCMPL_XILINXLOG]"
    puts [subst "$compile_command"]
    #eval exec "$compile_command"
    puts ""
    # catch error during compile
    catch {[eval exec "$compile_command"]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with the error log, copy over other logs
        eval exec "cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log; cp -f xmvhdl.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvhdl.log; cp -f xmvlog.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvlog.log"      
        puts "Xilinx script Compile ERROR !"
        # exit compile
        return -level 2 -code error
    }

    return;
}

# TB/TC compile log aggreagating to single file TODO: fix
##set VSCMPL_LOG " 2>&1 | tee compile.log; cat .tmp_simu_log >> xmvlog.log 2>/dev/null "
set VSCMPL_LOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log  2>/dev/null "

# set vlog verilog/sv compile options
#set VSVLOG_OPTS "$REDIRECTSTD xmvlog -work fpga -64bit -messages -logfile $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log -update "
# TODO; port UVM support from the testcase call
set VSVLOG_OPTS "$REDIRECTSTD xvlog -incr "
# verilog compile command
proc suvlog {args} {
    puts_debug2 "==============config_settings_activehdl::suvlog $args =================\n"

    set compile_command "$::VSVLOG_OPTS {*}$args "
    if {$::CMD_ARG_SIMVENTCL == 0} {
        # Linux bash use
        append compile_command " $::VSCMPL_LOG "}
    # puts [subst $compile_command]
    # puts ""
    # if run inside questa then use local commands, otherwise execute externally 
    if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}
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
set VSVHDL_OPTS "$REDIRECTSTD vcom -incr -2008 "
# vhdl compile command
proc suvhdl {args} {
    puts_debug2 "==============config_settings_activehdl::suvhdl $args =================\n"

    set compile_command "$::VSVHDL_OPTS {*}$args "
    if {$::CMD_ARG_SIMVENTCL == 0} {
        # Linux bash use
        append compile_command " $::VSCMPL_LOG "}    
    # puts [subst $compile_command]
    # puts ""
    # catch error during compile
    # if run inside questa then use local commands, otherwise execute externally 
    if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"} 
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

############################# Elaboration #####################
#set ::XSIM_INITFILE ""
#set ::XSIM_INITFILE "-initfile=xsim_ip.ini"
# -s key is for snapshot result of the elaboration
#set ::XELAB_INVOCATION "$REDIRECTSTD xelab  -s work.tb_elab $::TIMESCALEELAB_OPT $::TCTIMESCALEELAB -L UNISIMS_VER -L XILINXCORELIB_VER work.tb -debug all -log $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.elab.log "

# Without this, script execution halts during a regression
proc preSimCommand {} {
    puts_debug2 "==============config_settings_activehdl::preSimCommand================\n"

    if {$::CMD_ARG_SIMVENTCL == 1} { onerror {resume} } 

    return;
}

############################# Sim database Optimization #############################
# no vopt function in Active HDL
# Appended to simulation command if optimizations on or off
set OPTIMIZATION_ON ""
set OPTIMIZATION_OFF ""

# set elaboration options
#set VSELAB_OPTS "$REDIRECTSTD vopt +acc "
set VSELAB_OPTS ""
#set VSELAB_LIBS " -L xil_defaultlib -L gtwizard_ultrascale_v1_7_16"
set VSELAB_LIBS ""
#set OPTIMIZATION_INVOCATION "vopt +acc tb -o tb_opt"
#set OPTIMIZATION_INVOCATION "$::VSELAB_OPTS $::VSELAB_LIBS  tb -o tb_opt "
set OPTIMIZATION_INVOCATION ""

# Variable for list of libraries, e.g. unisim 
# no optimization avalaible in Active HDL
set EXTRA_LIBS ""
proc optimizeCommand {tcSubDir tcFileName tcTimeScale} {
    puts_debug2 "==============config_settings_activehdl::optimizeCommand================\n"
    set optcmd $::OPTIMIZATION_INVOCATION
    foreach lib $::EXTRA_LIBS {
        append optcmd " -L $lib"
    }
    foreach unit $::EXTRA_UNITS {
        append optcmd " $unit"
    }

    puts stdout [subst $optcmd]
    puts ""   
    # if run inside questa then use local commands, otherwise execute externally 
    if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}    
    eval $extern $optcmd

}

############################# Simulator options setup #############################
# Variable for extra top level unit e.g. glbl 
# global EXTRA_UNITS
set EXTRA_UNITS ""

# set xmsim simulation options
set VSSIM_OPTS "$REDIRECTSTD vsim  -permit_unmatched_virtual_intf +access +r tb -PL pmi_work -L ovi_lifmd "
# Log and WLF to result_rtl
# TODO: fix sim command for Active HDL
#set ::SIMULATOR_INVOCATION {vsim  -permit_unmatched_virtual_intf  -l "$tcSubDir/result_rtl/$tcFileName.log" -wlf "$tcSubDir/result_rtl/$tcFileName.wlf "}
set SIMULATOR_INVOCATION  "$VSSIM_OPTS  -l $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.log -do vsim_wavelog_coverage.tcl "
#set SIMULATOR_INVOCATION  "$VSSIM_OPTS  -l $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.log  -wlf $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.wlf "

# simulation run command is empty becuse the "run" parameters now in the TCL file called from the simulaton call function simCommand
set SIM_RUN_COMMAND ""

proc simCommand {} {
    puts_debug2 "==============config_settings_activehdl::simCommand================\n"
    set simcmd $::SIMULATOR_INVOCATION

    # not GUI mode to look at waveform == CLI mode
    #if {$::CMD_ARG_VIEW != 2} {
    #    append simcmd " -c " }

    # waveform logging
    if {$::CMD_ARG_WAVELOGGING > 0} {
        append simcmd " -asdb $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.asdb "   } 

    # optimize options
    if {$::CMD_ARG_OPTIMIZE > 0} {append simcmd " $::OPTIMIZATION_ON "
    } else                       {append simcmd " $::OPTIMIZATION_OFF $::EXTRA_UNITS "}

    # coverage options
    if {$::CMD_ARG_COVERAGE > 0} {append simcmd " $::COVERAGE_ON "
    } else                       {append simcmd " $::COVERAGE_OFF "}

    foreach lib $::EXTRA_LIBS {
        append simcmd " -L $lib"
    }

    # if run inside questa then use local commands, otherwise execute externally 
    if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}
    puts stdout [subst $simcmd]
    puts ""       
    eval $extern $simcmd    
}

proc generateSimTclFile {} {
    puts_debug2 "==============config_settings_activehdl::generateSimTclFile================\n"

    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open vsim_wavelog_coverage.tcl w]

    puts     "Wave log .tcl prep"

    # add wave logging parameters
    if {$::CMD_ARG_WAVELOGGING > 0} {            
        puts     "Wave log creation for vsim for all signals .tcl prep"
        putf $fp "#wave log creation for vsim for all signals"
        putf $fp "log -mem -rec /* "
    } 

    # run simulation
    puts     "Run simulation until end .tcl prep"
    putf $fp "#run simulation until end"
    putf $fp "run -all"

    # Coverage reports saving 
    if {$::CMD_ARG_COVERAGE > 0} {
        puts stdout "Coverage report invocation .tcl prep"
        putf $fp    "#Coverage report invocation .tcl prep"
        puts stdout [subst $::COVERAGE_REPORT_INVOCATION]
        putf $fp [subst $::COVERAGE_REPORT_INVOCATION]
        puts stdout "\n"
        puts stdout "Coverage database save invocation .tcl prep"  
        putf $fp    "#Coverage database save invocation .tcl prep"  
        puts stdout [subst $::COVERAGE_SAVE_INVOCATION]
        putf $fp [subst $::COVERAGE_SAVE_INVOCATION]
        puts stdout "\n"
        puts stdout "Coverage .tcl prep complete\n"
    } else {
        puts stdout "No coverage selected.\n"
    }

    # exit simulation if not in GUI mode with simulator license use
    if {$::CMD_ARG_VIEW != 2} {
        puts     "Exit simulation .tcl prep"        
        putf $fp "#exit simulation"
        putf $fp "endsim"
    } 

    # exit simulation if running in not simulator vendor tcl
    if {$::CMD_ARG_SIMVENTCL == 0 && $::CMD_ARG_VIEW != 2} {
        puts     "Exit simulation .tcl prep"        
        putf $fp "#exit simulation"
        putf $fp "exit"
    }     

    close $fp

}

# Quit simulation without closing entire program 
global SIMULATOR_QUIT
# if running in terminal TCL interpreter then 'quit' command doesn't exist, 'quit' is only vsim TCL command
set SIMULATOR_QUIT "if {$::CMD_ARG_SIMVENTCL == 1} {
    puts stdout \"Quiting simulator ...\"
    endsim
    }"

############################ View Test Case Waveforms in GUI ######################################
proc view_wave_log {view_wave wave_do tcSubDir tcFileName} {
    puts_debug2 "==============config_settings_activehdl::view_wave_log================\n"
    global REGRESSION

    if { ![info exists REGRESSION]} {
        set REGRESSION no
    }

    # If not in regression, either exit, or reopen in viewer mode
    if [string equal -nocase $REGRESSION no] {
        eval $::SIMULATOR_QUIT
        if {$view_wave == 1} {
            vsim -view $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wlf

            # Waveform viewer
            if [file exists $wave_do] {
                do $wave_do
            }
        } else {

            puts stdout "Not opening waveform in simulator.\n"
       }
    }
}

############################# Coverage options setup #############################
# used by vlog vcom compile commands when optimization is on or off
set COVERAGE_PARAMS ""
set COVERAGE_YES_PARAMS " -dbg "
set COVERAGE_NO_PARAMS " "
set COVERAGE_PARAMS $COVERAGE_YES_PARAMS
if {$::CMD_ARG_COVERAGE == 0} {set COVERAGE_PARAMS $COVERAGE_NO_PARAMS}

# used by simulation command if optimizations in on or off
set COVERAGE_ON " -cc -cc_dest $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.coverage_report.rep "
set COVERAGE_OFF ""

# Postprocessing called per testcase to save that simulation's coverage report and database
#set COVERAGE_REPORT_INVOCATION {coverage report -file "$CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.coverage_report.rep"}
set COVERAGE_REPORT_INVOCATION "toggle -toggle_type full -nosingle_edge -unknown_edge escape -rec -xml -o $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.coverage_report.xml -report all -type {/dut/*} "
#set COVERAGE_SAVE_INVOCATION "coverage save $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.cov" 
set COVERAGE_SAVE_INVOCATION "" 

# Coverage merging and reporting functions for regression. Placed here for easy modification.
proc coverageMergeCmd {outFile inFile1 inFile2} {
    puts_debug2 "==============config_settings_activehdl::coverageMergeCmd================\n"
    #vcover merge -out $outFile $inFile1 $inFile2
    return
}
proc coverageReportCmd {outReport inCov} {
    puts_debug2 "==============config_settings_activehdl::coverageReportCmd================\n"
    #vcover report $inCov -file $outReport
    return
}

