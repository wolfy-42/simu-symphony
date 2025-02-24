# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-06-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testbench for clock and reset BFMs.
#               Intentionally fails for demonstration purposes.
#
#               Command Line Options: uses modified scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: tc_fidus_axis_video.tcl
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_fidus_axis_video
set TCSUBDIR $TESTCASESDIR_FIDUS_SV/tc_fidus_axis_video
puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
append ::OPTIMIZATION_INVOCATION ""
append ::SIMULATOR_INVOCATION ""

# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE

# TCSUBDIR is unset at by TCCOMMON_TCCOMPILESIMULATE
set TCSUBDIR $TESTCASESDIR_FIDUS_SV/tc_fidus_axis_video
## Specific to tc_vidgen ##
# for RGB, set to 0
set YCC 0
set vid_width 640
set vid_height 480
if {$YCC == 1} {
    exec $TCSUBDIR/ycc2rgb $TCSUBDIR/result_rtl/sent1.raw $TCSUBDIR/result_rtl/sent1_rgb.raw
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/sent1_rgb.raw $TCSUBDIR/result_rtl/sent1.tif
    exec $TCSUBDIR/ycc2rgb $TCSUBDIR/result_rtl/sent2.raw $TCSUBDIR/result_rtl/sent2_rgb.raw
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/sent2_rgb.raw $TCSUBDIR/result_rtl/sent2.tif

    exec $TCSUBDIR/ycc2rgb $TCSUBDIR/result_rtl/received1.raw $TCSUBDIR/result_rtl/received1_rgb.raw
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/received1_rgb.raw $TCSUBDIR/result_rtl/received1.tif
    exec $TCSUBDIR/ycc2rgb $TCSUBDIR/result_rtl/received2.raw $TCSUBDIR/result_rtl/received2_rgb.raw
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/received2_rgb.raw $TCSUBDIR/result_rtl/received2.tif

    exec $TCSUBDIR/ycc2rgb $TCSUBDIR/result_rtl/received3.raw $TCSUBDIR/result_rtl/received3_rgb.raw
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/received3_rgb.raw $TCSUBDIR/result_rtl/received3.tif
} else {
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/sent1.raw $TCSUBDIR/result_rtl/sent1.tif
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/sent2.raw $TCSUBDIR/result_rtl/sent2.tif

    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/received1.raw $TCSUBDIR/result_rtl/received1.tif
    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/received2.raw $TCSUBDIR/result_rtl/received2.tif

    exec raw2tiff  -w $vid_width -l $vid_height -p rgb -b 3 -d short $TCSUBDIR/result_rtl/received3.raw $TCSUBDIR/result_rtl/received3.tif
}
