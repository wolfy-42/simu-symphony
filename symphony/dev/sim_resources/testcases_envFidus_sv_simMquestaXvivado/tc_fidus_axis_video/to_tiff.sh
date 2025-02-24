#!/bin/bash

pushd $1

raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short sent1.raw ~/Downloads/sent1.tif
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short sent2.raw ~/Downloads/sent2.tif

raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received1.raw ~/Downloads/received1.tif
raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received2.raw ~/Downloads/received2.tif

raw2tiff  -w 640 -l 480 -p rgb -b 3 -d short received3.raw ~/Downloads/received3.tif

popd
