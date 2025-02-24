//---------------------------------------------------------------------------//
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project     : SIMU
// Author      : Jacob von Chorus
// Created     : June 26, 2018
// Description : Convert raw YCC frame to raw RGB frame as output by AXI4-Stream
//                  Video BFM.
// Usage       : ycc2rgb <ycc.raw> <rgb.raw>
// Compilation : gcc -o ycc2rgb ycc2rgb.c
//---------------------------------------------------------------------------//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

double Kr = 0.299; // Rec.601 coefficients
double Kg = 0.587; 
double Kb = 0.114;
double max_val = 65535; // 2^16 - 1

int main(int argc, char **argv)
{
    FILE *fi, *fo;
    unsigned short ycbcr[3];
    double y, cb, cr;
    double r, g, b;
    unsigned short rgb[3];

    if (argc != 3) {
        printf("Usage: ycc2rgb <input.raw> <output.raw>\n");
        return 1;
    }

    fi = fopen(argv[1], "r");
    fo = fopen(argv[2], "wb");
    if (!fi || !fo) {
        printf("Unable to open input and/or output.\n");
        return 1;
    }


    while (fread(ycbcr, sizeof(unsigned short), 3, fi) == 3) { /* read until EOF */
        y = (double)ycbcr[0] / max_val;
        cb = (double)ycbcr[1] / max_val;
        cr = (double)ycbcr[2] / max_val;

        cb = (cb * 2.0) - 1.0; /* cb/cr: [-1.0, 1.0] */
        cr = (cr * 2.0) - 1.0;
        
        r = y + cr*(1 - Kr);       // YCC -> RGB
        g = y - cb*(1 - Kb)*(Kb/Kg) - cr*(1 - Kr)*(Kr/Kg);
        b = y + cb*(1 - Kb);

        r = r * max_val; // Normalize back to 2^COMP_WIDTH - 1
        g = g * max_val;
        b = b * max_val;

        rgb[0] = (unsigned short)r; 
        rgb[1] = (unsigned short)g; 
        rgb[2] = (unsigned short)b; 

        fwrite(rgb, sizeof(unsigned short), 3, fo);
    }

    fclose(fi);
    fclose(fo);

    return 0;
}
