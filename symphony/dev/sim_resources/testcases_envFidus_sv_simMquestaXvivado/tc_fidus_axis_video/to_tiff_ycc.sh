#!/bin/bash

pushd $1

../ycc2rgb sent1.raw sent1_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short sent1_rgb.raw ./sent1.tif
../ycc2rgb sent2.raw sent2_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short sent2_rgb.raw ./sent2.tif

../ycc2rgb received1.raw received1_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received1_rgb.raw ./received1.tif
../ycc2rgb received2.raw received2_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received2_rgb.raw ./received2.tif

../ycc2rgb received3.raw received3_rgb.raw
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received3_rgb.raw ./received3.tif

popd
