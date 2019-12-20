------------------------------------------------------------------------
--
-- Copyright (C) 2012 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Arnold Balisch
-- Created       : 2012-09-20
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Description   : This library is responsible for setting the RNG seed
-- Updated       : date / author - comments
------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

package seed_pkg is

  constant SEED_INITIAL_VALUE : integer := 3447;

end package seed_pkg;
