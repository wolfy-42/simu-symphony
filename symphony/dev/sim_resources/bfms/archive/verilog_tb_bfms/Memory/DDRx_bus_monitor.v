//--------------------------------------------------------------------
// Copyright (C) 2006-2023 Fidus Systems Inc. 
// SPDX-License-Identifier: Apache-2.0 OR MIT
// The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
// File name   : DDRx_bus_monitor.v
// Project     : RIPL
// Author      : Arnold Balisch
// Created     : OCT 30, 2013
// Modified    : May 7, 2015
// Version     : v2.2
//--------------------------------------------------------------------
// Description : DDRx bus transaction sniffer/monitor
//       - intended for simulation waveform display and testcase events
//  
//--------------------------------------------------------------------
// Usage: 
//    - Tie input ports to matching DDR bus signals (sniffer taps)
//    - Ensure module parameters are correct for target DDRx RAM type/configuration
//
//   Waveform Variables:
//    - the following nets are the main ones to Map into waveform viewer:
//          command              -- string mnemonic for current bus transaction/command (RD, WR, ACT, etc)
//          ram_byte_addr        -- shows logical/linear byte-aligned address during read/write transactions (LSbit = 8 bits)
//          ram_bus_addr         -- shows logical/linear bus-width-aligned address during read/write transactions (LSbit = DQ_BITS)
//
//   User accessable Task/Function calls:
//    - the following functions/tasks can be called from a testcase:
//          function real ClearWrCount();            -- clears write cycle counters 
//          function real ClearWrCount();            -- clears read cycle counters
//          function real ClearWrCount();            -- clears read,write, and data cycle counters
//          function real GetCurrWrBW();             -- returns percent bandwidth of write traffic since last ClearDataCnt() of ClearWrCount()
//          function real GetCurrRdBW();             -- returns percent bandwidth of read traffic since last ClearDataCnt() or ClearRdCount()
//          function real GetCurrDataBW();           -- returns percent bandwidth of both read and write traffic since last ClearDataCount()
//
//   User accessable calculation results:
//          CK_meas_period       -- Measured period of CK    (time)
//          CK_freq              -- measured frequency of CK (real)
//          
//  Known Issues:
//    - DDR3 "on-the-fly" variants of Read/Write are reported as normal read/write
//    - DDR4 features not yet implemented
//
//--------------------------------------------------------------------
// Resource: Truth Table derived from JEDEC specification JESD79-xx
//--------------------------------------------------------------------
// Modifications:
//    v1.0 - May 21, 2014  (Arnold Balisch)
//                -  removed "-BL_bits" from ADDRESS_BITS param as it incorrectly reflected internal
//                 array bit-width and not actual bus address range maximum.
//
//    v2.0 - Sept 12, 2014 (Arnold Balisch)
//                - added A[12] avoidance for DDR3/4 protocol support when building linear 'ram_address'
//                - fixed issue with byte alignment of logical address for word or nibble DQ width
//                   - "ram_byte_addr" now always reads as a byte-aligned address 
//                         - value of DQ_BITs 16/8/4 (word/byte/nibble) controls internal compensation adjustment
//
//    v2.1 - May 7, 2015   (Arnold Balisch)
//                - added functions and counters for read/write/data transaction effeciency calculations
//                - added address for DQ_BIT-aligned address (vs byte-aligned address). 
//                   - Helpful in decoding bus transactions at ROW/COL/BANK within BFMs
//                - started implementation of bus frequency calculations
//
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.5 $    $Date: 2015-05-08 13:08:18 $
//--------------------------------------------------------------------

//<> global defines for consistant testcase design
`timescale 1ns / 1ns

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module DDRx_bus_monitor
   #( parameter DDR_TYPE     = 2,                   // DDR generation for truthtable: 1=DDR, 2= DDR2, 3=DDR3 (4=DDR4 {RFU})
      parameter DDR_AD_MODE  = "ROW_BANK_COLUMN",   // Addressing mode : ROW_BANK_COLUMN or BANK_ROW_COLUMN
      parameter DDR_PKG_ARCH = "SINGLE",            // packaging architecture : SINGLE, DIMM 
      parameter AD_BITS      = 13,                  // number  AD bits of DDR bus(including specials)
      parameter ROW_BITS     = 13,                  // number AD bits assigned to row addressing inside RAM
      parameter COL_BITS     = 10,                  // number AD bits assigned to column addressing inside RAM
      parameter BA_BITS      = 2,                   // number bits of BA bus
      parameter RANK_BITS    = 0,                   // number bits of rank bus - <DIMM use only> - Default = 0 (SINGLE)
      parameter BL_BITS      = 3,                   // number bits to count to maximum burst length (default=3 for BL-8)
      parameter DQ_BITS      = 16,                  // Width of DQ bus (valid options = 4/8/16) - affects logical address byte alignment (default=16)
      parameter BURST_LEN    = 8                    // number of data-words per RD/WR burst (used for bandwidth calculations)
      )
(  input wire [AD_BITS-1:0] AD,               // DDR AD bus
   input wire [RANK_BITS-1:0] Sn,             // Rank select lines (DIMM only - tie zero if SINGLE)
   input wire [BA_BITS-1:0] BA,               // DDR Bank Address
   input wire CK,                             // DDR CK clock
   input wire CKE,                            // DDR clock enable
   input wire CSn,                            // DDR chip select
   input wire CASn,                           // DDR column address strobe
   input wire RASn,                           // DDR row address strobe
   input wire WEn                             // DDR write enable
);

   //<>----------------------------------------------------------------
   //<> local parameters
   localparam MODULE_NAME = "DDRx_bus_monitor";
   localparam ADDRESS_BITS = (RANK_BITS+BA_BITS+ROW_BITS+COL_BITS+1);     // +1 for 16bit bus byte-boundary addressing
   
   //<>----------------------------------------------------------------
   //<> local variables and structures
   string command;                                        // symbol for holding current transaction description
   reg [ADDRESS_BITS-1:0] ram_byte_addr = 0;              // Linear address at byte granularity (LSbit = 8 bits)
   reg [ADDRESS_BITS-2:0] ram_bus_addr  = 0;              // Linear address at DQ-width granularity (LSbit = DQ_BITS)
   reg [COL_BITS-1:0] col_addr = 0;                       // column address - latched during read/write cycle
   reg [ROW_BITS-1:0] row_addr = 0;                       // row address - latched during activate cycle
   reg A10;                                               // Address bit-10 - used for DDR3/4 command/linear address decode
   reg prev_cke = 1'b0;                                   // hold last state of CKE input for truthtable decode

   integer rd_count     = 0;                              // user-accessable counter for tracking read operations (all types)
   integer wr_count     = 0;                              // user-accessable counter for tracking write operations (all types)
   integer rd_clk_cnt   = 0;                              // user-accessable counter for tracking clock operations (all types)
   integer wr_clk_cnt   = 0;                              // user-accessable counter for tracking clock operations (all types)
   integer data_clk_cnt = 0;                              // user-accessable counter for tracking clock operations (all types)
   integer x;                                             // loop pointer
   
   time CK_rise, CK_meas_period;                          // used for bandwidth calculations <<UNTESTED>>
   
   real CK_freq = 0.0;                                    // used for bandwidth calculations <<UNTESTED>>
   
   event activate_evnt;                                   // use highlight ACTIVATE events in waveforms
   event read_evnt;                                       // use highlight READ events in waveforms
   event write_evnt;                                      // use highlight WRITE events in waveforms

   
//<>=============================================================================================
//<> ============  User accessable tasks/functions  =============================================
//<>=============================================================================================   
   
   //<>------------------------------------------------------------------
   //<> Tasks to enable testcases to clear read/write counters as required
   
   task ClearRdCount();   //<> clear read transaction counter (clk+data)
   begin
      rd_clk_cnt = 0;
      rd_count = 0;
   end
   endtask
   
   task ClearWrCount();    //<> clear write transaction counter (clk+data)
   begin
      wr_clk_cnt = 0;
      wr_count = 0;
   end
   endtask

   task ClearDataCount();  //<> clear read/write/data transaction counters (clk+data)
   begin
      rd_clk_cnt = 0;
      wr_clk_cnt = 0;
      data_clk_cnt = 0;
      rd_count = 0;
      wr_count = 0;
   end
   endtask

   //<>----------------------------------------------------------------
   //<> functions to return percentage bandwidth calculations 
   //<> - returns bus effeciency in percent (%) of bus theoretical maximum 
   
   function real GetCurrRdBW();  //<> read BW percentage
   begin
      GetCurrRdBW = (real'(rd_count*BURST_LEN)/real'(rd_clk_cnt*2))*100.0; 
   end
   endfunction

   function real GetCurrWrBW();   //<> write BW percentage
   begin
      GetCurrWrBW = (real'(wr_count*BURST_LEN)/real'(wr_clk_cnt*2))*100.0;  //output a percentage
   end
   endfunction

   function real GetCurrDataBW(); //<> data (read+write) BW percentage
      integer total_cnt;
   begin
      total_cnt = wr_count+rd_count;
      GetCurrDataBW = (real'(total_cnt*BURST_LEN)/real'(data_clk_cnt*2))*100.0;  //output a percentage
   end
   endfunction
   
//<>=============================================================================================
//<> ============  end of User accessable tasks/functions =======================================
//<>=============================================================================================   

   //<>------------------------------------------------------------------
   //<> function avoids including DDR A[10] in Column address. 
   initial begin
      x=0;
      while (x<200) begin                    // pad out 200 clock cycles to avoid any startup perturbances
         @(posedge CK);   
         x++;
      end
      CK_rise = $time;                       // latch first posedge edge of CK period
      @(posedge CK);                           // wait for next posedge
      CK_meas_period = $time - CK_rise;      // calculate period duration
      CK_freq = real'(1.0/CK_meas_period);   // invert for frequency and cast as type real
   end
  
   //<>------------------------------------------------------------------
   //<> function avoids including DDR A[10] in Column address. 
   //<>  - DDR bus bit A[10] is a special case bit used in Command decode (ie  WR vs WRA)
   //<>  - DDR bus bit A[12] is a special case bit in DDR3 used in Command decode (ie  WR vs WRA)
   function [COL_BITS-1:0] ParseColAddr(
      input reg [AD_BITS-1:0] bus_addr);
      integer i,ptr;
   begin
      ptr=0; // initialize
      for (i=0; i<COL_BITS; i=i+1) begin
         if (    (i==10)                           // skip over A[10] (for all DDR types),
              || ((DDR_TYPE >= 3) && (i==12)) )    //    and/or A[12] (for DDR3(4?) only)
         begin
            ptr = ptr+1;                           // -> advance pointer
         end
         ParseColAddr[i] = bus_addr[ptr];
         ptr=ptr+1;                                // advance to track for loop index
      end
   end
   endfunction
   
   //<>----------------------------------------------------------------
   //<> pipe to latch previous CKE state for command truthtable decode
   always 
   begin
      @(posedge CK)
      rd_clk_cnt++;     // increment various clock event counters
      wr_clk_cnt++;
      data_clk_cnt++;
      #1;      // delay to ensure no race with truthtable decode
      prev_cke = CKE;
   end
   
   //<>----------------------------------------------------------------
   //<> extract special function address line for command decode read-ability
   assign A10 = AD[10];
   
   //<>----------------------------------------------------------------
   //<> DDR command truthtable decode 
   always @(posedge CK)
   begin
      casex ({prev_cke, CKE, CSn, RASn, CASn, WEn, A10})    // build bus command pattern (in sequence of JESD79 documentation)
         'b110_000x     :     command = "MRS";              // Mode register access
         'b110_001x     :     command = "REF";              // refresh 
         'b100_001x     :     command = "SRE";              // self-refresh entry
         'b011_xxxx,    
            'b010_111x  :     command = "SRX";              // self-refresh exit
         'b110_0100     :     command = "PRE";              // single bank precharge
         'b110_0101     :     command = "PREA";             // all bank precharge
         'b110_011x     :  begin
                              command = "ACT";              // bank activate
                              row_addr = AD[ROW_BITS-1:0];
                              ->activate_evnt;              // indicate activate event
                           end
         'b110_1000     :  begin 
                              command = "WR";               // write
                              wr_count = wr_count +1;
                              col_addr = ParseColAddr(AD);  // avoid A[10] if needed
                              ->write_evnt;
                           end
         'b110_1001     :  begin 
                              command = "WRA";              // write with auto-precharge
                              wr_count = wr_count +1;
                              col_addr = ParseColAddr(AD);  // avoid A[10] if needed
                              ->write_evnt;
                           end
         'b110_1010     :  begin 
                              command = "RD";               // read
                              rd_count = rd_count +1;
                              col_addr = ParseColAddr(AD);  // avoid A[10] if needed
                              ->read_evnt;
                           end
         'b110_1011     :  begin 
                              command = "RDA";              // read with auto-precharge
                              rd_count = rd_count +1;
                              col_addr = ParseColAddr(AD);
                              ->read_evnt;
                           end
         'b1x0_111x     :     command = "NOP";              // no operation
         'b1x1_xxxx     :     command = "DES";              // device deselect
         'b101_xxxx,    
            'b100_111x  :     command = "PDE";              // power down entry 
         'b011_xxxx,    
            'b010_111x  :     command = "PDX";              // power down exit
         default        :     command = "idle";             // command engine in idle
      endcase
   end

   //<>----------------------------------------------------------------
   //<> build new RAM address 
   // always @(*) begin
   always @(command) begin  // limits process trigger to only when command is changing
      //<> on valid data transfer commands only build the associated address
      if ((command == "RD") || (command == "RDA") || (command == "WR") || (command == "WRA")) begin
         if (DDR_AD_MODE == "ROW_BANK_COLUMN") begin
            ram_bus_addr = {row_addr, BA, col_addr};
            case (DQ_BITS)
               16 : ram_byte_addr = {row_addr, BA, col_addr, 1'b0};                   // reflect word address as byte address
                8 : ram_byte_addr = {1'b0, row_addr, BA, col_addr};                   // native byte address...pad MSbit
                4 : ram_byte_addr = {2'b0, row_addr, BA, col_addr[COL_BITS-1:1]};     // Nibble address, drop LSbit
               default: begin
                     $display("DDRx_Bus_Monitor: Invalid Data Bus dimension supplied!!");
                     $stop;   //Critical fault - abort simulation
                  end
            endcase
         end
         else begin      // otherwise assumes DDR_AD_MODE = "BANK_ROW_COLUMN"
            ram_bus_addr = {BA, row_addr, col_addr};         
            case (DQ_BITS)
               16 : ram_byte_addr = {BA, row_addr, col_addr, 1'b0};                       // reflect word address as byte address
                8 : ram_byte_addr = {1'b0, BA, row_addr, col_addr};                       // native byte address...pad MSbit
                4 : ram_byte_addr = {2'b0, BA, row_addr, BA, col_addr[COL_BITS-1:1]};     // Nibble address, drop LSbit
               default: begin
                     $display("DDRx_Bus_Monitor: Invalid Data Bus dimension supplied!!");
                     $stop;   //Critical fault - abort simulation
                  end
            endcase
         end
      end
   end
   
endmodule //

//************************ Instance Template ************************************

// //<>--------------------------------------------------------
// //<> Description : DDRx Bus Sniffer/Monitor
// //     - Decodes DDRx bus transactions
// //  
// //  Note: ensure correct row/col bit counts provided in instance for selected RAM device
// //
// //   Use: 
// //    - tie input ports to matching DDR bus signals (tap)
// //    - ensure parameters on monitor instance match target DDR RAM configuration
// //    - map following nets into waveform viewer...
// //          tb.{DDRx_bus_monitor_inst}.command 
// //          tb.{DDRx_bus_monitor_inst}.ram_byte_addr
// //
// DDRx_bus_monitor   #( .DDR_TYPE     (2),                 // DDR generation for truthtable: (1=DDR), 2= DDR2), 3=DDR3)
//                      .DDR_AD_MODE  ("ROW_BANK_COLUMN"), // Addressing mode : ROW_BANK_COLUMN or BANK_ROW_COLUMN
//                      .DDR_PKG_ARCH ("SINGLE"),          // packaging architecture : SINGLE, DIMM 
//                      .AD_BITS      (13),                // number  AD bits of DDR bus(including specials)
//                      .ROW_BITS     (13),                // number AD bits assigned to row addressing inside RAM
//                      .COL_BITS     (10),                // number AD bits assigned to column addressing inside RAM
//                      .BA_BITS      (2),                 // number bits of BA bus
//                      .RANK_BITS    (0),                 // number bits of rank bus (DIMM use only)
//                      .BL_BITS      (3),                  // number bits to count to maximum burst length (default=3 for BL-8)
//                      .DQ_BITS      (16)                 // Width of DQ bus (valid options = 4/8/16) - affects logical address byte alignment (default=16)
//                   ) 
//    DDRx_bus_monitor_inst
//    (  .AD   (),         // DDR AD bus
//    // .Sn   (),         // Rank select lines (DIMM only)
//       .BA   (),         // DDR Bank Address
//       .CK   (),         // DDR CK clock
//       .CKE  (),         // DDR clock enable
//       .CSn  (),         // DDR chip select
//       .CASn (),         // DDR column address strobe
//       .RASn (),         // DDR row address strobe
//       .WEn  ()          // DDR write enable
//    );
   
   
