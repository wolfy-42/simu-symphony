# ---------------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2024-07-19
# ---------------------------------------------------------------------------//
# ---------------------------------------------------------------------------//
# Description   : Xilinx Unified Vitis HLS environment configuration functions and variables
#     IMPORTANT : Tool revision being tested with is listed in the build
#
# Updated       : yyyy-mm-dd / name - comment
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW WTIH SIMULATOR SPECIFIC COMMANDS
# --------------------------------------------------------------------//

puts_debug1 "==============config_settings_xhls.tcl================\n"

# command for redirect to stdout - Xilinx HLS is executed in bash shell and 
# the logs and error pipes redirect is always required
set REDIRECTSTDHLS " >&@stdout "

# Current test-case location, evaluated later during last step of execution (curly braces)
# global declaration is needed for regression runs
#global TCSUBDIRHLS
global CURRENT_TCSUBDIRHLS
set CURRENT_TCSUBDIRHLS {$::TCSUBDIR}
#global TCFILENAMEHLS
global CURRENT_TCFILENAMEHLS
set CURRENT_TCFILENAMEHLS {$::TCFILENAME}


##################### Text logs clearing ###########################
# proc text_logs_init {}
# Purpose: Procedure which ensures a fresh compile/simulation logs
# Inputs none. - Uses the global variables for testcase name and the module folder name.
# Outputs: none.
proc hls_text_logs_init {} {
    puts_debug2 "==============config_settings_xhls::hls_text_logs_init================\n"

    # delete old logs
    puts "Delete old logs..." 
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.cppsim.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.csynth.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.cosim.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.export.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.parse.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_create.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_del.log]
    file delete -force [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_tbtc.log]

    #TODO add all

    puts "Deleting old logs completed." 

}


##################### TB/TC pats soterd in a file for Vitis to access ###########################
# proc autogenerate_simu_paths {}
# Purpose: Procedure storing the TB/TC paths in a file which Vitis can use when executing
# Inputs: none - Uses the global variables for testcase name and the module folder name.
# Outputs: none. 
proc autogenerate_simu_paths {} {
    puts_debug2 "==============config_settings_xhls::autogenerate_simu_paths================\n"

    cd $::HLSSCRIPTSDIR

    # create the project deleting tcl script
    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open autogen_simu_paths.tcl w]     
    puts     "Generate TB/TC paths TCLfile."
    putf $fp "puts \"==============autogen_simu_paths.tcl================ \" "
    putf $fp "#Auto-generated TB/TC path in a TCL file to be used by Vitis project creation TCL script."
    putf $fp "set TCFILENAME $::TCFILENAME"
    putf $fp "set TCSUBDIR $::TCSUBDIR"
    putf $fp "set RUNDIR $::RUNDIR"

    close $fp

    cd $::RUNDIR

    puts "----------> TB/TC paths file autogen_simu_paths.tcl generated successfully ...............\n"

}


##################### Fresh HLS project ###########################
# Delete the old HLS project
set HLSDEL_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_del.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_del.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proc ensure_fresh_proj {}
# Purpose: Procedure which ensures a fresh project libraries by deleting the old proejct and recreating it from scripts
# Inputs: none - Uses the global variables for testcase name and the module folder name.
# Outputs: none. 
proc hls_ensure_fresh_proj {} {
    puts_debug2 "==============config_settings_xhls::hls_ensure_fresh_proj================\n"

    cd $::HLSSCRIPTSDIR

    # create the project deleting tcl script
    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open autogen_proj_delete.tcl w]     
    puts     "Generate project delteing TCLfile."
    putf $fp "puts \"==============autogen_proj_delete.tcl================ \" "
    putf $fp "#Auto-Generateed project deleting TCL file "
    putf $fp "set SCRIPTSDIR [pwd]"
    putf $fp "source proj_paths.tcl"
    putf $fp "cd \$::HLSPROJDIR_FROMSCRIPTS"   
    putf $fp "puts \"Deleting project ............\" "   
    putf $fp "delete_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME"   
    putf $fp "exit"   
    putf $fp "cd \$::SCRIPTSDIR"   
    putf $fp "puts \"Back to scripts folder..............\" "   
    close $fp


    # execute the project deleting tcl script
    puts stdout "HLS Project Deleting..."
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl autogen_proj_delete.tcl  $::HLSDEL_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        puts "config_settings_xhls::hls_ensure_fresh_proj - Deleting Project ERROR !"
        # exit compile
        puts "cd from builds/scripts/<project> to sim/run folder"
        #eval exec $::REDIRECTSTDHLS pwd
        cd $::RUNDIR
        return -level 2 -code error
    } 

    cd $::RUNDIR

    puts "----------> Project deleted successfully ...............\n"

}


##################### text logs ###########################
# proc hls_transcript_reset {} command will close the current log file. The next command will open a new log file. If it has
# the same name as an existing file, it will replace the previous one.
# We clear the transcript here so that the next commands will not appear in the previous log file.
proc hls_transcript_reset {} {
    puts_debug2 "==============config_settings_xhls::hls_transcript_reset================\n"

    puts stdout "Transcript reset not relevant."
}

##################### text logs ###########################
# proc generateTcPathsTclFile {} command will create the TCL script with the path to the TC/TB
proc generateTcPathsTclFile {} {
    puts_debug2 "==============config_settings_xhls::generateTcPathsTclFile================\n"


    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open $::HLSSCRIPTSDIR/autogen_simu_paths.tcl w]
      
    puts     "Generate TC path in a TCL file to be used by Vitis project creation TCL script."
    putf $fp "puts \"==============autogen_simu_paths.tcl================ \" "
    putf $fp "#Generate TC path in a TCL file to be used by Vitis project creation TCL script."
    putf $fp "set TCFILENAME $::TCFILENAME"
    putf $fp "set TCSUBDIR $::TCSUBDIR"
    putf $fp "set RUNDIR $::RUNDIR"   

    close $fp

    return

}


##################### HLS project creation ###########################
# HLS project creation 
set HLSPRJ_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_create.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_create.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proj create function
proc hls_proj_create {} {
    puts_debug2 "==============config_settings_vlog::hls_proj_create =================\n"

    puts stdout "HLS Project Creation..."
    cd $::HLSSCRIPTSDIR 
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl proj_create.tcl $::HLSPRJ_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        puts "config_settings_vlog::hls_proj_create - Creating Project ERROR !"
        puts "cd from builds/vitis/<project> to sim/run folder"
        cd $::RUNDIR
        return -level 2 -code error
    }

    cd $::RUNDIR

    puts "----------> Project created successfully ...............\n"

}

##################### HLS project creation ###########################
# HLS add TC and TC to project 
set HLSPRJTBTC_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_tbtc.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.prj_tbtc.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proj add TB/TC function
proc hls_proj_tbtc {} {
    puts_debug2 "==============config_settings_vlog::hls_proj_tbtc =================\n"

    puts stdout "HLS Project adding TB & TC ..."
    cd $::HLSSCRIPTSDIR 
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl simu_create_tbtc.tcl $::HLSPRJTBTC_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        puts "config_settings_vlog::hls_proj_tbtc - Adding TB&TC ERROR !"
        puts "cd from builds/vitis/<project> to sim/run folder"
        cd $::RUNDIR
        return -level 2 -code error
    }

    cd $::RUNDIR

    puts "----------> Project added TB & TC successfully ...............\n"

}

# # HLS TB/TC files added to the project 
# ##set VSCMPL_LOG " 2>&1 | tee compile.log; cat .tmp_simu_log >> xmvlog.log 2>/dev/null "
# set HLSPROJ_ADDRTL_LOG " 2>&1 | tee $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log; exec cat $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.tmp_simu_log.log >> $::CURRENT_TCSUBDIR/result_rtl/$::CURRENT_TCFILENAME.cmpl.log  2>/dev/null "

# set HLSPROJ_ADDRTL_OPTS "$REDIRECTSTDHLS vlog -incr "
# # proj create function
# proc hlsproj_addrtl{args} {
#     puts_debug2 "==============config_settings_vlog::hlsproj_create =================\n"

# https://docs.amd.com/r/en-US/ug1399-vitis-hls/vitis-v-and-vitis-run-Commands
# v++ -c --mode hls --config ./dct/hls_config.cfg --work_dir dct
 

# Where:

#     --config specifies a config file with the compiler directives for the build, and to configure the simulator for the run
#     --work_dir provides a work directory to build the component
#     Tip: When creating an HLS component from the command line, the --work_dir specifies the HLS component folder, and the parent folder of the --work_dir becomes the workspace for launching the Vitis IDE.

# The contents of a configuration file can vary, but for synthesis the dct HLS component requires the following commands in the hls_config.cfg file:

# part=xczu9eg-ffvb1156-2-e

# [hls]
# syn.file=./src/dct.cpp
# syn.top=dct
# flow_target=vitis
# clock=8ns
# clock_uncertainty=12%
# syn.output.format=rtl
# syn.directive.pipeline=dct_2d II=4

# Important: If your HLS configuration file uses platform= instead of part= then you must also specify freqhz= instead of clock= as shown here to change the default clock frequency of the platform.

# The success of the synthesis command largely depends on the contents of the configuration file. There are a few key required elements, and then there are a number of options that you can specify. From the config file provided above, the required elements for synthesis are the part, syn.file, and syn.top. The flow_target, clock, and clock_uncertainty are not required except to override the default values. The syn.directive.xxx commands are used to provide specific optimization to the synthesis of the function. 

# ----
# part=xcvu11p-flga2577-1-e

# [hls]
# clock=8
# flow_target=vitis
# syn.file=../../src/dct.cpp
# syn.top=dct
# tb.file=../../src/out.golden.dat
# tb.file=../../src/in.dat
# tb.file=../../src/dct_test.cpp
# tb.file=../../src/dct_coeff_table.txt
# syn.output.format=xo
# clock_uncertainty=15%


# syn.cflags=-I../../src/
# syn.file_cflags=../../src/dct.cpp,-I../../src/
# syn.file_csimflags=../../src/dct.cpp,-Wno-unknown-pragmas
# tb.cflags=-Wno-unknown-pragmas

# syn.compile.pragma_strict_mode
#     Enable errors instead of warnings for unrecognized and improper pragma syntax.

#     syn.compile.pragma_strict_mode=1






#     return;
# }

##################### Run Cpp HLS simulation ###########################
# command to run simulation
set HLSCPPSIMLOG_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.cppsim.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.cppsim.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proc simu_run_cppsim {}
# Purpose: Creates a TCL script and runs Cpp simulation
# Inputs: none - Uses the global variables for testcase name and the module folder name.
# Outputs: none. 
proc simu_run_cppsim {} {
    puts_debug2 "==============config_settings_xhls::simu_run_cppsim================\n"

    cd $::HLSSCRIPTSDIR

    # create the project Cpp simulation tcl script
    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open autogen_simu_run_cppsim.tcl w]     
    puts     "Generate Cpp simulating TCLfile."
    putf $fp "puts \"==============autogen_simu_run_cppsim.tcl================ \" "
    putf $fp "#Auto-Generated Cpp simulating TCL file "

    putf $fp "set SCRIPTSDIR [pwd]"
    putf $fp "source proj_paths.tcl"
    putf $fp "cd \$::HLSPROJDIR_FROMSCRIPTS"   

    putf $fp "puts \"Running Cpp simulation .............\" "   
    putf $fp "open_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME" 
    putf $fp "open_solution \"solution1\" -flow_target vivado" 
    #config_compile -pipeline_loops 30
    #config_csim [OPTIONS]
    putf $fp "csim_design" 
    putf $fp "write_ini \$::SCRIPTSDIR/backup_simu_config_cppsim.cfg -all=true" 

    putf $fp "cd \$::SCRIPTSDIR"   
    putf $fp "puts \"Back to scripts folder..............\" "   
    close $fp


    # execute the project deleting tcl script
    puts stdout "HLS Project Deleting......................."
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl autogen_simu_run_cppsim.tcl  $::HLSCPPSIMLOG_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        #
        puts "config_settings_xhls::simu_run_cppsim - Cpp simulation ERROR !"
        # exit compile
        puts "cd from builds/scripts/<project> to sim/run folder"
        cd $::RUNDIR
        return -level 2 -code error
    } 

    cd $::RUNDIR

    puts "----------> Cpp simulation completed successfully ...............\n"

}


##################### Run Synth HLS  ###########################
# command to run simulation
set HLSSYNTHLOG_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.csynth.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.csynth.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proc simu_run_synth {}
# Purpose: Creates a TCL script and runs HLS Cpp sythesis
# Inputs: none - Uses the global variables for testcase name and the module folder name.
# Outputs: none. 
proc simu_run_csynth {} {
    puts_debug2 "==============config_settings_xhls::simu_run_csynth================\n"

    cd $::HLSSCRIPTSDIR

    # create the project synthesis tcl script
    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open autogen_simu_run_csynth.tcl w]     
    puts     "Generate Cpp simulating TCLfile."
    putf $fp "puts \"==============autogen_simu_run_csynth.tcl================ \" "
    putf $fp "#Auto-Generated Cpp synthesis TCL file "

    putf $fp "set SCRIPTSDIR [pwd]"
    putf $fp "source proj_paths.tcl"
    putf $fp "cd \$::HLSPROJDIR_FROMSCRIPTS"   

    putf $fp "puts \"Running Cpp synthesis .............\" "   
    putf $fp "open_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME" 
    putf $fp "open_solution \"solution1\" -flow_target vivado" 
    putf $fp "csynth_design" 
    putf $fp "write_ini \$::SCRIPTSDIR/backup_simu_config_csynth.cfg -all=true" 

    putf $fp "cd \$::SCRIPTSDIR"   
    putf $fp "puts \"Back to scripts folder..............\" "   
    close $fp


    # execute the project sythesizing tcl script
    puts stdout "HLS Project Sythesizing................."
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl autogen_simu_run_csynth.tcl  $::HLSSYNTHLOG_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        #
        puts "config_settings_xhls::simu_run_csynth - Cpp synthesis ERROR !"
        # exit compile
        puts "cd from builds/scripts/<project> to sim/run folder"
        cd $::RUNDIR
        return -level 2 -code error
    } 

    cd $::RUNDIR

    puts "----------> Cpp synthesis completed successfully ...............\n"

}

##################### Run CoSim HLS  ###########################
# command to run simulation
set HLSCOSIMTHLOG_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.cosim.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.cosim.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proc simu_run_cosim {}
# Purpose: Creates a TCL script and runs HLS Cpp CoSimulation with third party HDL simulator like Modelsim like
# Inputs: none - Uses the global variables for testcase name and the module folder name.
# Outputs: none. 
proc simu_run_cosim {} {
    puts_debug2 "==============config_settings_xhls::simu_run_cosim================\n"

    cd $::HLSSCRIPTSDIR

    # create the project co-sim tcl script
    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open autogen_simu_run_cosim.tcl w]     
    puts     "Generate Cpp co-sim TCLfile."
    putf $fp "puts \"==============autogen_simu_run_cosim.tcl================ \" "
    putf $fp "#Auto-Generated Cpp co-simulation TCL file "

    putf $fp "set SCRIPTSDIR [pwd]"
    putf $fp "source proj_paths.tcl"
    putf $fp "cd \$::HLSPROJDIR_FROMSCRIPTS"   

    putf $fp "puts \"Running Cpp CoSimulation .............\" "   
    putf $fp "open_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME" 
    putf $fp "open_solution \"solution1\" -flow_target vivado" 
    #config_cosim [OPTIONS]
    putf $fp "cosim_design" 
    putf $fp "write_ini \$::SCRIPTSDIR/backup_simu_config_cosim.cfg -all=true" 

    putf $fp "cd \$::SCRIPTSDIR"   
    putf $fp "puts \"Back to scripts folder..............\" "   
    close $fp


    # execute the project sythesizing tcl script
    puts stdout "HLS Project CoSimulation................."
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl autogen_simu_run_cosim.tcl  $::HLSCOSIMTHLOG_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        #
        puts "config_settings_xhls::simu_run_cosim - CoSim synthesis ERROR !"
        # exit compile
        puts "cd from builds/scripts/<project> to sim/run folder"
        cd $::RUNDIR
        return -level 2 -code error
    } 

    cd $::RUNDIR

    puts "----------> Co-Simulation completed successfully ...............\n"

}


##################### Run Export HLS  ###########################
# command to run IP export
set HLSEXPORTLOG_LOG " 2>&1 | tee $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.export.log; exec cat $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.export.log >> $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log  2>/dev/null "

# proc simu_run_export {}
# Purpose: Creates a TCL script and runs HLS IP export 
# Inputs: none - Uses the global variables for testcase name and the module folder name.
# Outputs: none. 
proc simu_run_export {} {
    puts_debug2 "==============config_settings_xhls::simu_run_export================\n"

    cd $::HLSSCRIPTSDIR

    # create the project IP export tcl script
    # rpint to .tcl file
    proc putf {fp command} {
        puts $fp $command
    }
    set fp [open autogen_simu_run_export.tcl w]     
    puts     "Generate IP export TCL file."
    putf $fp "puts \"==============autogen_simu_run_export.tcl================ \" "
    putf $fp "#Auto-Generated IP export TCL file "

    putf $fp "set SCRIPTSDIR [pwd]"
    putf $fp "source proj_paths.tcl"
    putf $fp "cd \$::HLSPROJDIR_FROMSCRIPTS"   

    putf $fp "puts \"Running IP export .............\" "   
    putf $fp "open_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME" 
    putf $fp "open_solution \"solution1\" -flow_target vivado" 
    putf $fp "export_design -format ip_catalog " 
    putf $fp "write_ini \$::SCRIPTSDIR/backup_simu_export.cfg -all=true" 

    putf $fp "cd \$::SCRIPTSDIR"   
    putf $fp "puts \"Back to scripts folder..............\" "   
    close $fp


    # execute the project sythesizing tcl script
    puts stdout "HLS Project IP export................."
    catch {[eval exec $::REDIRECTSTDHLS vitis-run --mode hls --tcl autogen_simu_run_export.tcl  $::HLSEXPORTLOG_LOG ]} result 
    if {$result eq "child process exited abnormally"} {
        puts "-----------------------------------catch error--------------------------------"
        # concatenate the log file with this error log
        #
        puts "config_settings_xhls::simu_run_export - IP export ERROR !"
        # exit compile
        puts "cd from builds/scripts/<project> to sim/run folder"
        cd $::RUNDIR
        return -level 2 -code error
    } 

    cd $::RUNDIR

    puts "----------> IP export completed successfully ...............\n"

}


##################### Run Parse HLS  ###########################
# command to run logs parsing
set HLSPARSELOG_LOG "$::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.parse.log"

# proc parsing_hls_flow_status {}
# Purpose: Parsing the HLS flow log to extract every stage status 
# Inputs: none
# Outputs: none 
proc parsing_hls_flow_status {} {
    puts_debug2 "==============config_settings_xhls::parsing_hls_flow_status================\n"

    if [catch {open [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log]  r} fileId] {
        puts stderr "Could not open [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log] for reading"
    } else {

        # print in 3 places - two log files and screen
        proc putf {colour text_to_print} {
            # main log open for addition
            set bigLog [open [subst $::CURRENT_TCSUBDIRHLS/result_rtl/$::CURRENT_TCFILENAMEHLS.log] a]
            # parsing small log open for writing
            set parseLog [open [subst $::HLSPARSELOG_LOG] a]

            puts            "$colour $text_to_print  $::debug_colour_reset"
            puts $bigLog    $text_to_print
            puts $parseLog  $text_to_print

            close $bigLog
            close $parseLog

        }

        set tcName $::CURRENT_TCFILENAMEHLS.cpp
        # set splitPathElements [file split $logFileNameAndPath]
        # set path ""
        # for {set i 0} {$i < [expr [llength $splitPathElements] - 2]} {incr i 1} {
        #     set path [file join $path [lindex $splitPathElements $i]]
        # }
        # #if {[string match verilog $::LANGUAGE]} {
        # set tcName "[file join $path $tcName].sv"
        # #} else {
        # #    set tcName "[file join $path $tcName].vhd"
        # #}

        # flag for not completed
        set foundStatus false

        # default stage status is Not Found
        #set statsArray {
        #     { "Csim stage status       :" "not found" }
        #     { "Synth stage status      :" "not found" }
        #     { "CoSim stage status      :" "not found" }
        #     { "Export stage status     :" "not found" }
        #     { "Implement stage status  :" "not found" } 
        # }

        set statsArray(cppsim_functions) "NA" 
        set statsArray(cppsim_stage) "NA" 
        set statsArray(csynth_stage) "NA"
        set statsArray(cosim_functions_cpp) "NA"
        set statsArray(cosim_functions_rtl) "NA"
        set statsArray(cosim_stage) "NA"
        set statsArray(export_stage) "NA"
        set statsArray(impl_stage) "NA"
        

        set cosim_first_result_cpp 0
        # pars all status
        while {[gets $fileId line] >= 0} {

            #---------------------------
            #C++Sim stage parsing
            if [string match {*CSim done with 0 errors.*} $line] {
                set statsArray(cppsim_stage) "OK"
                #puts "ok\n"
            } 
            if [string match {*CSim done with 1 errors.*} $line] {
                set statsArray(cppsim_stage) "BAD"
                #puts "err\n"
            } 

            if [string match {*SIMULATION STATUS: PASS*} $line] {
                set statsArray(cppsim_functions) "PASS"
                #puts "ok\n"
            } 
            if [string match {*SIMULATION STATUS: FAIL*} $line] {
                set statsArray(cppsim_functions) "FAIL"
                #puts "err\n"
            } 

            #----------------------------
            #C-Synth stage parsing
             if [string match {*Finished Command csynth_design*} $line] {
                set statsArray(csynth_stage) "OK"
                #puts "ok\n"
            } 

            #C-Synt if BAD then it won't finish or bat timing/toher things - TBD to add for bad things

            #--------------------------
            #CoSim stage parsing
             if {[string match {*C/RTL co-simulation finished: PASS*} $line]} {
                set statsArray(cosim_stage) "OK"
                set cosim_first_result_cpp 1
                #puts "ok\n"
            } 
             if {[string match {*C/RTL co-simulation finished: FAIL*} $line]} {
                set statsArray(cosim_stage) "BAD"
                set cosim_first_result_cpp 1                
                #puts "ok\n"
            } 

            #CoSim Cpp functions parsing
            if {[string match {*SIMULATION STATUS: PASS*} $line] && $cosim_first_result_cpp == 0} {
                set statsArray(cosim_functions_cpp) "PASS"
                set cosim_first_result_cpp 1
                #puts "ok\n"
            } 
             if {[string match {*SIMULATION STATUS: FAIL*} $line] && $cosim_first_result_cpp == 0} {
                set statsArray(cosim_functions_cpp) "FAIL"
                set cosim_first_result_cpp 1                
                #puts "ok\n"
            } 

            #CoSim RTL functions parsing
            if {[string match {*SIMULATION STATUS: PASS*} $line] && $cosim_first_result_cpp == 1} {
                set statsArray(cosim_functions_rtl) "PASS"
                #set cosim_first_result_cpp 1
                #puts "ok\n"
            } 
             if {[string match {*SIMULATION STATUS: FAIL*} $line] && $cosim_first_result_cpp == 1} {
                set statsArray(cosim_functions_rtl) "FAIL"
                #set cosim_first_result_cpp 1                
                #puts "ok\n"
            }
           
            #---------------------------
            #Export stage parsing
             if [string match {*Finished Command export_design*} $line] {
                set statsArray(export_stage) "OK"
                #puts "ok\n"
            } 
           
            #Impelment stage parsing
            #  if [string match {*Finished Command export_design*} $line] {
            #     set statsArray(export_stage) "OK"
            #     puts "ok\n"
            # } 
           

        }

            proc putc {text_to_print varable} {

                if          {[string match $varable "NA"]} {
                putf $::debug_colour2   $text_to_print
                } elseif    {[string match $varable "OK"]} {
                putf $::green_colour    $text_to_print
                } elseif    {[string match $varable "PASS"]} {
                putf $::green_colour    $text_to_print
                } else      {
                putf $::red_colour      $text_to_print
            }

            }


            putf $::debug_colour1 ""
            putf $::debug_colour1 "open logs and parse stages status..."
            putf $::debug_colour1 "======================================================================"
            putc "1.  CppSim stage            : $statsArray(cppsim_stage)"              $statsArray(cppsim_stage) 
            putc "1.1 CppSim functions           - $statsArray(cppsim_functions)"       $statsArray(cppsim_functions) 
            putc "2.  CSynth stage            : $statsArray(csynth_stage)"              $statsArray(csynth_stage) 
            putc "3.  CoSim stage             : $statsArray(cosim_stage)"               $statsArray(cosim_stage) 
            putc "3.1 CoSim fucntions Cpp        - $statsArray(cosim_functions_cpp)"    $statsArray(cosim_functions_cpp) 
            putc "3.2 CoSim fucntions RTL        - $statsArray(cosim_functions_rtl)"    $statsArray(cosim_functions_rtl) 
            putc "4.  Export stage            : $statsArray(export_stage)"              $statsArray(export_stage) 
            putc "5.  Implement stage         : $statsArray(impl_stage)"                $statsArray(impl_stage) 





            # putf "1.1  CppSim functions           - $statsArray(cppsim_functions)"
            # putf "2.  CSynth stage            : $statsArray(csynth_stage)"
            # putf "3.  CoSim stage             : $statsArray(cosim_stage)"
            # putf "3.1  CoSim fucntions Cpp        - $statsArray(cosim_functions_cpp)"
            # putf "3.2  CoSim fucntions RTL        - $statsArray(cosim_functions_rtl)"
            # putf "4.  Export stage            : $statsArray(export_stage)"
            # putf "5.  Implement stage         : $statsArray(impl_stage)"
            # putf "======================================================================"
            # putf ""


    }
    return

}








# ############################# Simulator options setup #############################
# # set C++ CSim simulation options
# set HLS_CPPSIM_OPTS "$REDIRECTSTDHLS vsim  -permit_unmatched_virtual_intf "
# #set ::SIMULATOR_INVOCATION {vsim  -permit_unmatched_virtual_intf  -l "$tcSubDir/result_rtl/$tcFileName.log" -wlf "$tcSubDir/result_rtl/$tcFileName.wlf "}
# set HLS_CPPSIM_SIMULATOR_INVOCATION  "$VSSIM_OPTS  -l $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.log -do vsim_wavelog_coverage.tcl "
# #set SIMULATOR_INVOCATION  "$VSSIM_OPTS  -l $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.log  -wlf $CURRENT_TCSUBDIR/result_rtl/$CURRENT_TCFILENAME.wlf "

# # simulation run command is empty becuse the "run" parameters now in the TCL file called from the simulaton call function simCommand
# set HLS_CPPSIM_RUN_COMMAND ""

# # C++ CSim for C++ simulation
# proc hls_cppsim_simCommand {} {
#     puts_debug2 "==============config_settings_xhls::hls_cppsim_simCommand================\n"
   
# vitis-run --mode hls --csim --config ./dct/hls_config.cfg --work_dir dct

# }

# proc hls_cppsim_generateSimTclFile {} {
#     puts_debug2 "==============config_settings_xhls::hls_cppsim_generateSimTclFile================\n"

# Where:

#     --csim specifies the target for the run.
#     --config specifies a config file as indicated for synthesis, but includes C simulation specific requirements as shown below.
#     --work_dir provides a work directory to build the component as indicated for synthesis.

# The contents of a configuration file can vary, but for C simulation the config file requires the source files and top specified for synthesis, but also require test bench and input files, as well as csim configuration settings as explained in C-Simulation Configuration:

# part=xczu9eg-ffvb1156-2-e

# [hls]
# clock=8ns
# clock_uncertainty=12%
# flow_target=vitis
# syn.output.format=rtl
# syn.file=./src/dct.cpp
# syn.file=./src/dct.h
# syn.top=dct
# tb.file=./src/dct_coeff_table.txt
# tb.file=./src/dct_test.cpp
# tb.file=./src/in.dat
# tb.file=./src/out.golden.dat
# csim.clean=true
# csim.code_analyzer=false
# syn.directive.pipeline=dct_2d II=4

# Tip: Change csim.code_analyzer to true to enable the Code Analyzer as well as simulation. 


# }

# # RTL CoSim for simulation
# proc hls_cosim_simCommand {} {
#     puts_debug2 "==============config_settings_xhls::hls_cosim_simCommand================\n"
   


# }

# proc hls_cosim_generateSimTclFile {} {
#     puts_debug2 "==============config_settings_xhls::hls_cosim_generateSimTclFile================\n"
# vitis-run --mode hls --impl --config ./dct/hls_config.cfg --work_dir dct

# vitis-run --mode hls --cosim --config ./dct/hls_config.cfg --work_dir dct
# The contents of the configuration file required for C/RTL Co-Simulation include the following:

# part=xczu9eg-ffvb1156-2-e

# [hls]
# clock=8ns
# clock_uncertainty=12%
# flow_target=vitis
# syn.output.format=rtl
# syn.file=./src/dct.cpp
# syn.file=./src/dct.h
# syn.top=dct
# tb.file=./src/dct_coeff_table.txt
# tb.file=./src/dct_test.cpp
# tb.file=./src/in.dat
# tb.file=./src/out.golden.dat
# syn.directive.pipeline=dct_2d II=4
# cosim.enable_dataflow_profiling=true
# cosim.enable_fifo_sizing=true
# cosim.trace_level=port
# cosim.wave_debug=true


#     auto
#     vcs
#     modelsim
#     riviera
#     isim
#     xsim
#     ncsim
#     xceilum

# cosim.tool=modelsim


# Determines the level of waveform trace data to save during C/RTL co-simulation.

#     none does not save trace data. This is the default.
#     all results in all port and signal waveforms being saved to the trace file.
#     port only saves waveform traces for the top-level ports.
#     port_hier save the trace information for all ports in the design hierarchy.

# cosim.trace_level=port


# cosim.rtl
#     Specifies either Verilog or VHDL as the language to use for C/RTL co-simulation. The default is Verilog.

#     cosim.rtl=vhdl

# cosim.random_stall
#     Enable random stalling of top level interfaces during co-simulation.

#     cosim.random_stall=true

# cosim.trace_level

#     Determines the level of waveform trace data to save during C/RTL co-simulation.

#         none does not save trace data. This is the default.
#         all results in all port and signal waveforms being saved to the trace file.
#         port only saves waveform traces for the top-level ports.
#         port_hier save the trace information for all ports in the design hierarchy.

#     cosim.trace_level=port
    
# cosim.wave_debug
#     Opens the Vivado simulator GUI to view waveforms and simulation results. Enables waveform viewing of all processes in the generated RTL, as in the dataflow and sequential processes. This option is only supported when using Vitis simulator for co-simulation by setting cosim.tool=xsim. See Viewing Simulation Waveforms for more information.

#     cosim.wave_debug=true



# ----------------

# vitis-run --mode hls --package --config ./dct/hls_config.cfg --work_dir dct
# The contents of the configuration file required to export the package IP or XO include the following: 
# part=xcvu9p-flga2104-2-i

# [hls]
# syn.file=/group/xcoswmktg/randyh/rigel-tests/03-Vitis_HLS/reference-files/src/dct.cpp
# syn.top=dct
# syn.output.format=xo



# }















# # Quit simulation without closing entire program 
# global HLS_SIMULATOR_QUIT
# # if running in terminal TCL interpreter then 'quit' command doesn't exist, 'quit' is only vsim TCL command
# set HLS_SIMULATOR_QUIT "if {$::CMD_ARG_SIMVENTCL == 1} {
#     puts stdout \"Quiting simulator ...\"
#     quit -sim
#     }"


# ############################ View Test Case Waveforms in GUI ######################################
# proc hls_cosim_view_wave_log {view_wave wave_do tcSubDir tcFileName} {
#     puts_debug2 "==============config_settings_xhls::hls_cosim_view_wave_log================\n"
 
# }

# ############################# Coverage options setup #############################
# # TODO: add this function


