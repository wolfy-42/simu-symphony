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
#include <stdint.h>

#include "sim_management_pkg.h"

// black - 30
// red - 31
// green - 32
// yellow - 33
// blue - 34
// magenta - 35
// cyan - 36
// lightgray - 37

// \033[0m - is the default color for the console
// \033[0;#m - is the color of the text, where # is one of the codes mentioned above
// \033[1m - makes text bold
// \033[1;#m - makes colored text bold**
// \033[2;#m - colors text according to # but a bit darker
// \033[4;#m - colors text in # and underlines
// \033[7;#m - colors the background according to #
// \033[9;#m - colors text and strikes it

static const std::string colour_def = "\033[0m"; // default consol colour
static const std::string colour_red = "\033[1;31m";
static const std::string colour_dred = "\033[0;31m";
static const std::string colour_green = "\033[1;32m";
static const std::string colour_dgreen = "\033[0;32m"; // dark green
static const std::string colour_yellow = "\033[1;33m"; // yellow
static const std::string colour_blue = "\033[1;34m";
static const std::string colour_dblue = "\033[0;34m";  // dark blue
static const std::string colour_cyan = "\033[1;36m";
static const std::string colour_dcyan = "\033[0;36m";
static const std::string colour_purple = "\033[1;35m";
static const std::string colour_dpurple = "\033[0;35m";
static const std::string colour_brown = "\033[1;33m";
static const std::string colour_dbrown = "\033[0;33m";
static const std::string colour_bold = "\033[1;1m";
static const std::string colour_inverse = "\033[1;7m";

static int globalErrorCounter   = 0;    // Incremented each time an error is printed.
static int globalWarningCounter = 0;    // Incremented each time a warning is printed.
static int globalPassCounter = 0;       // Incremented each time a pass is printed.
static std::string global_debug = "on";  // "on", "off", "all" to report all modules debug messages
static int enable_colours = 1;          // set to 1 to print in colour; 0 to not;

//-----------------------------------------------------------------------------
// function: fPrintColour
// Purpose: Print  colour string if enabled.
// Inputs:
//      colour_code: colour escape code to print
//-----------------------------------------------------------------------------
static void fPrintColour(std::string colour_code)
{
    if (enable_colours)
        printf(colour_code.c_str());
}


//-----------------------------------------------------------------------------
// function: fSimPrint
// Purpose: Print formatted message with entity and colour.
// Inputs:
//      entity:         string describing the entity being printed and the message level.
//      msg:            formatted message to be printed.
//      colour_code:    escaped colour code to print the message in.
//      args:           variable list of arguments used by the formatted string.
//-----------------------------------------------------------------------------
void SimManagementPkg::fSimPrint(std::string entity, std::string msg, std::string colour_code, va_list args)
{
    fPrintColour(colour_code);
    printf(entity.c_str());
    vprintf(msg.c_str(), args);
    fPrintColour(colour_def);
    printf("\n");
}

//-----------------------------------------------------------------------------
// function: fSetDebug
// Purpose: Disable debug message printing for this class instance.
// Inputs:
//      debug_on: 1 to enabled, 0 to disable
//-----------------------------------------------------------------------------
void SimManagementPkg::fSetDebug(int debug_on)
{
    this->local_debug = debug_on;
}

//-----------------------------------------------------------------------------
// function: fSetGlobalDebug
// Purpose: Global force all debug on, suppress all, or case by case depending on local_debug.
// Inputs:
//      global_debug_on: "on"  -> debug messages printed if local_debug is set
//                       "off" -> all debug message supressed
//                       "all" -> all debug messages printed
//-----------------------------------------------------------------------------
void SimManagementPkg::fSetGlobalDebug(std::string global_debug_on)
{
    global_debug = global_debug_on;
}

//-----------------------------------------------------------------------------
// function: fSetGlobalColour
// Purpose: Enable printing in colour.
// Inputs:
//      global_colour_on: 1 to print in colour; 0 to not;
//-----------------------------------------------------------------------------
void fSetGlobalColour(int global_colour_on){
    enable_colours = global_colour_on;
}

//-----------------------------------------------------------------------------
// function: fPrintDebug
// Purpose: To print a message in a standard format, starting with the
//          name of the module which invoked this task and the label debug.
// Inputs: 
//      entity: the name of the module who invoked this task
//      msg:    the message to be displayed
//      ...:    variable length list of format variables
//-----------------------------------------------------------------------------
void SimManagementPkg::fPrintDebug(std::string entity, std::string msg, ...)
{
    va_list args;
    va_start(args, msg);

    if ((this->local_debug && global_debug == "on") || global_debug == "all") {
        std::string debug_entity = "    debug (" + entity + "): ";
        this->fSimPrint(debug_entity, msg, colour_def, args);
    }

    va_end(args);
}

//-----------------------------------------------------------------------------
// function: fPrintMessage
// Purpose: To print a message in a standard format, starting with the
//          name of the module which invoked this task and the label MESSAGE.
// Inputs: 
//      entity: the name of the module who invoked this task
//      msg:    the message to be displayed
//      ...:    variable length list of format variables
//-----------------------------------------------------------------------------
void SimManagementPkg::fPrintMessage(std::string entity, std::string msg, ...)
{
    va_list args;
    va_start(args, msg);

    std::string msg_entity = "    MESSAGE (" + entity + "): ";
    this->fSimPrint(msg_entity, msg, colour_bold, args);

    va_end(args);
}

//-----------------------------------------------------------------------------
// function: fPrintPass
// Purpose: To print a message in a standard format, starting with the
//          name of the module which invoked this task and the label PASS.
// Inputs: 
//      entity: the name of the module who invoked this task
//      msg:    the message to be displayed
//      ...:    variable length list of format variables
//-----------------------------------------------------------------------------
void SimManagementPkg::fPrintPass(std::string entity, std::string msg, ...)
{
    va_list args;
    va_start(args, msg);

    std::string pass_entity = "    +PASS (" + entity + "): ";
    this->fSimPrint(pass_entity, msg, colour_green, args);
    globalPassCounter =  globalPassCounter + 1;

    va_end(args);
}

//-----------------------------------------------------------------------------
// function: fPrintWarning
// Purpose: To print a message in a standard format, starting with the
//          name of the module which invoked this task and the label WARNING.
// Inputs: 
//      entity: the name of the module who invoked this task
//      msg:    the message to be displayed
//      ...:    variable length list of format variables
//-----------------------------------------------------------------------------
void SimManagementPkg::fPrintWarning(std::string entity, std::string msg, ...)
{
    va_list args;
    va_start(args, msg);

    std::string warning_entity = "   >WARNING (" + entity + "): ";
    this->fSimPrint(warning_entity, msg, colour_yellow, args);
    globalWarningCounter = globalWarningCounter + 1;

    va_end(args);
}

//-----------------------------------------------------------------------------
// function: fPrintError
// Purpose: To print a message in a standard format, starting with the
//          name of the module which invoked this task and the label ERROR.
// Inputs: 
//      entity: the name of the module who invoked this task
//      msg:    the message to be displayed
//      ...:    variable length list of format variables
//-----------------------------------------------------------------------------
void SimManagementPkg::fPrintError(std::string entity, std::string msg, ...)
{
    va_list args;
    va_start(args, msg);

    std::string error_entity = "  >>ERROR (" + entity + "): ";
    this->fSimPrint(error_entity, msg, colour_red, args);
    globalErrorCounter = globalErrorCounter + 1;

    va_end(args);
}

//-----------------------------------------------------------------------------
// function: fCheckSig
// Purpose: Check two ap_uint types for equality and raise an error/warning is not equal.
// Inputs: 
//      entity:     name of the module who invoked this take
//      errlevel:   when not equal: 0 -> print message; 1 -> print warning; 2 -> print error
//      sname:      signal name to be added to message
//      actual:     signal to be tested
//      expected:   expected value
//      quiet:      set to 0 to print a pass message when equal; set 0 to to suppress printPass
//-----------------------------------------------------------------------------
void SimManagementPkg::fCheckSig(std::string entity, int errlevel, std::string sname,
        ap_uint<64> actual, ap_uint<64> expected, int quiet)
{
    if (actual != expected) {
        std::string message = "%s had unexpected value (0x%lx), expected (0x%lx)";
        switch (errlevel) {
            case 0: fPrintMessage(entity, message, sname.c_str(), (uint64_t)actual, (uint64_t)expected);break;
            case 1: fPrintWarning(entity, message, sname.c_str(), (uint64_t)actual, (uint64_t)expected);break;
            default: fPrintError(entity, message, sname.c_str(), (uint64_t)actual, (uint64_t)expected);break;
        }
    } else if (!quiet) {
        fPrintPass(entity, "%s matched expected value (0x%lx)", sname.c_str(), (uint64_t)actual);
    } else {
        globalPassCounter =  globalPassCounter + 1;
    }
}

//-----------------------------------------------------------------------------
// function: fCheckRange
// Purpose: Check that ap_uint falls between two bounds and raise an error/warning if not.
// Inputs: 
//      entity:     name of the module who invoked this take
//      errlevel:   when not equal: 0 -> print message; 1 -> print warning; 2 -> print error
//      sname:      signal name to be added to message
//      actual:     signal to be tested
//      expected_min: lower end of expected range (inclusive)
//      expected_max: upper end of expected range (inclusive)
//      quiet:      set to 0 to print a pass message when equal; set 0 to to suppress printPass
//-----------------------------------------------------------------------------
void SimManagementPkg::fCheckRange(std::string entity, int errlevel, std::string sname, ap_uint<64> actual,
        ap_int<64> expected_min, ap_uint<64> expected_max, int quiet)
{
    if (actual < expected_min || actual > expected_max) {
        std::string message = "%s had unexpected value (0x%lx), expected (0x%lx - 0x%lx)";
        switch (errlevel) {
            case 0: 
                fPrintMessage(entity, message, sname.c_str(), (uint64_t)actual,
                        (uint64_t)expected_min, (uint64_t)expected_max);
                break;
            case 1:
                fPrintWarning(entity, message, sname.c_str(), (uint64_t)actual,
                        (uint64_t)expected_min, (uint64_t)expected_max);
                break;
            default:
                fPrintError(entity, message, sname.c_str(), (uint64_t)actual,
                        (uint64_t)expected_min, (uint64_t)expected_max);
                break;
        }
    } else if (!quiet) {
        fPrintPass(entity, "%s value (0x%lx) inside expected range (0x%lx-0x%lx)",
                sname.c_str(), (uint64_t)actual, (uint64_t)expected_min, (uint64_t)expected_max);
    } else {
        globalPassCounter =  globalPassCounter + 1;
    }
}

//-----------------------------------------------------------------------------
// function: fTestComplete
// Purpose: This task cleanly terminates the simulation. It reports the simulation
//          status (pass/fail) based on the values of the globalErrorCounter. The
//          simulation should be ended no other way than by invoking this task.
//-----------------------------------------------------------------------------
int SimManagementPkg::fTestComplete(void)
{
    // Set colour.
    fPrintColour(colour_green); // set console green
    if (globalWarningCounter != 0)
        fPrintColour(colour_yellow); // set console yellow
    if (globalErrorCounter != 0 || globalPassCounter == 0)
        fPrintColour(colour_red); // set console red

    printf("\n================================================================\n");
    printf("====================== END OF SIMULATION =======================\n");
    printf("================================================================\n\n");

    // One space between ":" and the number is required.
    printf("PASS  : %d\n", globalPassCounter);
    // There must be no space between WARNINGS and ":", log file parsing assumes this fact.
    printf("WARNINGS: %d\n", globalWarningCounter);
    printf("ERRORS  : %d\n", globalErrorCounter);

    if (globalErrorCounter == 0 && globalPassCounter > 0)
        printf("\n\nSIMULATION STATUS: PASS\n\n\n");
    else
        printf("\n\nSIMULATION STATUS: FAIL\n\n\n");

    fPrintColour(colour_def); // default colour restore

    printf("Colours can be turned off in sim_managemnt_pkg.cpp\n\n\n");

        // TODO make return to return 1 if there are errors in the TC
    if (globalErrorCounter == 0 )  { 
        return 0;         
    } else {
        return 1;
    }
}
