# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-04
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Parses Vivado's 3rd party Questa simulation scripts and imports them into simu.
#               The compile script is copied to a local file and modifed to be runnable
#               from with simu.
#               The elaborate script is parsed to extract the library arguments that must
#               be passed to vsim (eg. -L microblaze). 
#
#               To get the simulation scripts from Vivado:
#                   -From within Vivado, set the simulator to Questa.
#                   -DO NOT precompile the simulation libraries. If any exist, delete them
#                       from project/project.cache. Otherwise Vivado will export incomplete scripts.
#                   -From the TCL console, run: launch_simulation -scripts_only -absolute_path
#                       * absolute_path is critical, otherwise the sources will never be found.
#                   -The files of interest will be named something like: tb_compile.do and tb_elaborate.do.
#                   -The local copy of the compile script must be sourced from 'compile_all_vsim.tcl', see tc_vivado/tc_vivado_vsim.tcl.
#
#               Compiling the simulation libraries:
#                   Before running an vivado testcase, Xilinx's simulation libraries must be precompiled within simu. These
#                   will be written to xsimlib.
#                   Run: vivado -mode tcl -source ./scripts_lib/compile_xilinx_libs.tcl
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

# proc get_vivado_lib_args
# Description:  Parses elaborate.do to determine required libraries.
#   Inputs:
#       elaborate_do_path: Path to elaborate.do file produced by Vivado.
proc get_vivado_lib_args {elaborate_do_path} {
    set fp [open $elaborate_do_path r]
    set elab_data [read $fp]
    close $fp

    # Returns a list of libraries required (eg. -L xpm)
    set lib_list [regexp -all -inline {\-L\s\w*} $elab_data]

    # Example of deleting a library.
    set lib_list [del_lib_arg $lib_list "xpm"]

    # Example of adding a library.
    set lib_list [add_lib_arg $lib_list "xpm"]

    return $lib_list
}

# proc adjust_vivado_compile_do
# Description:  Copies Vivado's compile.do file to a local file and modifies it to
#               work with simu.
#               The modifications remove creation of msim and work, simu handles these.
#               They also remove the absolute paths from the library locations in vmap,
#               and replace with msim/<library>.
#   Inputs:
#       compile_do_path: Path to compile.do file produced by Vivado.
#       comp_script_out: Location where adjusted script will be saved.
proc adjust_vivado_compile_do {compile_do_path comp_script_out} {
    # Copy vivado's compile script to a new location
    file copy -force -- $compile_do_path $comp_script_out

    # Don't create questa_lib/work, simu uses and creates msim/work.
    del_script_line $comp_script_out {vlib.*work}
    # Don't create quest_lib/msim, simu uses and creates msim.
    del_script_line $comp_script_out {vlib.*msim}
    # Replace /<path_to_vivado_scripts>/questa_lib/msim with msim.
    # The '0' means don't use line based matching (^/$ mean start and end of script, not of a line).
    mod_script $comp_script_out {\s\S*\/msim} " $::SIM_LIBRARY_DIRNAME" 0

    # Remove uart_rcvr_wrapper compilation line, a modified version is supplied that uses the
    # sim_management_pkg.
    del_script_line $comp_script_out {.*uart_rcvr_wrapper\.v.*}

    # Example of adding a newline
    add_script_line $comp_script_out "puts \"Vivado Compile Script\""
}

# proc get_vivado_glbl_design_unit
# Description:  Vivado vivado includes a glbl design unit that must be run in vsim. Typically this would be in
#               xil_defaultlib (xil_defaultlib.glbl). This function searches for the glbl unit that Vivado's do
#               scripts pass to Questa, and returns it. 
#               Ie. the return would typically be: xil_defaultlib.glbl
#   Inputs:
#       elaborate_do_path: Path to elaborate.do file produced by Vivado.
proc get_vivado_glbl_design_unit {elaborate_do_path} {
    set fp [open $elaborate_do_path r]
    set elab_data [read $fp]
    close $fp

    # Returns the glbl design unit.
    set glbl_design_unit [regexp -all -inline {\S*glbl} $elab_data]

    return $glbl_design_unit
}
