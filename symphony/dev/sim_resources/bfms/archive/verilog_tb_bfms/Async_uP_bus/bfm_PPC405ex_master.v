//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_PPC405ex_master.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : April 21st, 2012
//--------------------------------------------------------------------
//Description : BFM for PPC-405ex parallel interface.
//
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2014-01-24 15:10:28 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

//<> uncomment to enable additional diagnostic logfile reporting
// `define DEBUG

  module bfm_PPC405ex_master
   #( parameter DATA_WIDTH = 16,                      // width of external data bus (#bits)
      parameter ADDR_WIDTH = 16,                      // width of external Address bus (#bits)
      parameter CLK_PERIOD = 10,                      // bus Clock period (ns)
      parameter SILENT     = 0                        // if true, suppress printMessage outputs
   )
   (  output reg  [ADDR_WIDTH-1:0]  ov_uC_addr = 0,   // address bus
      inout wire  [DATA_WIDTH-1:0]  iov_uC_data ,     // bidirectional data bus
      output reg  [1:0] o_uC_csn  = 2'b11,            // chipselect [CS3,CS2]
      output reg  o_uC_wen  = 1'b1,                   // write enable (active low)
      output reg  o_uC_oen  = 1'b1                    // output enable (active low)
   );

//<> ------------------------------------------------------------
//<> MODULE LOCAL PARAMETER/CONSTANTS
//<> ------------------------------------------------------------
   localparam BFM_NAME            = "bfm_PPC405ex_master";
   localparam CSN_spec            = 3;    // bus clocks start to chipselect
   localparam TWR_spec            = 20;   // bus clocks transaction active
   localparam TH_spec             = 7;    // bus clocks data hold after cs release
   localparam OEN_spec            = 0;    // bus clocks chipselect to output enable

   localparam ts_TAmin            = 0;    // minimum time between bus cycles

   //<> timing specs (read)
   localparam ts_RD_ADsu2CSn      = (CSN_spec * CLK_PERIOD);                 // delay from Address/Data setup ahead of CS assert (write)
   localparam ts_RD_CSdur         = ((TWR_spec - CSN_spec) * CLK_PERIOD);    // active duration of WR (write)
   localparam ts_RD_CS2ADrel      = (TH_spec * CLK_PERIOD);                  // data setup ahead of WR deasset (write)
   localparam ts_RD_CSn2OEn       = (OEN_spec * CLK_PERIOD);                 // active duration of OE (read)
   localparam ts_RD_OEnDur        = ((TWR_spec - CSN_spec) * CLK_PERIOD);    // active duration of OE (read)

   //<> timing specs (write)
   localparam ts_WR_ADsu2CSn      = (CSN_spec * CLK_PERIOD);                 // delay from Address/Data setup ahead of CS assert (write)
   localparam ts_WR_CSdur         = ((TWR_spec - CSN_spec) * CLK_PERIOD);    // active duration of WR (write)
   localparam ts_WR_CS2WRrel      = (TH_spec * CLK_PERIOD);                  // data setup ahead of WR deasset (write)

//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------
   reg [DATA_WIDTH-1:0] uC_data_out = 'bZ;      // default to tristate
   reg data_out_en = 1'b0;                      // internal data bus tristate control


   //<> --------------------------------------------
   //<> implement Bi-diretional bus tristate control
   assign iov_uC_data = (data_out_en) ? uC_data_out : 'bZ;


   //<>--------------------------------------------
   //<> task to write to the CPU-type interface
   task uc_write (
		   input [ADDR_WIDTH-1:0] address,
		   input [DATA_WIDTH-1:0] data,
         input cs_sel  = 0                   // 0=cs2, 1=cs3
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
            ov_uC_addr = address;
            o_uC_oen = 1'b1;
            o_uC_wen = 1'b0;                // write direction
            data_out_en = 1;                // switch data bus to output mode
            uC_data_out = data;             // assert data onto bus
         # (ts_WR_ADsu2CSn);
            o_uC_csn[cs_sel] = 1'b0;        // assert chipselect
         # (ts_WR_CSdur);                   // write cycle active
            o_uC_csn = 2'b11;               // deassert chipselect
         # (ts_WR_CS2WRrel);                // data hold
            o_uC_wen = 1'b1;
            ov_uC_addr = 'bZ;               // release bus to tristate state
            o_uC_oen = 1'b1;
            data_out_en = 0;                // switch data bus to tristate mode
            uC_data_out = 'b0;              // clear internal data driver (garbage collection)
         # (ts_TAmin);                      // ensure turnaround seperation between cycles
      end
   endtask // cpu_write


   //<> -------------------------------------------------------------
   //<> task to read from the CPU-type interface
   task uc_read (
		   input [ADDR_WIDTH-1:0] address,
		   output [DATA_WIDTH-1:0] data,
         input cs_sel = 0                    // 0=cs2, 1=cs3
      );
      string msg;
      string a_str;
      string b_str;
      begin
            ov_uC_addr = address;
            o_uC_oen = 1'b1;                  // ensure output enable initialy deasserted
            o_uC_wen = 1'b1;                  // read direction
            data_out_en = 1'b0;               // ensure data bus in input/tri mode
            uC_data_out = 'b0;                // clear internal data driver (avoid confusion)
         # (ts_RD_ADsu2CSn);
            o_uC_csn[cs_sel] = 1'b0;          // assert chipselect
         # (ts_RD_CSn2OEn);                   // data setup to write enable
            o_uC_oen = 1'b0;
         # (ts_RD_OEnDur);                    // read cycle active minus data setup
            data = iov_uC_data;               // latch data at earliest moment
            o_uC_oen = 1'b1;                  // deassert output enable (formal data latch point)
            o_uC_csn = 2'b11;                 // deassert chipselect
            // if (data != iov_uC_data) begin
               // `SIM.printError(BFM_NAME, "read data setup time violation detected");
               // data = iov_uC_data;            // relatch data at OE edge moment if setup violation (minimize downstream sim errors)
            // end
         // # (ts_RD_Dhld);                      // wait and verify data hold
            // if (data != iov_uC_data)
               // `SIM.printError(BFM_NAME, "read data hold time violation detected");
         # (ts_RD_CS2ADrel);      // complete remaining ts_RD_OEn2p duration and end bus cycle
            ov_uC_addr = 'bZ;                 // release bus to DON'T CARE state
            data_out_en = 1'b0;               // leave data bus to tristate mode
         # (ts_TAmin);                        // ensure turnaround seperation between cycles
         //<> perform simulation transcript output
         msg = {"read: addresss: ", `V2HEXSTR(address)," data: ", `V2HEXSTR(data)};  // build output message string
      `ifdef DEBUG
         `SIM.printMessage (BFM_NAME, msg);
      `else
         if (!SILENT) `SIM.printMessage (BFM_NAME, msg);
      `endif
      end
   endtask // cpu_read

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
            `SIM.printMessage (BFM_NAME, msg);
         end
         else begin
            msg = {"TI_DSP data bad, expected data ", a_str, " actual data ", b_str, " address ", c_str};
            `SIM.printError (BFM_NAME, msg);
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

// bfm_PPC405ex_master
   // #( .DATA_WIDTH (16),
      // .ADDR_WIDTH (16),
      // .CLK_PERIOD (10),
      // .SILENT (0)
   // ) bfm_PPC405ex_master_inst
      // .ov_uC_addr    (),   // [ADDR_WIDTH-1:0]
      // .iov_uC_data   (),   // [DATA_WIDTH-1:0]
      // .o_uC_csn      (),   // [cs3,cs2]
      // .o_uC_wen      (),
      // .o_uC_oen      ()
   // );

