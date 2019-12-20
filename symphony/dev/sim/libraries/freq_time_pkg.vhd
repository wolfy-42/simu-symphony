------------------------------------------------------------------------
--
-- Copyright (C) 2011 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Arnold Balisch   
-- Created       : 2011-09-15
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Description   :  frequency<->period time conversion functions 
--       - intended for use in constant declarations for enhanced readability/manipulation
--
--    Included Function Calls:
--       - to_frequency()
--       - to_time()
-- 
--    External Constants from "global_signals_pkg" used:
--       - <none>
-- Updated       : date / author - comments
------------------------------------------------------------------------

package freq_time_pkg is

  type t_freq is range 0 to 2147483647
  units
    Hz;
    KHz = 1000 Hz;
    MHz = 1000 KHz;
    GHz = 1000 MHz;
  end units;

  -- convert a period time value to frequency (in MHz)
  function to_frequency ( duration : time) return t_freq;

  -- convert any frequency (in MHz) to its corresponding period time value
  function to_time (frequency : t_freq) return time;

end package freq_time_pkg;

package body freq_time_pkg is
  function to_frequency ( duration : time) return t_freq is
    begin
      if duration > 0 sec then  -- avoid negative timebases
        return (1 sec / duration) * 1 Hz;  -- invert and ensure correct timebase casting
      else
        return 0 Hz;
      end if;
      --return (1 sec / duration) * 1 Hz;
    end;

  -- assumes frequency given in MHz   
  function to_time ( frequency : t_freq) return time is
    begin
      return (1 GHz / frequency) * 1 ns;
    end;

end package body freq_time_pkg;
