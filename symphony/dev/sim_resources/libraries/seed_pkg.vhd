------------------------------------------------------------------------
--
-- Copyright (C) 2006-2023 Fidus Systems Inc. 
-- SPDX-License-Identifier: Apache-2.0 OR MIT
-- The licenses stated above take precedence over any other contracts, agreements, etc.
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
