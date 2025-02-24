//--------------------------------------------------------------------
//Copyright (C) 2006-2023 Fidus Systems Inc. 
//SPDX-License-Identifier: Apache-2.0 OR MIT
//The licenses stated above take precedence over any other contracts, agreements, etc.
//--------------------------------------------------------------------
//File name   : bfm_HD_framer.v
//Project     : RIPL
//Author      : Arnold Balisch
//Created     : March 31, 2015
//--------------------------------------------------------------------
//Description : BFM for streaming HD video frame output
//    - output registered relative to FALLING edge of output Clock
//
// User-Accessable Task/Function calls:
// ---------------------------------------
//    - task DriveFail (input reg newval);      -- force drive fail output
//    - task TrafficControl (input reg newval);  -- enable/disable traffic generation
//
//--------------------------------------------------------------------
// $Author: Arnold.Balisch $     $Revision: 1.8 $    $Date: 2015-06-10 14:44:51 $
//--------------------------------------------------------------------

`include "./bfms/bfm_common.hv"     // include common timing spec and task heirarchy alias defines

`define ENABLE  1'b1
`define DISABLE 1'b0

module bfm_HD_framer
   #( parameter BFM_NAME       = "bfm_HD_framer",
      parameter PCLK_PERIOD    = 20ns,   // clock period in ns
      parameter PIXEL_WIDTH    = 10,     // NOTE: this value NOT to be user adjustable!
      parameter PIXEL_PER_CLK  = 2,      // NOTE: this value NOT to be user adjustable!
      parameter SILENT         = 1     // if true, suppress printMessage outputs
   )
   (
      //<> DSS interface
      output reg o_pclk       = 0,
      output reg [(PIXEL_WIDTH*PIXEL_PER_CLK)-1:0]  ov_vdata = 0,          // video data
      output reg o_vsync      = 0,
      output reg o_hsync      = 0,
      output reg o_ac_bias_en = 0,
      output reg o_fail_n     = 0,
      output reg o_enable     = 0,
      input wire o_rec_all,
      //<> testbench control/status
      // input  wire  i_tx_en,         // system transfer enable
      output event new_row_event    // pings before the start of every new image row (active or blanking)
   );


//<> ------------------------------------------------------------
//<> PARAMETER/CONSTANTS
//<> ------------------------------------------------------------

   //<> TIMING SPECS
   //<>    - NOTE: ALL "ONTIME"s measured from START OF TRANSACTION

   //<> columns/row
   parameter  p_ACT_VID_COLUMNS       = 1952;    // number of ACTIVE video columns
   parameter  p_HSYNC_CNT             = 16;      // number of PCLK cycles active
   parameter  p_BACK_PORCH_CNT        = 16;      // number of PCLK cycles active
   localparam p_PIXEL_COUNT           = p_ACT_VID_COLUMNS/2;      // number of PCLK cycles active (two pixels/clk)
   parameter  p_FRONT_PORCH_CNT       = 16;      // number of PCLK cycles active
   parameter  p_RAM_LWORDS_PER_PIXROW = 64/4;  //

   //<> rows/frame
   parameter  p_NUM_VSYNC_ROWS       = 1;       // number of prefix video rows
   parameter  p_NUM_TOP_PORCH_ROWS   = 1;       // number of prefix video rows
   parameter  p_ACT_VID_NUM_ROWS     = 1088;    // number of ACTIVE video rows
   parameter  p_NUM_BOT_PORCH_ROWS   = 1;       // number of prefix video rows


//<> ------------------------------------------------------------
//<> INTERNAL BFM VARIABLES
//<> ------------------------------------------------------------

   //<> Row tracking statemachine datastructures
   typedef enum integer
                { F_IDLE      ,   //
                  VSYNC       ,   //
                  TOP_PORCH   ,   //
                  ACT_IMAGE   ,   //  - active pixel data
                  BOT_PORCH       //
                  } t_frame_state_type;

   t_frame_state_type frame_state = F_IDLE;

   //<> column/pixel tracking statemachine datastructures
   typedef enum integer
                { POR         ,   //  -   initial power on diabled state
                  HSYNC       ,   //  -\
                  BK_PORCH    ,   //    \ 'N' rows
                  BLANK_ROW   ,   //    /  output
                  ACT_ROW     ,   //    /
                  FNT_PORCH       //  -/
                  } t_row_state_type;

   t_row_state_type row_state = POR;

   //<> frame position counters (for statemachines)
   integer row_count = 0;
   integer col_count = 0;

   //<> Create a full Video frame test pattern
   reg [5:0] stim_high ;
   reg [1:0] stim_low ;
   integer rep, x, y, z;
   integer curr_pixel;
   integer num_tst_rows = p_ACT_VID_NUM_ROWS;   // default to standard row count

   //<> 3D array for testpattern
   reg [PIXEL_WIDTH-1:0] full_frame [p_ACT_VID_NUM_ROWS-1:0][p_ACT_VID_COLUMNS-1:0];   // 1088row x 1920col @ 10bits/pixel
   reg [PIXEL_WIDTH-1:0] tmp;

   //<> frame flow-control
   reg row_enable   = `ENABLE;    // column statemachine flag to halt at HSYNC
   reg frame_enable = `DISABLE;  // row statemachine flag to halt at VSYNC
   event stop_start_evnt;

//<> ------------------------------------------------------------
//<> USER ACCESSABLE TASK/FUCTION CALLS
//<> ------------------------------------------------------------

   //<>--------------------------------------------------------------
   //<> user-called task to drive o_fail_n ouptut to requested logic level
   task DriveFail (input newval);
      begin
         if (!SILENT) `SIM.printMessage(BFM_NAME, {"output o_fail_n driven to : ", `V2HEXSTR(newval) });
         o_fail_n = newval;
      end
   endtask


   //<>--------------------------------------------------------------
   //<> user-called task to drive o_enable ouptut to requested logic level
   //<>  - '0' = stop traffic
   //<>  - '1' = start traffic
   task TrafficControl (input newval);
      begin
         frame_enable = newval;      // set internal statemachine control flag
         if (!SILENT) `SIM.printMessage(BFM_NAME, {"output o_enable driven to : ", `V2HEXSTR(newval) });
      end
   endtask

   //<>--------------------------------------------------------------
   //<> user-called task to drive o_enable ouptut to requested logic level
   //<>  - '0' = stop traffic
   //<>  - '1' = start traffic
   task ChgNumActiveRows (input integer newval);
      begin
         num_tst_rows = newval;      // set internal statemachine control flag
         if (!SILENT) `SIM.printMessage(BFM_NAME, {"changing number of active rows to: ", `V2HEXSTR(newval) });
      end
   endtask

//<>--------------------------------------------------------------
//<> INTERNAL-USE-ONLY FUNCTIONS AND TASKS
//<>--------------------------------------------------------------

   //<>--------------------------------------------------------------
   //<> generate pixel values to ID each Active pixel by row/col in Active region
   //<> - two pixels output per pclk period..align with start of active region (remove blanking)
   //<> - NOTE: because of size of pixel vs size of frame, count cropping will occur.
   //<>        --> max count =  2^(PIXEL_WIDTH/2)
   function reg [(PIXEL_WIDTH*PIXEL_PER_CLK)-1:0] MakePixelPair (
               input int row,
               input int col);
         reg [6:0] col_reg;     // half of pixel width
         reg [2:0] row_reg;     // half of pixel width
         reg [9:0] pixel;                // half of pixel width
      begin
         col_reg = col ;            // remove leading blanking from count and crop to half of PIXEL_WIDTH
         row_reg = row ;    // remove leading blanking from count and crop to half of PIXEL_WIDTH
         pixel = col_reg * 2;  // 2 pixels per pclk cycle/count
         MakePixelPair = {pixel, row_reg, col_reg};     // build/return result value
      end
   endfunction


//<> ------------------------------------------------------------
//<> INTERNAL BFM PROCESSES
//<> ------------------------------------------------------------

   //<> ------------------------------------------------------------
   //<> Initializations
   //<> ------------------------------------------------------------

   //<> Generate a testpattern for the HD Frame's ActiveArea
   initial begin
      #1ns;    // avoid tsim=0ns conjestion
      for (rep=0; rep<p_ACT_VID_NUM_ROWS; rep=rep+1) begin    // number of rows of video frame to transfer
         curr_pixel = 0;  // reset pixel_column position pointer
         for (x=0; x<64; x=x+1) begin    // 64 clusters of 32bit words Upper [7:2]
            stim_high = x;                // high [7:2] pattern
            // if (SILENT) `SIM.printMessage(TC_NAME, {" DMA_FRAME ======================= upper range bits[7:2]=", `V2BINSTR(stim_high)});
            for (y=0; y<8; y=y+1) begin           // 8 clusters of 4 writes per stim_high pattern (32 writes total per increment of bits[7:2]
               // if (SILENT) `SIM.printMessage(TC_NAME, {" DMA_FRAME --------------- 32 word cluster boundary#", `V2INTSTR(y)});
               for (z=0; z<4; z=z+1) begin      // Low [1:0] bits patern
                  if (stim_high[5] == 1'b0) begin    // check if we are in the A or B pattern
                     stim_low = z;              // low pattern A: y=0(0,1,2,3), y=1(4,5,6,7)..y=3(C,D,E,F) & repeat
                  end
                  else begin
                     stim_low = z + 1 ;         // low pattern B: y=5(1,2,3,0), y=6(5,6,7,4)..y=7(D,E,F.C) & repeat (shifted by one count)
                  end
                  // if ({stim_high, stim_low} < 'b111100_00) begin
                  if (curr_pixel < p_ACT_VID_COLUMNS) begin    // avoid array indexing beyond valid 1952 columns
                     tmp = {2'b0, stim_high, stim_low}; // build 10bit pixel
                     full_frame[rep][curr_pixel] = tmp; // build frame of 10bit pixels
                  end
                  curr_pixel++;    // increment pixel/col pointer for next pass
                  // #1;      //<> debug delay for waveform viewing (do not use for live sim)
               end // for z loop lower bits
            end // for y loop upper bits
         end // for x loop clusters
      end // for rep loop rows
   end // initial


//<>--------------------------------------------------------------
//<> CONTROL ROUTINES
//<>--------------------------------------------------------------

   //<> Gated Bus clock driver and enable control
   initial
   begin
      while (1) begin                        // repeate until infinity
         if (frame_enable) begin             // - clock startup/normal run
            #(PCLK_PERIOD/2) o_pclk = ~o_pclk; //  toggling clock
         end
         else begin                          // - frame_enable=0 --> user traffic stop request logged
            if (o_enable) begin              // -- waiting for current frame to complete
               #(PCLK_PERIOD/2) o_pclk = ~o_pclk;     // keep clock toggling until frame finished
            end
            else begin                       // -- frame finished, statemachines halted --> commence clean clock shutdown
               if (o_pclk) begin             // --- if clock high, alow to finish high-dutycycle
                  #(PCLK_PERIOD/2) o_pclk = ~o_pclk;     // toggle to zero
               end
               else begin                    // --- freezeing clock output in low state
                  o_pclk = 1'b0;             // clock stopped low
                  @(posedge frame_enable);   // now wait for next enable of output (@ avoids sim lockup)
               end
            end
         end
      end
   end


   //<> -------------------------------------------------
   //<> Per-Frame ROW statemachine
   //<> - Frame statemachine driven by strobes from Row statemachine
   always @(new_row_event)
   begin  :Row_Statemachine
      row_count++;                     // count increment on every event unless overriden by state transition condition
      case (frame_state)
         F_IDLE    : begin
                        row_count = 0;          // powerup/reset null position .. counter frozen
                        row_enable = `ENABLE;
                        frame_state = VSYNC;
                        ->stop_start_evnt;   // indicate traffic starting
                     end

         VSYNC     : begin
                        if (row_count == p_NUM_VSYNC_ROWS) begin
                           row_count = 0;
                           frame_state = TOP_PORCH;
                        end
                     end

         TOP_PORCH : begin
                        if (row_count == p_NUM_TOP_PORCH_ROWS) begin
                           row_count = 0;
                           frame_state = ACT_IMAGE;
                        end
                     end

         ACT_IMAGE : begin
                        // if (row_count == p_ACT_VID_NUM_ROWS) begin
                        if (row_count >= num_tst_rows) begin
                           row_count = 0;
                           frame_state = BOT_PORCH;
                        end
                     end

         BOT_PORCH : begin
                        if (row_count == p_NUM_BOT_PORCH_ROWS) begin
                           row_count = 0;
                           if (frame_enable) begin
                              row_enable = `ENABLE;   // continue sending frames
                              frame_state = VSYNC;    //
                           end
                           else begin
                              ->stop_start_evnt;      // indicate traffic halting
                              row_enable = `DISABLE;  // stop video output
                              frame_state = F_IDLE;   //
                           end
                        end
                     end
      endcase
   end


   //<> -----------------------------------------------------------------
   //<> per-Row COLUMN Statemachine
   //<> -----------------------------------------------------------------

   //<> -------------------------------------------------
   //<> row pixel output statemachine
   always @(negedge o_pclk)
   begin :Col_Statemachine
      col_count++;      // count increment on every event unless overriden by state transition condition
      case (row_state)
         // POR        :   if (frame_enable && row_enable) begin            // wait until user-enabled before starting traffic flow after powerup/reset
         POR        :   if (frame_enable) begin            // wait until user-enabled before starting traffic flow after powerup/reset
                           row_state = FNT_PORCH;     // startup image output in front-porch state...no real traffic, and helps align H/Vsync pulses
                        end

         HSYNC      :   if (col_count == p_HSYNC_CNT) begin    // prefix blanking columns and HSYNC pulse active
                           col_count = 0;
                           row_state = BK_PORCH;
                        end

         BK_PORCH   :   if (col_count == p_BACK_PORCH_CNT) begin   // prefix blanking columns (HSYNC inactive)
                           col_count = 0;
                           if (frame_state == ACT_IMAGE)   // check if we are on top/bottom blanking rows or active pixel output row
                              row_state = ACT_ROW;
                           else
                              row_state = BLANK_ROW;
                        end

         BLANK_ROW  :   if (col_count == p_PIXEL_COUNT) begin  // blanking rows
                           col_count = 0;
                           row_state = FNT_PORCH;
                        end

         ACT_ROW    :   if (col_count == p_PIXEL_COUNT) begin  // active display pixel rows (non-blanking pixels)
                           col_count = 0;
                           row_state = FNT_PORCH;
                        end

         FNT_PORCH  :   if (col_count == p_FRONT_PORCH_CNT) begin  // trailing blanking columns
                           col_count = 0;
                           ->new_row_event;     // strobe frame-statemachine to increment
                           if (row_enable) begin      // clear to start new row?
                              row_state = HSYNC;
                           end
                           else begin              // user has disabled video output
                              row_state = POR;
                           end
                        end
      endcase
   end


//<>--------------------------------------------------------------
//<> I/O PORT CONTROLS
//<>--------------------------------------------------------------

   //<> -------------------------------------------------
   //<> drive VSYNC output
   always @(negedge o_pclk)
   begin
      if (frame_state == VSYNC )
         o_vsync = `ENABLE;
      else
         o_vsync = `DISABLE;
   end

   //<> -------------------------------------------------
   //<> drive HSYNC output
   always @(negedge o_pclk)
   begin
      if (row_state == HSYNC )
         o_hsync = `ENABLE;
      else
         o_hsync = `DISABLE;
   end


   //<> -------------------------------------------------
   //<> output active pane data pattern drive.
   always @(negedge o_pclk)
   begin
      if ((row_state == ACT_ROW) && (frame_state == ACT_IMAGE)) begin  // only during active data window within full frame
         ov_vdata = { full_frame[row_count][(col_count*2)+1], full_frame[row_count][col_count*2] };   // <MSW,LSW> = <odd, even> pixel
         // ov_vdata = { full_frame[row_count][(col_count*2)], full_frame[row_count][(col_count*2)+1] };  // <MMSW,LSW> = <even, odd> pixel
      end
      else begin
         ov_vdata = 0; // output nulls as we are in blanking frame\
      end
   end

   //<> -------------------------------------------------
   //<> drive bias output only during active pane data window
   always @(negedge o_pclk)
   begin
      // if (row_state == ACT_ROW)
      if ((row_state == ACT_ROW) && (frame_state == ACT_IMAGE))
         o_ac_bias_en = `ENABLE;
      else
         o_ac_bias_en = `DISABLE;
   end

   //<> -------------------------------------------------
   //<> assert external enable output port on statemachine start/shutdown event
   always @(stop_start_evnt)
   begin
      o_enable = frame_enable;      // map intenal to external port
      if (frame_enable == `DISABLE)     // generate Logfile change of status message
         `SIM.printMessage(BFM_NAME, {" --- HD Frame output traffic <<Stopped>> --- "});
      else
         `SIM.printMessage(BFM_NAME, {" --- HD Frame output traffic *Started* --- "});
   end

   //<> -------------------------------------------------
   //<> Log when FPGA indictes frame received
   //<>
   always @(posedge o_rec_all)
   begin
      `SIM.printMessage(BFM_NAME, {" --- DUT signaled Video frame recieved --- "});
   end


endmodule

// bfm_HD_framer
   // #( .BFM_NAME      ("bfm_HD_framer"),
      // .PCLK_PERIOD   (20),
      // .SILENT        (0)
   // ) bfm_framer_inst
   // (
      // //<> Asynchronous memory interface
      // .o_pclk        () ,  // reg -
      // .ov_vdata      () ,  // reg [(PIXEL_WIDTH*PIXEL_PER_CLK)-1:0] - video data
      // .o_vsync       () ,  // reg -
      // .o_hsync       () ,  // reg -
      // .o_ac_bias_en  () ,  // reg -
      // .o_fail_n      () ,  // reg -
      // .o_enable      () ,  // reg -
      // .o_rec_all     () ,  // reg -
      // //<> testbench control/status
      // .i_tx_en       () ,  // wire - system transfer enable
      // .new_row_event ()    // event - pings before the start of every new image row (active or blanking)
   // );

