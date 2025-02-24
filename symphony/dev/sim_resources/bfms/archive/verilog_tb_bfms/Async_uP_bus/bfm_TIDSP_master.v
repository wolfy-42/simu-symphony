//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_TIDSP_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : April 21st, 2012
//--------------------------------------------------------------------
//Description : BFM for TI DSP slow RAM interface. For TI DSP TMS320C6748
//
// datasheet: http://www.ti.com/product/tms320c6748?DCMP=dsp-c6-lcdk-120524&HQS=dsp-c6-lcdk-pr-pf1
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.10 $    $Date: 2012-06-13 09:55:33 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

  module bfm_TIDSP_master
   #( parameter DATA_WIDTH = 16,                      // width of external data bus (#bits)
      parameter ADDR_WIDTH = 8,                       // width of external Address bus (#bits)
      parameter SILENT     = 0                        // if true, suppress printMessage outputs
   )
   (  output reg  [ADDR_WIDTH-1:0]  ov_uC_addr = 0,   // address bus
      inout wire  [DATA_WIDTH-1:0]  iov_uC_data ,     // bidirectional data bus
      output reg        o_uC_csn = 1'b1,              // chipselect
      output reg        o_uC_rwn = 1'b1,              // read/(write) select (1=read)
      output reg        o_uC_wen = 1'b1,              // write enable (active low)
      output reg        o_uC_oen = 1'b1               // output enable (active low)
   );

//<> ------------------------------------------------------------
//<> MODULE LOCAL PARAMETER/CONSTANTS
//<> ------------------------------------------------------------

   localparam BFM_NAME       = "bfm_TIDSP_master";
   //<> timing specs (read)
   localparam ts_RD_Asu2CSn  = 1;     // delay from address setup ahead of CS assert (read)
   localparam ts_RD_CSn2OEn  = 20;    // delay from CS assert until OE assert (read)
   localparam ts_RD_OEn2p    = 120;   // active duration of OE (read)
   localparam ts_RD_Dsu      = 5;     // data setup ahead of OE deasset (read)
   localparam ts_RD_Dhld     = 0;     // data hold after OE deasset (read)
   localparam ts_RD_OEp2CSp  = 40;    // data hold after OE deasset (read)
   //<> timing specs (write)
   localparam ts_WR_ADsu2CSn = 1;     // delay from Address/Data setup ahead of CS assert (write)
   localparam ts_WR_CSn2WEn  = 30;    // delay from CS assert until WR assert (write)
   localparam ts_WR_WRdur    = 70;    // active duration of WR (write)
   localparam ts_WR_Dsu      = 30;    // data setup ahead of WR deasset (write)
   localparam ts_WR_Dhold    = 30;    // data hold after WR deasset (write)
   localparam ts_WR_WRp2CSp  = 30;    // WR deassert to CS deassert delay
   localparam ts_TAmin       = 40;    // minimum time between bus cycles (write)

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   reg [DATA_WIDTH-1:0] uC_data_out = 'bZ;   // default to tristate
   reg data_out_en = 0;                      // internal data bus tristate control


   //<> --------------------------------------------
   //<> implement Bi-diretional bus tristate control
   assign iov_uC_data = (data_out_en) ? uC_data_out : 'bZ;


   //<>--------------------------------------------
   //<> task to write to the CPU-type interface
   task uc_write (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] data
      );
         string msg;
         string a_str;
         string b_str;
      begin
         // perform simulation cross checks and transcript output
         msg = {"write: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
   `ifdef DEBUG
         `SIM.printMessage (BFM_NAME, msg);
   `else
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
   `endif
         #(1);                      // start cycle
         ov_uC_addr = address;
         o_uC_oen = 1'b1;
         o_uC_rwn = 1'b1;           // write direction
         o_uC_wen = 1'b1;           // write direction
         data_out_en = 1;           // switch data bus to output mode
         uC_data_out = data;        // assert data onto bus
         #(ts_WR_ADsu2CSn);
         o_uC_csn = 1'b0;           // assert chipselect
         o_uC_rwn = 1'b0;           // write direction
         #(ts_WR_CSn2WEn);          // data setup to write enable
         o_uC_wen = 1'b0;
         #(ts_WR_WRdur);            // write cycle active
         o_uC_wen = 1'b1;
         #(ts_WR_WRp2CSp);          // data hold
         o_uC_csn = 1'b1;           // deassert chipselect
         ov_uC_addr = 'bX;          // release bus to DON'T CARE state
         o_uC_oen = 1'b1;
         o_uC_rwn = 1'b1;           // release to read direction
         data_out_en = 0;           // switch data bus to tristate mode
         uC_data_out = 'b0;         // clear internal data driver (garbage collection)
         #(ts_TAmin);               // ensure turnaround seperation between cycles
      end
   endtask // cpu_write


   //<> -------------------------------------------------------------
   //<> task to read from the CPU-type interface
   task uc_read (
		   input [ADDR_WIDTH-1:0] address,
		   output [DATA_WIDTH-1:0] data
      );
      string msg;
      string a_str;
      string b_str;
      begin
         # 1;                                                                        // start cycle
         ov_uC_addr = address;
         o_uC_wen = 1'b1;                                                            // read direction
         o_uC_rwn = 1'b1;                                                            // read direction
         o_uC_oen = 1'b1;                                                            // ensure output enable initialy deasserted
         data_out_en = 1'b0;                                                         // ensure data bus in input/tri mode
         uC_data_out = 'b0;                                                          // clear internal data driver (avoid confusion)
         # (ts_RD_Asu2CSn);
         o_uC_csn = 1'b0;                                                            // assert chipselect
         # (ts_RD_CSn2OEn);                                                          // data setup to write enable
         o_uC_oen = 1'b0;
         # (ts_RD_OEn2p - ts_RD_Dsu);                                                // read cycle active minus data setup
         data = iov_uC_data;                                                         // latch data at earliest moment
         # (ts_RD_Dsu);                                                              // complete ts_RD_OEn2p duration
         o_uC_oen = 1'b1;                                                            // deassert output enable (formal data latch point)
         if (data != iov_uC_data) begin
            `SIM.printError(BFM_NAME, "read data setup time violation detected");
            data = iov_uC_data;                                                      // relatch data at OE edge moment if setup violation (minimize downstream sim errors)
         end
         # (ts_RD_Dhld);                                                             // wait and verify data hold
         if (data != iov_uC_data)
            `SIM.printError(BFM_NAME, "read data hold time violation detected");
         # (ts_RD_OEp2CSp - ts_RD_Dhld);                                             // complete remaining ts_RD_OEn2p duration and end bus cycle
         o_uC_csn = 1'b1;                                                            // assert chipselect
         ov_uC_addr = 'bX;                                                           // release bus to DON'T CARE state
         o_uC_rwn = 1'b1;                                                            // leave bus in read mode (default)
         data_out_en = 1'b0;                                                         // leave data bus to tristate mode
         # (ts_TAmin);                                                               // ensure turnaround seperation between cycles
         //<> perform simulation transcript output
         msg = {"read: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
      `ifdef DEBUG
         `SIM.printMessage (BFM_NAME, msg);
      `else
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
      `endif
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
      string a_str;
      string b_str;
      string c_str;
      begin
         lib_math_inst.hex2a(expected_data,1,a_str);
         lib_math_inst.hex2a(actual_data,1,b_str);
         lib_math_inst.hex2a(address,1,c_str);
         if (expected_data == actual_data) begin
            msg = {"TI_DSP data read OK " };
            `SIM.printMessage(BFM_NAME, msg);
         end
         else begin
            msg = {"TI_DSP data bad, expected data ", a_str, " actual data ", b_str, " address ", c_str};
            `SIM.printError(BFM_NAME, msg);
         end
      end
   endtask // check_data

endmodule

//* -----------------------------Outline--------------------------------
//  --------------------------------*-----------------------------------
//######################################################################
// Local Variables:
// mode: outline-minor
// outline-regexp: " *\/\/\\*"

// bfm_TIDSP_master
   // #( .DATA_WIDTH (16),
      // .ADDR_WIDTH (8),
      // .SILENT (0)
   // ) bfm_TIDSP_master_inst
      // .ov_uC_addr    (),   // [ADDR_WIDTH-1:0]
      // .iov_uC_data   (),   // [DATA_WIDTH-1:0]
      // .o_uC_csn      (),
      // .o_uC_rwn      (),
      // .o_uC_wen      (),
      // .o_uC_oen      ()
   // );

