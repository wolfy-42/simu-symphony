//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_CY7C133_DPRAM_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : Aug 25st, 2012
//--------------------------------------------------------------------
//Description : Master model for read/write of an I/F based on the Cypress CY7C133 DPRAM
//  Supported Operation Mode(s):
//    - Read Mode #3 (read with busy)
//    - Write mode #1 (OE tristate control)
//    - Busy timing #1 (CE arbitration) 
//
// Datasheet: http://download.siliconexpert.com/pdfs/2008/04/10/urlc/cyp/cy7c133_8.pdf (obsolete)
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2012-08-30 14:31:08 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

module bfm_CY7C133_DPRAM_master
   #( parameter BFM_NAME             = "bfm_CY7C133_DPRAM",
      parameter ADDR_WIDTH           = 12,
      parameter DATA_WIDTH           = 16
   )
   (
      //<> DUT connections
      output reg [ADDR_WIDTH-1:0] o_addr    ,
      inout wire [DATA_WIDTH-1:0] io_data ,
      output reg o_rw_n   ,
      output reg o_oe_n   ,
      output reg o_ce_n   ,
      input wire i_busy_n  		
   );

//<> ------------------------------------------------------------
//<> LOCAL PARAMETER/CONSTANTS 
//<> ------------------------------------------------------------   

   //<> ------------------------------------------------------------   
   //<> TIMING SPECS  (ns)
   //<>    - NOTE: ALL TIMES FROM START OF TRANSACTION 
   parameter ts_C2C_GAP              = 250;   // cycle to cycle gap  <<ARBITRARY>>

   // //<>-----------------------------------------------------------------------------------------
   // //<> 25ns SPEEDGRADE-------------------------------------------------------------------------
   // //<> Read Cycle
   // parameter ts_RD_RC            = 25;   // read cycle time (address valid)
   // parameter ts_RD_AA            = 25;   // Address to data valid MAX
   // parameter ts_RD_ACE           = 25;   // CE low to data valid MAX
   // parameter ts_RD_DOE           = 20;   // OE low to data valid MAX
   // parameter ts_RD_LZE           = 3;    // OE/CE low to tri-release MIN
   // parameter ts_RD_HZE           = 15;   // OE/CE HIGH to tristate MAX
   // //<> Write Cycle      
   // parameter ts_WR_WC            = 25;       
   // parameter ts_WR_PWE           = 20;                                     // WE pulse width MIN 
   // parameter ts_WR_AW            = 20;                                     // ADDR setup to WE end MIN
   // parameter ts_WR_SA            = 0;                                      // addr setup to we start min
   // parameter ts_WR_SD            = 15;                                     // data setup to we end
   // parameter ts_WR_SCE           = 20 ;                                    // CE low to WE end
   // parameter ts_WR_HA            = 2 ;                                     // ADDR hold from WE end
   // parameter ts_WR_HD            = 0 ;                                     // DATA hold from WE end

   //<>-----------------------------------------------------------------------------------------
   //<> 55ns SPEEDGRADE-------------------------------------------------------------------------
   //<> Read Cycle
   // parameter ts_RD_RC            = 55;   // read cycle time (address valid)
   parameter ts_RD_RC            = 200;   // read cycle time (address valid)
   parameter ts_RD_AA            = 55;   // Address to data valid MAX
   parameter ts_RD_ACE           = 55;   // CE low to data valid MAX
   parameter ts_RD_DOE           = 30;   // OE low to data valid MAX
   parameter ts_RD_LZE           = 5;    // OE/CE low to tri-release MIN
   parameter ts_RD_HZE           = 20;   // OE/CE HIGH to tristate MAX
   //<> Write Cycle      
   // parameter ts_WR_WC            = 55;       
   parameter ts_WR_WC            = ts_RD_RC;       
   parameter ts_WR_PWE           = 35;                                     // WE pulse width MIN 
   parameter ts_WR_AW            = 40;                                     // ADDR setup to WE end MIN
   parameter ts_WR_SA            = 0;                                      // addr setup to we start min
   parameter ts_WR_SD            = 20;                                     // data setup to we end
   parameter ts_WR_SCE           = 40 ;                                    // CE low to WE end
   parameter ts_WR_HA            = 2 ;                                     // ADDR hold from WE end
   parameter ts_WR_HD            = 0 ;                                     // DATA hold from WE end
   
   //<>-----------------------------------------------------------------------------------------
   localparam ts_A2CEsu          = 55; //(ts_WR_WC - (ts_WR_SCE + ts_WR_HA)) ;   // address setup ahead of CE assert
   localparam ts_WR_A2Dsu        = (ts_WR_AW - ts_WR_SD);                  // data assert after address
   
//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   reg [DATA_WIDTH-1:0] data_out = 0;  
   reg data_tristate_en = 1;           // internal data bus tristate control
   reg [ADDR_WIDTH-1:0] int_address = 0;  // internal copy of requested transfers
   reg rd_wr_sel;       // 1=read, 0=write   
   event transaction;  
   
//<>--------------------------------------------------------------
//<> SIMULATION CONTROL TASKS
//<>--------------------------------------------------------------

   //<> ------------------------------------------------------------- 
   //<> task for read mode (data input)
   task mwsRead (
		   input [ADDR_WIDTH-1:0] address,
		   output [DATA_WIDTH-1:0] data
   );
      string msg;
      begin
         // //<> start cycle
         int_address = address;
         rd_wr_sel = 1;
         ->transaction;                // kick transaction 
         @(posedge o_oe_n);            // wait on end of output enable cycle
         data = io_data;               // latch and return read data to caller
         //<> perform simulation transcript output (if enabled)
         msg = {"read_ctrl: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         `SIM.printDebugMsg(BFM_NAME, msg); 
         if (~o_ce_n) @(posedge o_ce_n);
         # (ts_C2C_GAP);               // ensure turnaround seperation between cycles
      end
   endtask // mwsRead

   //<>-------------------------------------------- 
   //<> task for write mode (data output)
   task mwsWrite (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] data
      );
      string msg;
      begin
         //<> perform simulation cross checks and transcript output
         msg = {"write_ctrl: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         `SIM.printDebugMsg(BFM_NAME, msg); 
         int_address = address;
         rd_wr_sel = 0;
         data_out = data;        // map requested wr data to internal output tristate buffer (pending release)
         ->transaction;          // kick transaction 
         BusyDelay((ts_A2CEsu+ts_WR_WC));  // wait for end of write cycle
         # (ts_C2C_GAP);         // ensure turnaround seperation between cycles
         data_out = 0; // clear internal data 
      end
   endtask // mwsWrite

   //<>-------------------------------------------- 
   //<> task to stretch MWS bus cycle on receipt of a BUSY input
   task BusyDelay (
         input integer delay
   );
   begin
      fork  // run two parallel delay paths...longer delay wins
         if (i_busy_n == 1'b0) begin          // check if the busy flag has been asserted
            @(posedge i_busy_n); // if so, then wait until it deasserts and ..
            #(delay);         // then delay as required
         end;
         #(delay);      // delay as required
      join
   end 
   endtask
   
//<>--------------------------------------------------------------
//<> IO PORT CONTROLS
//<>--------------------------------------------------------------

   //<> -------------------------------------------- 
   //<> implement Bi-diretional bus tristate control 
   assign io_data = (~data_tristate_en) ? data_out : 'bZ;

   //<> -------------------------------------------- 
   //<> Address control 
   always
   begin
      o_addr = 0;      // ensure address bus cleared
      @(transaction);       // wait for start of transaction request
      o_addr = int_address;
      #(ts_A2CEsu);
      if (rd_wr_sel == 1)   // -- READ CYCLE --
         BusyDelay(ts_RD_RC);          // read cycle time (address valid)
      else                  // -- WRITE CYCLE --
         BusyDelay(ts_WR_WC);          // write cycle time (address valid)
   end
   
   //<> --------------------------------------------    
   //<> Chip enable control
   always
   begin
      o_ce_n = 1'b1;               // ensure select inactive
      @(transaction);              // wait for start of transaction request
      #(ts_A2CEsu);                // delay for start of chipselect (same for RD or WR)
      o_ce_n = 1'b0;               // assert chip enable
      if (rd_wr_sel) begin         // -- READ CYCLE --
         BusyDelay(ts_RD_RC);              // delay before release
      end
      else begin                   // -- WRITE cycle -- 
         BusyDelay((ts_WR_WC - ts_WR_HA));  // delay before release
      end
   end // always

   //<> -------------------------------------------- 
   //<> RWn output 
   always
   begin
      o_rw_n = 1'b1;       // ensure RWn inactive
      @(transaction);  // wait for start of transaction request
      #(ts_A2CEsu);
      if (~rd_wr_sel) begin     // -- WRITE cycle -- 
         BusyDelay((ts_WR_WC - (ts_WR_PWE + ts_WR_HA)));   // delay start of WR
         o_rw_n = 1'b0;
         BusyDelay(ts_WR_PWE);  // delay end of WR
         // int_rd_data = io_data;   // latch data bus on rising write_enable
      end
   end // RWn  always

   //<> --------------------------------------------
   //<> OE control & data latch
   always
   begin
      o_oe_n = 1'b1;                             // ensure select inactive
      @(transaction);  // wait for start of transaction request
      #(ts_A2CEsu);
      if (rd_wr_sel) begin      // -- READ cycle --
         BusyDelay((ts_RD_ACE - ts_RD_DOE));   // delay OE vs CS/ADDR
         o_oe_n = 1'b0;
         BusyDelay((ts_RD_RC - (ts_RD_ACE - ts_RD_DOE)));  // delay end of read cycle
      end
   end // OE always
   
      
   //<> -------------------------------------------- 
   //<> internal data bus direction/tristate control
   always
   begin
      data_tristate_en = 1'b1;     // hold data port in Tristate (for reading)
      @(transaction);  // wait for start of transaction request
      #(ts_A2CEsu);
      if (~rd_wr_sel) begin     // -- WRITE cycle -- 
         BusyDelay((ts_WR_WC - (ts_WR_SD + ts_WR_HA)));   // delay start of WR
         data_tristate_en = 1'b0;  // release tristate, drive data on port
         BusyDelay((ts_WR_SD + ts_WR_HD));  // delay end of valid data out 
      end
   end // tristate always
   
endmodule


//<> INSTANCE TEMPLATE

// //<> Cypress DPRAM Master BFM instance
// bfm_CY7C133_DPRAM_master
   // #( .BFM_NAME   ("bfm_CY7C133_DPRAM"),
      // .ADDR_WIDTH (12),
      // .DATA_WIDTH (16)
   // ) bfm_CY7C133_DPRAM_master_inst
   // (
      // //<> main bus
      // .o_addr            (),
      // .io_data           (),
      // .o_rw_n            (),
      // .o_oe_n            (),
      // .o_ce_n            (),
      // .i_busy_n          ()		
   // );