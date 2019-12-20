------------------------------------------------------------------------
--
-- Copyright (C) 2012 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Chris Hesse
-- Created       : 2007-05-01
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Description   : This library is responsible for implementing all tasks that
--              relate to simulation management.
-- Updated       : 2010-01-01 / Arnold B. - fixes
-- Updated       : date / author - comments
------------------------------------------------------------------------

library ieee, work, std;
use ieee.std_logic_1164.all;
use work.txt_util.all;
use std.env.all;


--<> Module declaration
package sim_management_vhdl is

   ------------------------------------------------------------------------
   --<> Simulation global signals declaration/initialization 
  signal globalSimulationEnd  : integer := 0;
  
  ------------------------------------------------------------------------
  --<> procedure/fuction calls
   
  --<> print the input message in a standard format
  procedure message(msg : in string);

  --<> print the input message in a standard format
  procedure printMessage(caller : in string;
                         msg    : in string);

  --<> print the input warning message in a standard format
  procedure printWarning(caller : in string;
                         msg    : in string);

  --<> print the input error message in a standard format
  procedure printError(caller : in string;
                       msg    : in string);

  --<> terminates the simulation
  procedure testComplete (seed : in integer);
  -- procedure testComplete (seed : in integer; signal sim_halt : out integer);

  --<> simple proceddure to check value of a net against expected  
  --   - NOTE: overloaded for std_logic and std_logic_vector
  --   - syntax: 
  --          check_sig(caller, level, "sname", sig ,exp );
  --                 where :( level --> 0=info, 1=warning, 2=Error).
   procedure check_sig( caller: in string;   
                        level: in integer;
                        sname: in string; 
                        sig : in std_logic;  -- <-- single bit
                        exp : in std_logic   -- <-- single bit
                        );
   procedure check_sig( caller: in string;
                        level: in integer;
                        sname: in string; 
                        sig : in std_logic_vector;   -- <-- arbitrary Vector (size= n)
                        exp : in std_logic_vector    -- <-- arbitrary Vector (size= n)
                        );

   procedure WaveMarker (mark : in integer := 0);
   
end sim_management_vhdl;

package body sim_management_vhdl is

   shared variable globalErrorCounter   : integer := 0;
   shared variable globalWarningCounter : integer := 0;  
   shared variable wave_test_marker     : integer := 0;   -- counter to highlight testcase testpoints in waveform viewer
  
   ------------------------------------------------------------------------------------
   --<> Procedure message
   -- Purpose: To print the input message in a standard format. The time unit is
   --          assumed to be ns.
   -- Inputs : string msg --> the message to be displayed
   -- Outputs: none
   procedure message (msg : in string) is
   begin
     printt (msg);
   end message;

   ------------------------------------------------------------------------------------
   --<> Procedure printMessage
   -- Purpose: To print the input message in a standard format, starting with the 
   --          name of the module which invoked this procedure and the label MESSAGE.
   -- Inputs : string caller --> The name of the module who invoked this procedure
   --          string msg    --> the message to be displayed
   -- Outputs: none
   procedure printMessage (caller : in string;
                           msg    : in string) is
   begin
     message (" MESSAGE (" & caller & "): " & msg);
   end printMessage;

   ------------------------------------------------------------------------------------
   --<> Procedure printWarning
   -- Purpose: To print the input warning message in a standard format, starting with the 
   --          name of the module which invoked this procedure and the label WARNING.
   -- Inputs : string caller --> The name of the module who invoked this procedure
   --          string msg    --> the warning message to be displayed
   -- Outputs: none
   procedure printWarning (caller : in string;
                           msg    : in string) is
   begin
     message (" * WARNING * (" & caller & "): " & msg);
     globalWarningCounter := globalWarningCounter + 1;
   end printWarning;

   ------------------------------------------------------------------------------------
   --<> Procedure printError
   -- Purpose: To print the input error message in a standard format, starting with the 
   --          name of the module which invoked this procedure and the label ERROR.
   -- Inputs : string caller --> The name of the module who invoked this procedure
   --          string msg    --> the error message to be displayed
   -- Outputs: none
   procedure printError (caller : in string;
                         msg    : in string) is
   begin
     message (" <<< ERROR >>> (" & caller & "): " & msg);
     globalErrorCounter := globalErrorCounter + 1;
   end printError;
   
   ------------------------------------------------------------------------------------
   --<> Procedure testComplete
   -- Purpose: This procedure cleanly terminates the simulation. It reports the simulation
   --          status (pass/fail) based on the values of the globalErrorCounter. The
   --          simulation should be ended no other way than by invoking this procedure.
   -- Inputs : none
   -- Outputs: none
   procedure testComplete (seed : in integer) is
   -- procedure testComplete (seed : in integer; signal sim_halt : out integer) is
   begin
     print ("");
     print (" ================================================================");
     print (" ====================== END OF SIMULATION =======================");
     print (" ================================================================");
     print ("");         
     -- First, make sure no BFM needs to report any further messages, warnings or errors
     -- by letting them know we are about to end the simulation.

     wait for 1 ns;

     print ("WARNINGS: " & str(globalWarningCounter));
     print ("ERRORS  : " & str(globalErrorCounter));
     print ("");
     print ("");
         
     if (globalErrorCounter = 0) then
       print (" SIMULATION STATUS: PASS");
       print ("");     
     else
       print ("SIMULATION STATUS: FAIL");
       print ("");     
     end if;
     
     -- sim_halt <= 1;
     -- wait for 5 ns;
     
     stop(2);
     --assert false
     --  report ""
     --    severity failure;
   end testComplete;   


   ------------------------------------------------------------------------------------
   --<> Procedure check_sig
   -- Purpose: this procedure checks that a given signal has the expected value at 
   --       the time the procedure is called.  
   --    - level of warning is provided as 
   --       (0=info, 1=warning, 2=Error).
   procedure check_sig( caller: in string;   -- string label of calling module/procedure
                        level: in integer;   -- error level responce (0-2)
                        sname: in string;    -- string of signal name being checked
                        sig : in std_logic;  -- signal to be checked
                        exp : in std_logic   -- correct value expected (fault if actual != expected)
                        ) is
   begin
      if (sig /= exp) then
         case level is
           when 0 => 
               printMessage(caller, (sname &" had unexpected value...exp= " & str(exp) & ", actual= " & str(sig)));
           when 1 => 
               printWarning(caller, (sname &" had unexpected value...exp= " & str(exp) & ", actual= " & str(sig)));
           when others => 
               printError(caller, (sname &" had unexpected value...exp= " & str(exp) & ", actual= " & str(sig)));
         end case;
      else
         printMessage(caller, (sname &" matched expected value = " & str(exp)));
      end if;
   end procedure check_sig;
   --
   -- <<Overload check_sig procedure for vector type >>
   --  - NOTE: sig'range == exp'range is required...mismatched sizes/ranges are not supported
   procedure check_sig( caller: in string;
                        level: in integer;
                        sname: in string; 
                        sig : in std_logic_vector; 
                        exp : in std_logic_vector 
                        ) is
   begin
      if (sig /= exp) then
         case level is
           when 0 => 
               printMessage(caller, (sname &" had unexpected value...exp= " & str(exp) &", actual= " & str(sig)));
           when 1 => 
               printWarning(caller, (sname &" had unexpected value...exp= " & str(exp) &", actual= " & str(sig)));
           when others => 
               printError(caller, (sname &" had unexpected value...exp= " & str(exp) &", actual= " & str(sig)));
         end case;
      else
         printMessage(caller, (sname &" matched expected value = " & str(exp)));
      end if;
   end procedure check_sig;
   
      
   --<>-------------------------------------------------------------------
   --<> WaveMarker: a call to increment a shared counter 
   --<>  - used only as visual waveform aid to highlight points within testcase flow
   --<>  - default is to increment shared counter.  (pass zero or no parameter assigned)
   --<>  - any assigned non-zero parameter overwrites shared variable (allows "section" boundary display)
   --<>-------------------------------------------------------------------
   procedure WaveMarker (mark : in integer := 0) is
   begin
      if (mark = 0) then
         wave_test_marker := wave_test_marker + 1;
      else
         wave_test_marker := mark;
      end if;
   end procedure;
   
end sim_management_vhdl;   
