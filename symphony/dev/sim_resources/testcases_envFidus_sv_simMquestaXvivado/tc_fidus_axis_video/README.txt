//--------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project       : simu
// Author        : Jacob von Chorus
// Created       : 2018-06-22
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : README.txt
// Updated       : date / author - comments
//--------------------------------------------------------------------//

This testcase directory contains a sample testcase that uses the AXI4-Stream Video BFM. The testcase creates several
video frames in the sink BFM, transmits them to the source BFM through a direct connection, and compares them for
equality. Colourspace, bitdepth, subsampling, and pixels per clock are configurable in tc_vidgen.sv.

The video frames, sent and received, are written to file as raw pixel dumps. The raw2tiff utility, part of libtiff,
converts these raw pixel dumps to .tif image files for viewing. See to_tiff.sh for reference. This utility assumes RGB
images. If the video frame's colourspace was YCC, then run ycc2rgb on the raw file before raw2tiff. See to_tiff_ycc.sh
for reference. The source for ycc2rgb is found in ycc2rgb.c. The utility uses Rec.601 coefficients.
