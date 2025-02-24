#ifndef SIM_MANAGEMENT_PKG_h
#define SIM_MANAGEMENT_PKG_h

//--------------------------------------------------------------------//
// Copyright (C) 2018 Fidus Systems Inc.
//
// Project      : V_VIDEO_BIST
// Author       : Jacob von Chorus
// Date         : July 25, 2018
// Description  : Simulation management package, pass/fail printing.
//--------------------------------------------------------------------//

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <stdarg.h>
#include <ap_int.h>

class SimManagementPkg
{
    //public:
    //    int globalErrorCounter   = 0;    // Incremented each time an error is printed. 

    public:
        int local_debug = 1;  // 1 to print debug messages in this class instance, 0 to not

    void fSimPrint(std::string entity, std::string msg, std::string colour_code, va_list arg);

    void fSetDebug(int debug_on);
    static void fSetGlobalDebug(std::string global_debug_on);
    static void fSetGlobalColour(int global_colour_on);

    void fPrintDebug (std::string entity, std::string msg, ...);
    void fPrintMessage(std::string entity, std::string msg, ...);
    void fPrintPass(std::string entity, std::string msg, ...);
    void fPrintWarning(std::string entity, std::string msg, ...);
    void fPrintError(std::string entity, std::string msg, ...);

    void fCheckSig(std::string entity, int errlevel, std::string sname, ap_uint<64> actual, ap_uint<64> expected, int quiet);
    void fCheckRange(std::string entity, int errlevel, std::string sname, ap_uint<64> actual,
            ap_int<64> expected_min, ap_uint<64> expected_max, int quiet);

    int fTestComplete(void);
}; // class SimManagementPkg

#endif
