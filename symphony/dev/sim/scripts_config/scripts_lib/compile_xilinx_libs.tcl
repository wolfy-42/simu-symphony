# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-06
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : Compiles Xilinx functional simulation libraries (unisim, unisim_ver, unimacro, etc).
#               This must be run from Vivado with vsim in $PATH.
#
#               Usage:
#                   vivado -mode tcl -source ./scripts_lib/compile_xilinx_libs.tcl -tclargs [ip path=<output_location>]
#
#                   The default path is xsimlib, an alternate may be specified with path=<path>.
#                   The default is to not compile ip. Passing "ip" causes all ip to be compiled.
#
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

# ----------------------------------------------------------------------//
# DO NOT EDIT
# ----------------------------------------------------------------------//

set output_dir xsimlib
set compile_all_ip 0
# Get options passed through argv
foreach arg [lindex $::argv 0] {
    if {$arg eq "ip"} {
        set compile_all_ip 1
    }

    if {[regexp {^path=} $arg]} {
        set output_dir [regsub {^path=} $arg {}]
    }
    puts $arg
}

# Re-create directory where libraries will be compiled to.
# ~270 MB
if [file exists "xsimlib"] { 
    file delete -force "xsimlib" 
}
file mkdir "xsimlib"

puts stdout "Compiling Xilinx simulation libraries to ./xsimlib. This may take a few minutes."

if {$compile_all_ip} {
    compile_simlib -directory $output_dir -simulator questa
} else {
    # Compiles behavioural simulation libraries.
    # Note this only compiles unisim. The other library is simprim which is meant for post-route timing simulation.
    # Unisim is for functional simulation and a fraction the size of simprim.
    compile_simlib -directory $output_dir -simulator questa -library unisim -no_ip_compile
}

puts stdout "Finished compiling."
puts stdout "==================================================================="
puts stdout "IF modelsim.ini IS NOT UPDATED WITH THE JUST PRE-COMPILED LIBRARIES, THEY SHOULD BE ADDED TO sim/scripts_config/config_precompiled_lib_list.tcl \
            SO THEY ARE MAPPED INTO SIMULATIONS. The following lines can be copy and pasted into config_precompiled_lib_list.tcl:"

puts stdout "========= COPY BELOW HERE ========================================="
set lib_list [glob -directory $output_dir -types d "*"]
foreach lib $lib_list {
    puts -nonewline stdout "lappend vsim_precompiled_lib_list \""
    puts stdout "[file tail $lib] $lib\""
}
puts stdout "========= COPY ABOVE HERE ========================================="
