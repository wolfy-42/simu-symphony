//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_SharcDSP_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : April 21st, 2012
//--------------------------------------------------------------------
//Description : BFM for Sharc DSP async AMI memory interfade. For Sharc DSP 21489
//
// Datasheet: http://www.analog.com/en/processors-dsp/sharc/adsp-21489/products/product.html
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.12 $    $Date: 2012-07-03 12:50:09 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_SharcDSP_master
   #( parameter BFM_NAME             = "bfm_SharcDSP_master",
      parameter DATA_WIDTH           = 8,
      parameter ADDR_WIDTH           = 8,
      parameter SILENT               = 0               // if true, suppress printMessage outputs
   )
   (
      output reg  [ADDR_WIDTH-1:0]  ov_ami_addr = 0,   // address bus
      inout wire  [DATA_WIDTH-1:0]  iov_ami_data,      // bi-directional data
      output reg        o_ami_msn = 1'b1,              // memory select
      output reg        o_ami_rdn = 1'b1,              // read enable (active Low)
      output reg        o_ami_wrn = 1'b1,              // write enable (active Low)
      input wire        i_ami_ack                      // external wait request (low=inject waittime)    <<RFU>>
   );

//<> ------------------------------------------------------------
//<> MODULE LOCAL PARAMETER/CONSTANTS
//<> ------------------------------------------------------------

   //<> timing specs (read)
   localparam ts_RD_DARL      = 6;
   localparam ts_RD_RW        = 308;
   localparam ts_RD_DRHA      = 20;
   localparam ts_RD_SDS       = 3;
   localparam ts_RD_HDRH      = 0;
   localparam ts_RD_RWR       = 29;

   //<> timing specs (write)
   localparam ts_WR_DAWL      = 7;
   localparam ts_WR_WW        = 308;
   localparam ts_WR_DWHA      = 21; //19;
   localparam ts_WR_DWHD      = 20;
   localparam ts_WR_WWR       = 28 ;
   localparam ts_WR_DDWH      = 316;

   localparam ts_WR_WRDsu     = ts_WR_DDWH - ts_WR_WW;
   localparam ts_WR_WRAsu     = ts_WR_WRDsu - ts_WR_DAWL;

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   reg [DATA_WIDTH-1:0] uC_data_out = 'bZ;  // default to tristate
   reg data_out_en = 0;          // internal data bus tristate control

   //<> --------------------------------------------
   //<> implement Bi-diretional bus tristate control
   assign iov_ami_data = (data_out_en) ? uC_data_out : 'bZ;

   //<>--------------------------------------------
   //<> task to write to the CPU-type interface
   task uc_write (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] data
      );
      string msg;
      begin
         //<> perform simulation cross checks and transcript output
         msg = {"write: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
         //<> begin transaction
         o_ami_rdn   = 1'b1;              // ensure read inactive
         o_ami_wrn   = 1'b1;              // ensure write inactive
         # 1;                             // start cycle delay
         uC_data_out = data;              // assert data onto bus...
         data_out_en = 1'b1;              // .. and switch data bus to output mode
         # (ts_WR_WRAsu);
         ov_ami_addr = address;           // assert address
         o_ami_msn   = 1'b0;              // assert memory select
         # (ts_WR_DAWL);
         o_ami_wrn   = 1'b0;              // assert write strobe
         //<>        << insert future AMI_ACK wait here?   >>
         # (ts_WR_WW);
         o_ami_wrn   = 1'b1;              // deassert write strobe
         # (ts_WR_DWHD);
         data_out_en = 1'b1;              // .. tristate data bus
         uC_data_out = 'bX;               // assert data onto bus...
         # (ts_WR_DWHA - ts_WR_DWHD);
         ov_ami_addr = 'bX;               // release bus to DON'T CARE state
         o_ami_msn   = 1'b1;
         # (ts_WR_WWR - ts_WR_DWHA);      // ensure turnaround seperation between cycles
      end
   endtask // cpu_write


   //<> -------------------------------------------------------------
   //<> task to read from the CPU-type interface
   task uc_read (
		   input [ADDR_WIDTH-1:0] address,
		   output [DATA_WIDTH-1:0] data
      );
      string msg;
      begin
         data_out_en = 1'b0;                              // ensure data bus in input/tri mode
         uC_data_out = 'bX;                               // clear internal data driver (avoid confusion)
         o_ami_rdn = 1'b1;                                // ensure read inactive
         o_ami_wrn = 1'b1;                                // ensure write inactive
         o_ami_msn = 1'b1;                                // ensure select inactive
         # 1;                                             // start cycle
         ov_ami_addr = address;                           // assert address
         o_ami_msn = 1'b0;                                // assert chipselect
         # (ts_RD_DARL);                                  // address setup to read strobe
         o_ami_rdn = 1'b0;                                // assert read
         //<>  << insert future AMI_ACK wait here?   >>
         # (ts_RD_RW-ts_RD_SDS);                          // data setup to write enable
         data = iov_ami_data;                             // latch data at earliest moment
         # (ts_RD_SDS);                                   // finish read strobe duration
         o_ami_rdn = 1'b1;                                // deassert read
         if (data != iov_ami_data) begin                  // verify earlier bus value against current...
            `SIM.printError(BFM_NAME, "SharcDSP read data setup time violation detected");
            data = iov_ami_data;                          // relatch data at OE edge moment if setup violation (minimize downstream sim errors)
         end
         # (ts_RD_DRHA);                                  // complete remaining ts_RD_OEn2p duration and end bus cycle
         ov_ami_addr = 'bX;                               // release bus to DON'T CARE state
         o_ami_msn = 1'b1;                                // deassert output enable (formal data latch point)
         # (ts_RD_RWR-ts_RD_DRHA);                        // ensure turnaround seperation between cycles
         //<> perform simulation cross checks and transcript output
         msg = {"read: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
      end
   endtask // cpu_read

   //<> --------------------------------------------------------------
   //<> Routine to verify data read vs expected, with simulation environment error calls and logging
   task check_data (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] expected_data,
		   input [DATA_WIDTH-1:0] actual_data
		   );
      string msg;
      begin
         if (expected_data == actual_data) begin
            msg = {"data check OK " };
            `SIM.printMessage (BFM_NAME, msg);
         end
         else begin
            msg = {"data check mismatch: expected data ", `V2HEXSTR(expected_data), " actual data ", `V2HEXSTR(actual_data), " @address ", `V2HEXSTR(address)};
            `SIM.printError (BFM_NAME, msg);
         end
      end
   endtask // check_data

   //<> -------------------------------------------------------------
   //<> task to read from the CPU-type interface for two consecutive registers
   //<>   - returns double wide data,
   //<>   - assumes lower-address = lower order byte
   //<>   - assumes registers are adjacent in map by one LSbit of address
   task uc_read_dw (
		   input [ADDR_WIDTH-1:0] address,
         output [(DATA_WIDTH*2)-1:0] data
      );
      begin
         uc_read(address,data[DATA_WIDTH-1:0]);                    // read lower order byte
         uc_read((address+1),data[(DATA_WIDTH*2)-1:DATA_WIDTH]);   // read higher order byte
      end
   endtask

   //<> -------------------------------------------------------------
   //<> task to write from the CPU-type interface for two consecutive registers
   //<>   - returns double wide data,
   //<>   - assumes lower-address = lower order byte
   //<>   - assumes registers are adjacent in map by one LSbit of address
   task uc_write_dw (
		   input [ADDR_WIDTH-1:0] address,
         input [(DATA_WIDTH*2)-1:0] data
      );
      begin
         uc_write(address,data[DATA_WIDTH-1:0]);                    // write lower order byte
         uc_write((address+1),data[(DATA_WIDTH*2)-1:DATA_WIDTH]);   // write higher order byte
      end
   endtask

endmodule

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 // bfm_SharcDSP_master
   // #( .BFM_NAME   ("bfm_SharcDSP_master "),
      // .DATA_WIDTH (8),
      // .ADDR_WIDTH (8)
   // ) bfm_SharcDSP_master_inst
   // (
      // .ov_ami_addr   (),   //  [ADDR_WIDTH-1:0]   address bus
      // .iov_ami_data  (),   //  [DATA_WIDTH-1:0]   bi-directional data
      // .o_ami_msn     (),   // memory select
      // .o_ami_rdn     (),   // read enable (active Low)
      // .o_ami_wrn     (),   // write enable (active Low)
      // .o_ami_ack     ()    // external wait request (low=inject waittime)    <<RFU>>
   // );
