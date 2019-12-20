# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-04
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Parses Vivado's 3rd party Xsim simulation scripts and imports them into simu.
#               The compile script is copied to a local file and modifed to be runnable
#               from with simu.
#               The elaborate script is parsed to extract the library arguments that must
#               be passed to the local xelab call (eg. -L microblaze). 
#
#               To get the simulation scripts from Vivado:
#                   -From within Vivado, set the simulator to Xsim.
#                   -From the TCL console, run: launch_simulation -scripts_only -absolute_path
#                       * absolute_path is critical, otherwise the sources will never be found.
#                   -The files of interest will be named something like: compile.sh, elaborate.shi, xsim.ini, *.prj.
#                   -The local copy of the compile script must be sourced from 'compile_all_xsim.tcl', see tc_vivado/tc_vivado_xsim.tcl.
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

# proc get_vivado_lib_args
# Description:  Parses elaborate.sh to determine required libraries.
#   Inputs:
#       elaborate_sh_path: Path to elaborate.sh file produced by Vivado.
proc get_vivado_lib_args {elaborate_sh_path} {
    set fp [open $elaborate_sh_path r]
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

# proc adjust_vivado_compile_sh
# Description:  Copies Vivado's compile.sh file to a local file and modifies it to
#               work with simu. Extracts the xvlog and xvhdl commands. Copies *.prj (parsed from compile.sh)
#               to comp_script_out's directory, and xsim.ini (passed as argument) to run/.
#   Inputs:
#       compile_sh_path: Path to compile.sh file produced by Vivado.
#       comp_script_out: Location where adjusted script will be saved.
#       vivado_xsim_ini: Location of xsim.ini which must be copied to run.
proc adjust_vivado_compile_sh {compile_sh_path comp_script_out vivado_xsim_ini} {
    # Copy xsim.ini to run/  and all *.prj to the tc subdir
    file copy -force $vivado_xsim_ini "./xsim.ini"

    set vivado_proj_list ""

    # Directory containing Vivado's do scripts.
    set sh_dir [file dirname $compile_sh_path]
    set fp [open $compile_sh_path r]

    # Vivado's xsim output is contained in .prj files that are called from compile.sh. The calls are
    # extracted in this loop and copied to a new compilation script. The .prj files are copied in
    # the subsequent foreach loop.
    set vivado_compile_data ""
    while {[gets $fp line] >= 0} {
        if {[regexp {^ExecStep\s} $line]} {
            # Replace Vivado's ExecStep with a tcl exec. >&@ is to get log data.
            set mod_line [string map {ExecStep {exec >&@stdout}} $line]
            set mod_line [regsub {\s2>.*$} $mod_line {}]
            # Add any .prj files to list of files to be copied. Contains the "-prj " string, it's stripped later.
            lappend vivado_proj_list [regexp -inline {\-prj\s\S*} $mod_line]
            # Add path to tc subdir before project path in the xelab calls (by default they assumed to be in the CWD).
            set mod_line [regsub {\-prj\s*} $mod_line "-prj [file dirname $comp_script_out]/"]
            append vivado_compile_data "$mod_line\n"
        }
    }
    close $fp

    # Copy all .prj files to the comp_script_out directory.
    foreach prj $vivado_proj_list {
        # Strip "-prj " from beginning of prj, the above regexp doesn't exlude this.
        set prj [regsub {\-prj\s} $prj {}]
        # Above puts  "{}" around the match, remove them.
        set prj [string trim $prj "\{\}"]
        file copy -force [file dirname $compile_sh_path]/$prj [file dirname $comp_script_out]/[file tail $prj]

        # del_script_line, mod_script, and add_script_line could be used on individual project files
        # here.
        # Remove uart_rcvr_wrapper compilation line, a modified version is supplied that uses the
        # sim_management_pkg.
        del_script_line [file dirname $comp_script_out]/[file tail $prj] {.*uart_rcvr_wrapper\.v.*}
        # See import_vivado_vsim.tcl for examples.
    }

    set fp [open $comp_script_out w]
    puts $fp $vivado_compile_data
    close $fp

    # del_script_line, mod_script, and add_script_line could be used on the compile script here.
    # See import_vivado_vsim.tcl for examples.
}

# proc get_vivado_glbl_design_unit
# Description:  Vivado vivado includes a glbl design unit that must be run in xsim. Typically this would be in
#               xil_defaultlib (xil_defaultlib.glbl). This function searches for the glbl unit that Vivado's sh
#               scripts, and returns it. 
#               Ie. the return would typically be: xil_defaultlib.glbl
#   Inputs:
#       elaborate_sh_path: Path to elaborate.sh file produced by Vivado.
proc get_vivado_glbl_design_unit {elaborate_sh_path} {
    set fp [open $elaborate_sh_path r]
    set elab_data [read $fp]
    close $fp

    # Return the glbl design unit
    set glbl_design_unit [regexp -all -inline {\S*glbl} $elab_data]

    return $glbl_design_unit
}
