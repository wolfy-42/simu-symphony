//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_TMS320_DSP.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : July 10st, 2012
//--------------------------------------------------------------------
//Description : BFM for Sharc DSP async AMI memory interfade. For Sharc DSP TMS320
//    - "ami" = Asynchronous Microprocessor Interface
//
// Datasheet:
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.4 $    $Date: 2012-09-07 14:33:39 $
//--------------------------------------------------------------------


`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_TMS320_DSP
   #( parameter BFM_NAME             = "bfm_TMS320_DSP",
      parameter DATA_WIDTH           = 8,
      parameter ADDR_WIDTH           = 8,
      parameter SILENT               = 0               // if true, suppress printMessage outputs
   )
   (
      //<> Asynchronous memory interface
      output reg  [ADDR_WIDTH-1:0]  ov_ami_addr = 0,   // address bus
      inout wire  [DATA_WIDTH-1:0]  iov_ami_data,      // bi-directional data
      output reg        o_ami_cs1n = 1'b1,             // control select
      output reg        o_ami_cs2n = 1'b1,             // memory select
      output reg        o_ami_oen  = 1'b1,             // read enable (active Low)
      output reg        o_ami_wrn  = 1'b1              // write enable (active Low)
      // input wire        i_ami_ack                   // external wait request (low=inject waittime)    <<RFU>>
   );

//<> ------------------------------------------------------------
//<> MODULE LOCAL PARAMETER/CONSTANTS
//<> ------------------------------------------------------------

   //<> ---------------------
   //<> TIMING SPECS
   //<>    - NOTE: ALL TIMES FROM START OF TRANSACTION
   parameter ts_FCLK_PERIOD          = 40 ;   // Period of DSP internal interface (assume 25MHz)
   parameter ts_C2C_GAP              = (ts_FCLK_PERIOD * 1);   // cycle to cycle gap
   parameter ts_CS_ONTIME            = (ts_FCLK_PERIOD * 0);
   //<> CS1 (control) Read Cycle
   parameter ts_ctrl_RD_CYCLETIME         = (ts_FCLK_PERIOD * 17);
   parameter ts_ctrl_RD_CS_OFFTIME        = (ts_FCLK_PERIOD * 16);
   parameter ts_ctrl_RD_OE_ONTIME         = (ts_FCLK_PERIOD * 3);
   parameter ts_ctrl_RD_OE_OFFTIME        = (ts_FCLK_PERIOD * 16);
   parameter ts_ctrl_RD_ACCESS_TIME       = (ts_FCLK_PERIOD * 15);   // data ready time
   //<> CS1 (control) Write Cycle
   parameter ts_ctrl_WR_CYCLETIME         = (ts_FCLK_PERIOD * 4);
   parameter ts_ctrl_WR_CS_ONTIME         = (ts_FCLK_PERIOD * 0);
   parameter ts_ctrl_WR_CS_OFFTIME        = (ts_FCLK_PERIOD * 2);
   parameter ts_ctrl_WR_WE_ONTIME         = (ts_FCLK_PERIOD * 0);
   parameter ts_ctrl_WR_WE_OFFTIME        = (ts_FCLK_PERIOD * 2);
   parameter ts_ctrl_WR_ACCESSTIME        = (ts_FCLK_PERIOD * 2);

      //<> CS2 (DDR2) Read Cycle
   parameter ts_ddr2_RD_CYCLETIME         = (ts_FCLK_PERIOD * 21);
   parameter ts_ddr2_RD_CS_OFFTIME        = (ts_FCLK_PERIOD * 16);
   parameter ts_ddr2_RD_OE_ONTIME         = (ts_FCLK_PERIOD * 3);
   parameter ts_ddr2_RD_OE_OFFTIME        = (ts_FCLK_PERIOD * 16);
   parameter ts_ddr2_RD_ACCESS_TIME       = (ts_FCLK_PERIOD * 15);   // data ready time
   //<> CS2 (DDR2) Write Cycle
   parameter ts_ddr2_WR_CYCLETIME         = (ts_FCLK_PERIOD * 4);
   parameter ts_ddr2_WR_CS_ONTIME         = (ts_FCLK_PERIOD * 0);
   parameter ts_ddr2_WR_CS_OFFTIME        = (ts_FCLK_PERIOD * 2);
   parameter ts_ddr2_WR_WE_ONTIME         = (ts_FCLK_PERIOD * 0);
   parameter ts_ddr2_WR_WE_OFFTIME        = (ts_FCLK_PERIOD * 2);
   parameter ts_ddr2_WR_ACCESSTIME        = (ts_FCLK_PERIOD * 2);


//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   reg [DATA_WIDTH-1:0] uC_data_out = 'bZ;  // default to tristate
   reg data_out_en = 0;          // internal data bus tristate control

   //<> internal copy of requested transfers
   reg [ADDR_WIDTH-1:0] int_address;
   reg [DATA_WIDTH-1:0] int_rd_data;
   reg [DATA_WIDTH-1:0] int_wr_data;
   reg rd_wr_sel;       // 1=read, 0=write
   reg ctrl_ddr2_sel;   // 1=ctrl, 0=ddr2

   event transaction;  // signal from tasks to stimulate module ports

//<>--------------------------------------------------------------
//<> SIMULATION CONTROL TASKS
//<>--------------------------------------------------------------

   //<> --------------------------------------------
   //<> implement Bi-diretional bus tristate control
   assign iov_ami_data = (data_out_en) ? uC_data_out : 'bZ;

   //<> -------------------------------------------------------------
   //<> task to read for CS1 Control mode
   task uc_read_ctrl (
		   input [ADDR_WIDTH-1:0] address,
		   output [DATA_WIDTH-1:0] data
   );
      string msg;
      begin
         // //<> start cycle
         int_address = address;
         rd_wr_sel     = 1;
         ctrl_ddr2_sel = 1;
         ->transaction;                                                                   // kick transaction
         #(ts_ctrl_RD_CYCLETIME);                                                         // wait for end of cycle
         data = int_rd_data;                                                              // return read data to caller
         //<> perform simulation transcript output (if enabled)
         msg = {"read_ctrl: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
         # (ts_C2C_GAP);                                                                  // ensure turnaround seperation between cycles
      end
   endtask // cpu_read

   //<>--------------------------------------------
   //<> task to write for CS1 Control mode
   task uc_write_ctrl (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] data
      );
      string msg;
      begin
         //<> perform simulation cross checks and transcript output
         msg = {"write_ctrl: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
         int_address = address;
         rd_wr_sel     = 0;
         ctrl_ddr2_sel = 1;
         uC_data_out = data;                                                               // map requested wr data to internal output vector
         ->transaction;                                                                    // kick transaction
         #(ts_ctrl_WR_CYCLETIME);                                                          // wait for end of cycle
         uC_data_out = 0;                                                                  // clear internal data
      end
   endtask // cpu_write

   //<> -------------------------------------------------------------
   //<> task to read for CS2 DDR2 mode
   task uc_read_ddr2 (
		   input [ADDR_WIDTH-1:0] address,
		   output [DATA_WIDTH-1:0] data
   );
      string msg;
      begin
         //<> start cycle
         int_address = address;
         rd_wr_sel     = 1;
         ctrl_ddr2_sel = 0;
         ->transaction;                                                                   // kick transaction
         #(ts_ddr2_RD_CYCLETIME);                                                         // wait for end of cycle
         data = int_rd_data;                                                              // return read data to caller
         //<> perform simulation transcript output (if enabled)
         msg = {"read_ddr2: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
         # (ts_C2C_GAP);                                                                  // ensure turnaround seperation between cycles
      end
   endtask // cpu_read

   //<>--------------------------------------------
   //<> task to write for CS1 ddr2 mode
   task uc_write_ddr2 (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] data
      );
      string msg;
      begin
         //<> perform simulation cross checks and transcript output
         msg = {"write_ddr2: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
         int_address = address;
         rd_wr_sel     = 0;
         ctrl_ddr2_sel = 0;
         uC_data_out = data;                                                               // map requested wr data to internal output vector
         ->transaction;                                                                    // kick transaction
         #(ts_ddr2_WR_CYCLETIME);                                                          // wait for end of cycle
         uC_data_out = 0;                                                                  // clear internal data
      end
   endtask // cpu_write



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

//<>--------------------------------------------------------------
//<> IO PORT CONTROLS
//<>--------------------------------------------------------------

   //<>--------------------------------------------------------------
   //<> Chipselect control
   always
   begin
      o_ami_cs1n = 1'b1;           // ensure select inactive
      o_ami_cs2n = 1'b1;           // ensure select inactive
      @(transaction);              // wait for start of transaction request
      ov_ami_addr = int_address;
      #(ts_CS_ONTIME);             // delay for start of chipselect
      if (ctrl_ddr2_sel) begin     // ctrl-mode
         o_ami_cs1n = 1'b0;        // assert cs1
         //#(ts_FCLK_PERIOD) ov_ami_addr = int_address;
         if (rd_wr_sel) begin      // control read mode
            #(ts_ctrl_RD_CS_OFFTIME - ts_CS_ONTIME);
         end
         else begin                // control write mode
            #(ts_ctrl_WR_CS_OFFTIME - ts_CS_ONTIME);
         end
      end
      else begin                   // DDR2-mode
         o_ami_cs2n = 1'b0;        // assert cs2
         if (rd_wr_sel) begin      // ddr2 read mode
            #(ts_ddr2_RD_CS_OFFTIME - ts_CS_ONTIME);
         end
         else begin                // ddr2 write mode
            #(ts_ddr2_WR_CS_OFFTIME - ts_CS_ONTIME);
         end
      end
   end // always

   //<>--------------------------------------------------------------
   //<> WR control
   always
   begin
      o_ami_wrn = 1'b1;                                       // ensure select inactive
      data_out_en = 1'b0;                                     // set bus for reading
      @(transaction);                                         // wait for start of transaction request
      if (~rd_wr_sel) begin                                   // action required only in write mode
         if (ctrl_ddr2_sel) begin                             // ctrl-mode -----------
            #(ts_ctrl_WR_WE_ONTIME);                          // delay start of WR
            data_out_en = 1'b1;
            o_ami_wrn = 1'b0;
            #(ts_ctrl_WR_WE_OFFTIME - ts_ctrl_WR_WE_ONTIME);  // delay end of WR
         end
         else begin                                           // DDR2 mode -----------
            #(ts_ddr2_WR_WE_ONTIME);                          // delay start of WR
            data_out_en = 1'b1;
            o_ami_wrn = 1'b0;
            #(ts_ddr2_WR_WE_OFFTIME - ts_ddr2_WR_WE_ONTIME);  // delay end of WR
         end
      end
   end // always

   //<>--------------------------------------------------------------
   //<> OE control
   always
   begin
      o_ami_oen = 1'b1;                                       // ensure select inactive
      @(transaction);                                         // wait for start of transaction request
      if (rd_wr_sel) begin                                    // action required only in read mode
         if (ctrl_ddr2_sel) begin                             // ctrl-mode ------------
            #(ts_ctrl_RD_OE_ONTIME);                          // delay start of OE
            o_ami_oen = 1'b0;
            #(ts_ctrl_RD_OE_OFFTIME - ts_ctrl_RD_OE_ONTIME);  // delay end of OE
         end
         else begin                                           // DDR2 mode ----------
            #(ts_ddr2_RD_OE_ONTIME);                          // delay start of OE
            o_ami_oen = 1'b0;
            #(ts_ddr2_RD_OE_OFFTIME - ts_ddr2_RD_OE_ONTIME);  // delay end of OE
         end
         int_rd_data = iov_ami_data;
      end
   end // always

endmodule

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"
// End:

 // bfm_TMS320_DSP
   // #( .BFM_NAME   ("bfm_TMS320_DSP "),
      // .DATA_WIDTH (8),
      // .ADDR_WIDTH (8)
   // ) bfm_TMS320_DSP_inst
   // (
      // .ov_ami_addr   (),   //  [ADDR_WIDTH-1:0]   address bus
      // .iov_ami_data  (),   //  [DATA_WIDTH-1:0]   bi-directional data
      // .o_ami_cs1n     (),   // memory select
      // .o_ami_oen     (),   // read enable (active Low)
      // .o_ami_wrn     (),   // write enable (active Low)
      // .o_ami_ack     ()    // external wait request (low=inject waittime)    <<RFU>>
   // );






            // data_out_en = 1'b0;                           // ensure data bus in input/tri mode
            // uC_data_out = 'bX;                            // clear internal data driver (avoid confusion)
            // o_ami_oen = 1'b1;                             // ensure read inactive
            // o_ami_wrn = 1'b1;                             // ensure write inactive
            // o_ami_cs1n = 1'b1;                             // ensure select inactive
            // o_ami_cs2n = 1'b1;                             // ensure select inactive
            // ov_ami_addr = address;                        // assert address
         // # (ts_ctrl_RD_CS_ONTIME);                                  // address setup to read strobe
            // o_ami_cs1n = 1'b0;                             // assert chipselect
         // # (ts_ctrl_RD_OE_ONTIME-ts_ctrl_RD_CS_ONTIME);            // address setup to read strobe
            // o_ami_oen = 1'b0;                             // assert read
         // //<>        << insert future AMI_ACK wait here?   >>
         // # (ts_ctrl_RD_OE_ACTIVE-ts_ctrl_RD_DsuOEhigh);            // data setup to write enable
            // data = iov_ami_data;                          // latch data at earliest moment
         // # (ts_ctrl_RD_DsuOEhigh);                                   // finish read strobe duration
            // o_ami_oen = 1'b1;                             // deassert read
            // if (data != iov_ami_data) begin               // verify earlier bus value against current...
               // `SIM.printError(BFM_NAME, "SharcDSP read data setup time violation detected");
               // data = iov_ami_data;                       // relatch data at OE edge moment if setup violation (minimize downstream sim errors)
            // end
         // # (ts_ctrl_RD_OEhighDhld);                            // complete remaining data hold duration and end bus cycle
            // // ov_ami_addr = 'bX;                            // release bus to DON'T CARE state
            // ov_ami_addr = 'b0;                            // release bus to DON'T CARE state
         // # (ts_ctrl_RD_CS_OFFTIME - ts_ctrl_RD_OE_OFFTIME - ts_ctrl_RD_OEhighDhld);   // finish chipselect period
            // o_ami_cs1n = 1'b1;                             // deassert output enable (formal data latch point)
