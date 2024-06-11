# ---------------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
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

puts_debug1 "==============config_settings_xcelium.tcl================\n"

# default simulator is Cadence/Ecelium
set ::DEFAULT_SIMULATOR xm

##################### Code compile ###########################
# timescale compile option
set TIMESCALE_OPT "-vtimescale" 
set TCTIMESCALE 1ns/100ps
set INCDIR_OPT "-incdir"
set DEFINE_OPT "-define"

# compile libs used
# set design libraries
set XMCMPL_LIBS " simprims_ver xil_defaultlib common ahb innolink_fpga memory config fpga serdes "
# simvision doesn't like the messages command for redirect to stdout, but it does the messages redirect by default without that command
if {$::CMD_ARG_SIMVENTCL == 1} {
set REDIRECTSTD " "
} else {
set REDIRECTSTD " >&@stdout "
}
# Current test-case location, evaluated later during execution (curly braces)
set CURRENT_TCSUBDIR {$::TCSUBDIR}
set CURRENT_TCFILENAME {$::TCFILENAME}

##################### Text logs clearing ###########################
# proc text_logs_init {}
# Purpose: Procedure which ensures a fresh compile/simulation logs
# Inputs none. - Uses the global variables for testcase name and the module folder name.
# Outputs: none.
proc text_logs_init {} {
    puts_debug2 "==============config_settings_vsim::text_logs_init TODO:fix================\n"

    # delete old logs
    puts "Delete old logs..." 
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvhdl.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvlog.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.elab.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.sim.log]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log]
    #file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wlf]
    #file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cov]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.rep]
    file delete -force [subst $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.coverage_report.rep]    
    puts "Delete old logs comleted." 

}

##################### Library Mapping ###########################
# Gets reset before a new compilation. Default Excelim lib is xcelium.d
global SIM_LIBRARY_DIRNAME
set SIM_LIBRARY_DIRNAME xcelium_lib

# proc ensure_fresh_lib {}
# Purpose: Procedure which ensures a fresh library is created.
# Inputs:
#        dir_name   --> Directory where libraries are stored, has to be "xsim.dir" for xsim
#        lib_name   --> Name of the library to be created.
# Outputs: none.
proc ensure_fresh_lib {dir_name lib_name} {
    puts_debug2 "==============config_settings_xcelium::ensure_fresh_lib================\n"
    if { ($::CMD_ARG_COMPILE == 0) || ($::CMD_ARG_RTLCOMPILE == 0) } {    
        puts stdout "Compiled HDL libraries are not deleted!"
    } else {  
        if {[file exists $dir_name]} {
            file delete -force $dir_name
            puts stdout "deleted the $dir_name directory"
        }
    }

    # in questa, vlib and vmap, in xcelium created by mkdir
    file mkdir $dir_name    
    file mkdir $dir_name/fpga
    puts "There should be $dir_name directory and the libraries inside\n"

    ## if run inside questa then vlib and vmap are local commands, otherwise they are external commands 
    #if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}
    #eval $extern vlib $dir_name/$lib_name
    #eval $extern vmap $lib_name $dir_name/$lib_name

    puts "Successfully Created $dir_name directory\n"
    return
}

# proc map_precompiled_lib_list {}
# Purpose: Maps precompiled libraries in precompiled_lib_list.tcl.
# Inputs: none.
# Outputs: none.
proc map_precompiled_lib_list {} {
    puts_debug2 "==============config_settings_xcelium::map_precompiled_lib_list TODO: fix================\n"
    source $::PRECOMPLIBLIST
    # Get library lists for each simulator and select the one required.

    # Got through each library and map it. In Xcelium it is just folders creation in library folder (no vlip/vmap commands)
    foreach lib $PRECOMPILED_LIB_LIST {
        #set word_list [split $lib]
        ## first word is library name, second is path
        # first word is library name, second is path, in xcelium it's a list to pass to simulator

        ## if run in questa, vlib and vmap are local, otherwise they are external commands
        #if { ($::CMD_ARG_SIMVENTCL == 1) } {set extern ""} else {set extern "exec"}
        #$extern vmap [lindex $word_list 0] [lindex $word_list 1]
    }
}

##################### text logs ###########################
# The _transcript file {}_ command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
# not existing command and not required in Xcelium
proc transcript_reset {name} {
    puts stdout "==============config_settings_xcelium::transcript_reset================\n"

    ## if runing in tclsh the command 'transcript' is not preset
    #if {$::CMD_ARG_SIMVENTCL == 1} {transcript file {} }

    ## if runing in tclsh the command 'transcript' is not preset
    #if {$::CMD_ARG_SIMVENTCL == 1} {transcript file $name }
}

############################# Xcelium simu compile functions #####################
# the Xilinx logs are generated when calling the xilinx compile script fpga.sh
set XMCMPL_XILINXLOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.compile_xilinx.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log; cp -f xmvhdl.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvhdl.log; cp -f xmvlog.log $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.xmvlog.log 2>/dev/null "
# xilinx simulation exported xcelium .sh script compile command
proc suxil {args} {
    puts_debug2 "==============config_settings_xcelium::suxil $args =================\n"

    # add stdout redirect and rtl log concatenate to running log
    set compile_command "$::REDIRECTSTD {*}$args [subst $::XMCMPL_XILINXLOG]"
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

# TB/TC compile log aggreagating to single file
#set XMCMPL_LOG " 2>&1 | tee compile.log; cat .tmp_simu_log >> xmvlog.log 2>/dev/null "
set XMCMPL_LOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log  2>/dev/null "

# set xmvlog verilog/sv compile options
set XMVLOG_OPTS "$REDIRECTSTD xmvlog -work fpga -64bit -messages -logfile $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log -update "
# verilog compile command
proc suvlog {args} {
    puts_debug2 "==============config_settings_vlog::suvlog $args =================\n"

    set compile_command "$::XMVLOG_OPTS {*}$args "
    if {$::CMD_ARG_SIMVENTCL == 0} {
        # Linux bash use
        append compile_command " $::XMCMPL_LOG "}

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
        puts "xmvlog Compile ERROR !"
        # exit compile
        return -level 2 -code error
    }

    return;
}

# set xmvhdl compile options
set XMVHDL_OPTS "$REDIRECTSTD xmvhdl -work fpga -64bit -messages -relax -logfile $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log -update "
# vhdl compile command
proc suvhdl {args} {
    puts_debug2 "==============config_settings_vlog::suvhdl $args =================\n"

    set compile_command "$::XMVHDL_OPTS {*}$args "
    if {$::CMD_ARG_SIMVENTCL == 0} {
        # Linux bash use
        append compile_command " $::XMCMPL_LOG "}    
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
        puts "xmvhdl Compile ERROR !"
        # exit compile
        return -level 2 -code error
    }

    return;
}

############################# Elaboration #####################
# set xmelab elaboration options
set XMELAB_OPTS "$REDIRECTSTD xmelab -64bit -relax -access +rwc -namemap_mixgen -messages  "
set XMELAB_LIBS " -libname xil_defaultlib -libname gtwizard_ultrascale_v1_7_16 -libname generic_baseblocks_v2_1_0 -libname axi_infrastructure_v1_1_0 -libname axi_register_slice_v2_1_28 -libname fifo_generator_v13_2_8 -libname axi_data_fifo_v2_1_27 -libname axi_crossbar_v2_1_29 -libname oran_radio_if_v3_0_0 -libname xlslice_v1_0_2 -libname lib_cdc_v1_0_2 -libname proc_sys_reset_v5_0_13 -libname util_vector_logic_v2_0_2 -libname xlconstant_v1_1_7 -libname axis_infrastructure_v1_1_0 -libname axis_data_fifo_v2_0_10 -libname gigantic_mux -libname axis_register_slice_v1_1_28 -libname axis_switch_v1_1_28 -libname lib_pkg_v1_0_2 -libname lib_fifo_v1_0_17 -libname lib_srl_fifo_v1_0_2 -libname axi_datamover_v5_1_30 -libname axi_msg_v1_0_9 -libname axi_mcdma_v1_1_9 -libname smartconnect_v1_0 -libname axi_vip_v1_1_14 -libname xxv_ethernet_v4_1_4 -libname axi_lite_ipif_v3_0_4 -libname axi_fifo_mm_s_v4_3_0 -libname xlconcat_v2_1_4 -libname timer_sync_1588_v1_2_4 -libname zynq_ultra_ps_e_vip_v1_0_14 -libname jtag_axi -libname axis_dwidth_converter_v1_1_27 -libname axi_protocol_converter_v2_1_28 -libname axi_clock_converter_v2_1_27 -libname blk_mem_gen_v8_4_6 -libname axi_dwidth_converter_v2_1_28 -libname axi_mmu_v2_1_26 -libname axi_sg_v4_1_16 -libname axi_dma_v7_1_29 -libname interrupt_control_v3_1_4 -libname axi_gpio_v2_0_30 -libname microblaze_v11_0_11 -libname lmb_v10_v3_0_12 -libname lmb_bram_if_cntlr_v4_0_22 -libname iomodule_v3_1_8 -libname util_reduced_logic_v2_0_4 -libname axis_clock_converter_v1_1_29 -libname axi_apb_bridge_v3_0_18 -libname axi_timer_v2_0_30 -libname dist_mem_gen_v8_0_13 -libname axi_quad_spi_v3_2_27 -libname axi_uart16550_v2_0_30 -libname common -libname ahb -libname innolink_fpga -libname memory -libname config -libname fpga -libname serdes -libname xilinx_vip -libname unisims_ver -libname unimacro_ver -libname secureip -libname xpm "
#set ::XELAB_INVOCATION "$REDIRECTSTD xelab  -s work.tb_elab $::TIMESCALEELAB_OPT $::TCTIMESCALEELAB -L UNISIMS_VER -L XILINXCORELIB_VER work.tb -debug all -log $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.elab.log "

# Without this, script execution halts during a regression
proc preSimCommand {} {
    puts_debug2 "==============config_settings_xcelium::preSimCommand================\n"

    if {$::CMD_ARG_SIMVENTCL == 1} { onbreak {resume} } 

    return;
}

############################# Sim database Optimization/elaboration always enabled for Excelium #############################

# Appended to simulation command if optimizations on or off
#set OPTIMIZATION_ON "work.tb_opt"
set OPTIMIZATION_ON ""
#set OPTIMIZATION_OFF "work.tb -novopt -suppress 12110"
set OPTIMIZATION_OFF ""

#set OPTIMIZATION_INVOCATION "vopt +acc tb -o tb_opt"
set OPTIMIZATION_INVOCATION "$::XMELAB_OPTS $::XMELAB_LIBS fpga.tb fpga.glbl -logfile $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.elab.log "

# Variable for list of libraries, e.g. unisim 
set EXTRA_LIBS ""
proc optimizeCommand {tcSubDir tcFileName tcTimeScale} {
    puts_debug2 "==============config_settings_xcelium::optimizeCommand================\n"
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
set XMSIM_OPTS "$REDIRECTSTD xmsim -64bit "
# Log and WLF to result_rtl
#set ::SIMULATOR_INVOCATION {vsim  -permit_unmatched_virtual_intf  -l "$CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.log" -wlf "$CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.wlf"}
#set ::SIMULATOR_INVOCATION "xmsim $XMSIM_OPTS worklib.tb -tcl -input xcelium_waveshmdb_creation.tcl"
set ::SIMULATOR_INVOCATION "$::XMSIM_OPTS fpga.tb -logfile $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.sim.log -tcl -input xcelium_waveshmdb_creation.tcl"

# simulation run command is empty becuse the "run" parameters now in the TCL file called from the simulaton call function simCommand
set SIM_RUN_COMMAND ""

proc simCommand {} {
    puts_debug2 "==============config_settings_xcelium::simCommand================\n"
    set simcmd $::SIMULATOR_INVOCATION

    # if {$::CMD_ARG_VIEW > 0} {
    #     append simcmd "  -input xcelium_waveshmdb_creation_gui.tcl"
    # } else                     {
    #     append simcmd "  -input xcelium_waveshmdb_creation_cli.tcl"
    #     }

    # # waveform logging
    # if {$::CMD_ARG_WAVELOGGING > 0} {
    #     append simcmd " -wlf $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wlf "   } 

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
    puts_debug2 "==============config_settings_xcelium::generateSimTclFile TODO: fix================\n"

    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open xcelium_waveshmdb_creation.tcl w]

    puts     "Wave log .tcl prep"
    putf $fp "#generic settings for simulation"
    putf $fp "set severity_pack_assert_off {warning} "
    putf $fp "set pack_assert_off { std_logic_arith numeric_std } "

    # add wave logging parameters
    if {$::CMD_ARG_WAVELOGGING > 0} {            
        puts     "Wave log creation for xcelium for all signals .tcl prep"
        putf $fp "#wave log creation for xcelium for all signals .tcl prep"
        putf $fp "database -open -shm waveshmdb "
        putf $fp "probe -create -database waveshmdb -all -depth all -all -dynamic -memories -qda_max_elem all "
    } 

    # run simulation
    puts     "Run simulation until end .tcl prep"
    putf $fp "#run simulation until end"
    putf $fp "run "

    # Coverage reports saving TODO:fix
    if {$::CMD_ARG_COVERAGE > 0} {
        #puts stdout "Coverage report invocation .tcl prep"
        #putf $fp    "#Coverage report invocation .tcl prep"
        #puts stdout [subst $::COVERAGE_REPORT_INVOCATION]
        #putf $fp [subst $::COVERAGE_REPORT_INVOCATION]
        #puts stdout "\n"
        #puts stdout "Coverage database save invocation .tcl prep"  
        #putf $fp    "#Coverage database save invocation .tcl prep"  
        #puts stdout [subst $::COVERAGE_SAVE_INVOCATION]
        #putf $fp [subst $::COVERAGE_SAVE_INVOCATION]
        #puts stdout "\n"
        #puts stdout "Coverage .tcl prep complete\n"
    } else {
        puts stdout "No coverage selected.\n"
    }

    puts     "Close wave DB .tcl prep"
    puts $fp "#Close wave DB "
    putf $fp "database -close waveshmdb"    

    # exit simulation if not in GUI mode with simulator license use
    if {$::CMD_ARG_VIEW != 2} {
        puts     "Exit simulation .tcl prep"        
        putf $fp "#Exit simulation"
        putf $fp "exit"
    } 

    # exit simulation if running in not simulator vendor tcl and not in wave GUI with sim license use
    if {$::CMD_ARG_SIMVENTCL == 0 && $::CMD_ARG_VIEW != 2} {
        #puts     "Exit simulation .tcl prep"        
        #putf $fp "#exit simulation"
        #putf $fp "exit"
    }     

    close $fp

}

# Quit simulation without closing entire program 
global SIMULATOR_QUIT
# if running in terminal TCL interpreter then 'quit' command doesn't exist, 'quit' is only vsim TCL command
set SIMULATOR_QUIT "if {$::CMD_ARG_SIMVENTCL == 1} {
    #puts stdout \"Quiting simulator ...\"
    #quit -sim
    }"

############################ View Test Case Waveforms in GUI ######################################
#Xcelium doesn't support simulator CLI for waveforms viewing, only .tcl file can be used
proc view_wave_log {view_wave wave_do tcSubDir tcFileName} {
    puts_debug2 "==============config_settings_xcelium::view_wave_log================\n"
    global REGRESSION

    if { ![info exists REGRESSION]} {
        set REGRESSION no
    }

    # If not in regression, either exit, or reopen in viewer mode
    if [string equal -nocase $REGRESSION no] {
        eval $::SIMULATOR_QUIT
        if {$view_wave == 1} {
            #vsim -view $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.wlf

            # Waveform viewer
            if [file exists $wave_do] {
                #do $wave_do
            }
        } else {

            puts stdout "Not opening waveform in simulator.\n"
       }
    }
}

############################# Coverage options setup #############################
# Appended to simulation command if optimizations on or off
# in Xcelium optimization is always used, can't be disabled
set COVERAGE_PARAMS ""
#set COVERAGE_YES_PARAMS "+cover=bcefsx"
set COVERAGE_YES_PARAMS " "
set COVERAGE_NO_PARAMS " "
set COVERAGE_PARAMS $COVERAGE_YES_PARAMS
if {$::CMD_ARG_COVERAGE == 0} {set COVERAGE_PARAMS $COVERAGE_NO_PARAMS}

#set COVERAGE_ON "-coverage"
set COVERAGE_ON ""
set COVERAGE_OFF ""

# Called per testcase to save that simulation's coverage. TODO: fix
#set COVERAGE_REPORT_INVOCATION {coverage report -file "$CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.coverage_report.rep"}
set COVERAGE_REPORT_INVOCATION {}
#set COVERAGE_SAVE_INVOCATION {coverage save "$CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.cov" }
set COVERAGE_SAVE_INVOCATION {}

# Coverage merging and reporting functions for regression. Placed here for easy modification.
proc coverageMergeCmd {outFile inFile1 inFile2} {
   puts stdout "==============config_settings_xcelium::coverageMergeCmd TODO: fix================\n"
    #vcover merge -out $outFile $inFile1 $inFile2

    return
}
proc coverageReportCmd {outReport inCov} {
    puts stdout "==============config_settings_xcelium::coverageReportCmd TODO: fix================\n"
    #vcover report $inCov -file $outReport 

    return
}

