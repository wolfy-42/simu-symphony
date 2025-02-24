//------------------------------------------------------------------------------
//
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//
// Project      : fidus_prbs_pkg
// Author       : Xianxin Du
// Created      : 2021-06-09
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Description  : Class package for generating/checking PRBS data.
//                Each instance of the class stores a separate state for the 
//                generator and the checker, so they can be used independently.
//                The bit order used throughout is for the newest bit to be in
//                the lsb position. Therefore, data words appended in sequence
//                will show the actual bit sequence.
//                For example, if 2 bytes are generated as "AB" and "CD", then 
//                the bit sequence will be "1010101111001101".
//
//                 Parameters:
//                  pPRBS_LEN   - length/type of PRBS: 7,9,11,15,23,31
//                  pDATA_WIDTH - granularity of data word
//                 Functions/Tasks:
//                  fGenPrbsData   - generate a data word
//                  tGenPrbsPacket - generate a packet of words
//                  fChkPrbsInit   - (re)synchronize the checker
//                  fChkPrbsData   - check a data word
//                  fChkPrbsPacket - check a packet of words
//
// Updated      : yyyy-mm-dd / author - comments
//------------------------------------------------------------------------------

package fidus_prbs_pkg;

class fidus_prbs #(
    // Class Parameters
    pPRBS_LEN   = 31,   // Supported PRBS options are: 7,9,11,15,23,31
    pDATA_WIDTH = 8     // Data granularity = 1 byte
);

    //--------------------------------------------------------------------------
    // Class Variables
    //--------------------------------------------------------------------------
    bit [pPRBS_LEN-1:0] gen_history;
    bit [pPRBS_LEN-1:0] chk_history;


    //--------------------------------------------------------------------------
    // Constructor. Optional argument to initialize to a non-zero state.
    //--------------------------------------------------------------------------
    function new (
        bit [pPRBS_LEN-1:0] init_data = '0
    );
        gen_history = init_data;
        chk_history = init_data;
    endfunction : new

    //--------------------------------------------------------------------------
    // Generate and return the next prbs word.
    //--------------------------------------------------------------------------
    function bit [pDATA_WIDTH-1:0] fGenPrbsData();
        bit newbit;
        bit [pDATA_WIDTH-1:0] gen_data;

        for (int i=0; i<pDATA_WIDTH; i++) begin
            // xor reduce of bits
            case(pPRBS_LEN)
                 7: newbit = ^{gen_history[6] ,gen_history[5] ,1'b1}; // x7  + x6  + 1
                 9: newbit = ^{gen_history[8] ,gen_history[4] ,1'b1}; // x9  + x5  + 1
                11: newbit = ^{gen_history[10],gen_history[8] ,1'b1}; // x11 + x9  + 1
                15: newbit = ^{gen_history[14],gen_history[13],1'b1}; // x15 + x14 + 1
                20: newbit = ^{gen_history[19],gen_history[2] ,1'b1}; // x20 + x3  + 1
                23: newbit = ^{gen_history[22],gen_history[17],1'b1}; // x23 + x18 + 1
                31: newbit = ^{gen_history[30],gen_history[27],1'b1}; // x31 + x28 + 1
                default: newbit = 0;
            endcase
            // shift
            gen_history = {gen_history[pPRBS_LEN-2:0], newbit};
            gen_data[pDATA_WIDTH-1-i] = newbit;
        end
        return gen_data;

    endfunction : fGenPrbsData

    //--------------------------------------------------------------------------
    // Task to generate and output a packet of specified size.
    // The first prbs word will be in o_data[0]. Arg can be a dynamic array.
    //--------------------------------------------------------------------------
    task tGenPrbsPacket(
        input  int size,
        output bit [pDATA_WIDTH-1:0] o_data []
    );
        bit [pDATA_WIDTH-1:0] data[] = new[size];
        for (int i=0; i<size; i++) begin
            data[i] = fGenPrbsData();
        end
        o_data = data;
    endtask : tGenPrbsPacket;


    //--------------------------------------------------------------------------
    // If the received data stream gets out of sync with the checker (due to 
    // loss/extra data), this function can be used to (re)synchronize with 
    // the input bit sequence.
    // Use the pPRBS_LEN bits before a pDATA_WIDTH boundary for init_data.
    // Then continue with fChkPrbsData using the next pDATA_WIDTH word.
    //--------------------------------------------------------------------------
    function void fChkPrbsInit(bit [pPRBS_LEN-1:0] init_data);
        chk_history = init_data;
    endfunction : fChkPrbsInit

    //--------------------------------------------------------------------------
    // Check a data word against the current prbs state.
    // Returns number of mismatch bit errors. 0 = data okay.
    //--------------------------------------------------------------------------
    function int fChkPrbsData(bit [pDATA_WIDTH-1:0] data);
        bit newbit;
        bit [pDATA_WIDTH-1:0] chk_data;

        for (int i=0; i<pDATA_WIDTH; i++) begin
            // xor reduce of bits
            case(pPRBS_LEN)
                 7: newbit = ^{chk_history[6] ,chk_history[5] ,1'b1}; // x7  + x6  + 1
                 9: newbit = ^{chk_history[8] ,chk_history[4] ,1'b1}; // x9  + x5  + 1
                11: newbit = ^{chk_history[10],chk_history[8] ,1'b1}; // x11 + x9  + 1
                15: newbit = ^{chk_history[14],chk_history[13],1'b1}; // x15 + x14 + 1
                20: newbit = ^{chk_history[19],chk_history[2] ,1'b1}; // x20 + x3  + 1
                23: newbit = ^{chk_history[22],chk_history[17],1'b1}; // x23 + x18 + 1
                31: newbit = ^{chk_history[30],chk_history[27],1'b1}; // x31 + x28 + 1
                default: newbit = 0;
            endcase
            chk_history = {chk_history[pPRBS_LEN-2:0], newbit};
            chk_data[pDATA_WIDTH-1-i] = newbit;
        end
        // returns count of non-matching bits
        return $countones(chk_data ^ data);
    endfunction : fChkPrbsData

    //--------------------------------------------------------------------------
    // Function to check a packet's data words.
    // Returns the total number of bit errors.
    //--------------------------------------------------------------------------
    function int fChkPrbsPacket(
        input  bit [pDATA_WIDTH-1:0] i_data []
    );
        int error_cnt = 0;
        for (int i=0; i<i_data.size(); i++) begin
            error_cnt += fChkPrbsData(i_data[i]);
        end
        return error_cnt;
    endfunction : fChkPrbsPacket;

endclass
endpackage
