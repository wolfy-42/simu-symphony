------------------------------------------------------------------------
--
-- Copyright (C) 2012 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Arnold Balisch
-- Created       : 2012-09-20
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Description   : This library is responsible for implementing a random number generator.
-- Updated       : date / author - comments
------------------------------------------------------------------------

library ieee, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use IEEE.std_logic_arith.all; -- for TO_STDLOGICVECTOR function 
use ieee.math_real.all;   -- for uniform, trunc functions
use ieee.numeric_std.all; -- for to_unsigned function
use work.seed_pkg.all;

package random_lib is
   impure function Random_int (min, max : in integer) return integer;
   impure function Random_slv (min, max : in integer; 
                               num_bits: integer) return std_logic_vector;
end random_lib;

package body random_lib is
   
   --------------------------------------------------------
   --<> seed values for random generator
   shared variable seed1 : positive := ((SEED_INITIAL_VALUE*7) / 3);  -- seed values must be different - prime numbers ensure better result 
   shared variable seed2 : positive := SEED_INITIAL_VALUE;            -- seed2 < seed 1
   
   --------------------------------------------------------
   --<> Pseudo-Random number generator function
   --<>  - returns integer value in the range of (0..limit) (positive only)
   --<>  - IMPURE: references outside variables seed1 and seed2 for call-to-call changes
   --<>  - uses math_real library
   impure function Random_int (min, max : in integer) return integer is
      variable rand      : real;    -- random real-number value in range 0 to 1.0
      variable val_range : real;    -- output value range scaling
   begin
      assert (max >= min) report "Rand_int(): Range Error" severity Failure;
      uniform(seed1, seed2, rand);     -- create random real-number value in range 0.0 to 1.0 
      val_range := real(Max - Min + 1);   -- find range within min and max
      return integer( trunc(rand * val_range )) + min;  -- scale real value to fit range and offset by min value
   end Random_int;

   --------------------------------------------------------
   --<> Random std_logic_vector function
   --<>  - returns std_logic_vector(num_bits-1 downto 0) in range
   --<>  - calls Random_int()
   impure function Random_slv (min, max : in integer;
                               num_bits: integer) return std_logic_vector is
     variable limit: real;                    -- integer range for vector size
     variable rand_int: integer;
   begin
      -- limit := real((vec_size**2) -1);        -- calculate limit based on size of desired return vector, cast as type real for calculation below
      rand_int := Random_int(min,max);      -- call random number function and mod with limit to improve distibution
      -- return TO_STDLOGICVECTOR(rand_int, num_bits);  -- convert to std_logic_vector and return
      return std_logic_vector( to_unsigned( rand_int, num_bits));  -- convert to std_logic_vector and return
   end Random_slv;
   
end random_lib;