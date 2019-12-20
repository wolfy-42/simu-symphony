------------------------------------------------------------------------
--
-- Copyright (C) 2007 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Chris Hesse
-- Created       : 2007-05-01
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Description   : This library is responsible for implementing all tasks that
--               relate to math expressions, such as random number generator.
-- Updated       : 2011-01-01 / Arnold B. - new functions
------------------------------------------------------------------------

library ieee, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use IEEE.std_logic_arith.all;
use work.txt_util.all;
use work.sim_management_vhdl.all;
use work.seed_pkg.all;

package lib_math is

   impure function random_8b_slv return std_logic_vector;
  
   function int2slv(number: in integer; bits : in integer) return std_logic_vector;
   function clogb2(number: in integer) return integer;
      
   procedure allBfmsPleaseDoStartOfSimCheck (seed : in integer);  
   procedure allBfmsPleaseDoEndOfSimCheck (seed : in integer);
   
end lib_math;

package body lib_math is

   constant MODULE_NAME        : string  := "lib_math";
   constant SEED_INITIAL_VALUE : integer := 1;

   shared variable low_range : positive := 2;
   shared variable high_range: positive := 200;

   ------------------------------------------------------
   --<> function to simplify the conversion of intergers to std_logic_vectors of "bits" size
   ------------------------------------------------------
   function int2slv(number: in integer; bits : in integer) return std_logic_vector is 
   begin
      return CONV_STD_LOGIC_VECTOR(number, bits);
   end function int2slv;
  
   ------------------------------------------------------
   -- <> Vector size determination from integer
   --   -  returns number of std_logic_vector bits needed to represent passed integer value (depth)
   ------------------------------------------------------
   function clogb2(number: in integer) return integer is
      variable num_bits: integer;
      variable depth: integer;
   begin
      num_bits := 0;                -- initialize count
      depth := number;               -- initialize variable with input to allow manipulation
      while (depth > 0) loop        -- repeat until a zero value remains
         num_bits := num_bits + 1;  -- for each loop itteration, increment bit count
         depth := depth/2;          -- integer divide by 2 is equivalent to bitwise shift right 
      end loop;
      return num_bits;              -- return count => number of vector bits needed to hold integer
   end function clogb2;
  
   --------------------------------
   -- <> random number generator function                                  <<<Sept 2012 - Obsoleted by Random_lib.vhd module>>>
   --  - IMPURE: references outside variables "low_range" and "high_range" for call2call changes
   --  - returns 8bit vector
   ---------------------------------
   impure function random_8b_slv return std_logic_vector is
      variable v_random: real;
   begin
      uniform(low_range, high_range, v_random);
      return CONV_STD_LOGIC_VECTOR(INTEGER(255.0*v_random), 8);
   end function random_8b_slv;
  
   procedure allBfmsPleaseDoStartOfSimCheck (seed : in integer) is
   begin
     printMessage (MODULE_NAME, "The seed is set to " & str(seed) & " for this simulation.");
   end allBfmsPleaseDoStartOfSimCheck;
  
   procedure allBfmsPleaseDoEndOfSimCheck (seed : in integer) is
   begin
     printMessage (MODULE_NAME, "The seed was set to " & str(seed) & " for this simulation.");
   end allBfmsPleaseDoEndOfSimCheck;

   
end lib_math;      



