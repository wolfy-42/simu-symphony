#!/bin/bash

./ycc2rgb sent1.raw sent1_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short sent1_rgb.raw ~/Downloads/sent1.tif
./ycc2rgb sent2.raw sent2_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short sent2_rgb.raw ~/Downloads/sent2.tif

./ycc2rgb received1.raw received1_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received1_rgb.raw ~/Downloads/received1.tif
./ycc2rgb received2.raw received2_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received2_rgb.raw ~/Downloads/received2.tif

./ycc2rgb received3.raw received3_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received3_rgb.raw ~/Downloads/received3.tif
