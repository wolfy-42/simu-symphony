------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_sharcdsp_master_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Nov 21, 2011
------------------------------------------------------------------------
--Description : Functions and Procedures for bfm_uc_master_package
--
-- Included Function Calls:
--    - uc_msg()
-- 
------------------------------------------------------------------------

--==========================================PACKAGE address==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;     -- allow std_logic_vector addition
-- use std.textio.all;
use work.txt_util.all;
use work.seed_pkg.all;
use work.lib_math.all;
use work.sim_management.all;

package bfm_sharcdsp_master_pkg is
   --=========== Package constants =============
   constant CS_POLARITY : std_logic := '0';   -- active level of ALE strobe
   constant ADDR_IDLE_STATE : std_logic := '0';   -- active level of ALE strobe
   constant NUM_XFER_PER_ACCESS : integer := 4;   -- number sequential transfers per rd/wr request
   constant DSP_UC_D_WIDTH : integer := 8;     -- width of data bus
   constant DSP_UC_A_WIDTH : integer := 8;     -- width of address bus
   
   -- Bus cycle timing constraints (minimums) READ 
   constant ts_RD_DARL   : time := 6   ns;  -- Read assert setup before CS Assert
   constant ts_RD_RW     : time := 308 ns;  -- Read/write pulse width
   constant ts_RD_DRHA   : time := 20  ns;  -- Read de-assert to next read assert 
   constant ts_RD_SDS    : time := 3   ns;  -- address setup before RD/WR Assertion
   constant ts_RD_HDRH   : time := 0   ns;  -- address hold after CS Deassertion
   constant ts_RD_RWR    : time := 29  ns;  -- min delay between read CS transactions
   
   -- Bus cycle timing constraints (minimums) WRITE
   constant ts_WR_DAWL     : time := 7   ns;  -- CS assert to Write Assert
   constant ts_WR_WW       : time := 308 ns;  -- Read/write pulse width
   constant ts_WR_DWHA     : time := 21  ns;  -- write de-assert to next write assert 
   constant ts_WR_DWHD     : time := 20  ns;  -- data setup before WRn de-assert
   constant ts_WR_WWR      : time := 28  ns;  -- min delay between write CS transactions
   constant ts_WR_DDWH     : time := 316 ns;  -- delay from read/write deassertion to Chipselect deassertion

   constant ts_WR_WRDsu     : time := (ts_WR_DDWH - ts_WR_WW);
   constant ts_WR_WRAsu     : time := (ts_WR_WRDsu - ts_WR_DAWL);
   
   type t_data_array is array (1 to 4) of std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);  -- data array type for proceedure loops

   --=========== Procedure addresss =============
   -- generic SPI Read/Write transaction 
   procedure uc_rd_msg(
                     base_addr: in std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     r_data1 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     r_data2 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     r_data3 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     r_data4 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     signal databus : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic);
   
   procedure uc_wr_msg(
                     base_addr: in std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     w_data1 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     w_data2 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     w_data3 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     w_data4 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     signal databus : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic);
                         
end bfm_sharcdsp_master_pkg;

--==========================================PACKAGE BODY==========================================
package body bfm_sharcdsp_master_pkg is
 
   ------------------------------------------------------------------------
   -- DSP parallel bus READ transaction
   ------------------------------------------------------------------------
   procedure uc_rd_msg(
                     base_addr: in std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     r_data1 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     r_data2 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     r_data3 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     r_data4 : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     signal databus : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic
   ) is
      variable v_addr   : std_logic_vector(base_addr'range);
      variable v_cycle  : integer;  -- loop pointer
      variable v_data   : t_data_array;
   begin
      printMessage ( "uc_rd_msg", (" INFO: read cycle base addr:" & hstr(base_addr)));
      flag <= '1';  -- assert for external monitors
      chipsel <= not CS_POLARITY;   -- ensure cs de-asserted before starting
      wrn <= '1';          -- ensure write inactive
      rdn <= '1';          -- ensure read inactive
      v_addr := base_addr; -- assert first address
      for v_cycle in 1 to NUM_XFER_PER_ACCESS loop  -- loop through read cycles
         ad <= v_addr;              -- assert address
         chipsel <= CS_POLARITY;    -- assert chipselct active
         wait for ts_RD_DARL ;     -- address setup to read strobe
         rdn <= '0';                -- assert read strobe
         wait for (ts_RD_RW-ts_RD_SDS) ;      -- data setup to write enable 
         v_data(v_cycle) := databus;   -- latch data at earliest moment
         wait for ts_RD_SDS ;        -- finish read strobe duration
         rdn <= '1';                -- deassert read strobe
         if (v_data(v_cycle) /= databus) then               -- verify earlier bus value against current...
            printError ("uc_rd_msg", "SharcDSP read data setup time violation detected");         
            v_data(v_cycle) := databus;                       -- relatch data at OE edge moment if setup violation (minimize downstream sim errors)
         end if;
         wait for ts_RD_DRHA;    -- complete remaining ts_RD_OEn2p duration and end bus cycle
         ad <= (others => '-');
         chipsel <= not CS_POLARITY; -- assert chipselct active
         wait for (ts_RD_RWR-ts_RD_DRHA);  -- ensure turnaround seperation between cycles
         v_addr := v_addr + '1';             -- increment address for next cycle
      end loop;
      --<>  return
      r_data1 := v_data(1);      -- map back to calling routine
      r_data2 := v_data(2);
      r_data3 := v_data(3);
      r_data4 := v_data(4);
      flag <= '0';  -- de-assert for external monitors
   end  uc_rd_msg;
   
   ------------------------------------------------------------------------
   -- DSP parallel bus READ transaction
   ------------------------------------------------------------------------
   procedure uc_wr_msg(
                     base_addr: in std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     w_data1 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     w_data2 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     w_data3 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     w_data4 : in std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_A_WIDTH-1 downto 0);
                     signal databus : out std_logic_vector(DSP_UC_D_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic
   ) is
      variable v_addr   : std_logic_vector(base_addr'range);
      variable v_cycle  : integer;  -- loop pointer
      variable v_data   : t_data_array;
   begin
      printMessage ( "uc_wr_msg", (" INFO: write cycle base addr:" & hstr(base_addr)));
      v_data(1) := w_data1;  -- Preload array
      v_data(2) := w_data2;
      v_data(3) := w_data3;
      v_data(4) := w_data4;
      flag <= '1';  -- assert for external monitors
      chipsel <= not CS_POLARITY;   -- ensure cs de-asserted before starting
      wrn <= '1';          -- ensure write inactive
      rdn <= '1';          -- ensure read inactive
      v_addr := base_addr;       -- local variable of base/first address
      for v_cycle in 1 to NUM_XFER_PER_ACCESS loop
         databus <= v_data(v_cycle); -- assert new write data
         wait for ts_WR_WRAsu ;     -- 
         ad <= v_addr;              -- assert address
         chipsel <= CS_POLARITY;    -- assert chipselct active
         wait for ts_WR_DAWL ;      -- 
         wrn <= '0';                -- assert wr strb
         wait for ts_WR_WW ;        -- wait wr strobe active duration - initial chipselect delay
         wrn <= '1';                -- de-assert write
         wait for ts_WR_DWHD ;      -- wait wr data hold time
         databus <= (others => 'Z');-- undefine data to verify hold not exceeded
         wait for (ts_WR_DWHA - ts_WR_DWHD); -- wait wr data hold time
         ad <= (others => '-');              -- assert address
         chipsel <= not CS_POLARITY;         -- assert chipselct active
         wait for (ts_WR_WWR - ts_WR_DWHA);  -- ensure turnaround seperation between cycles
         v_addr := v_addr + '1';             -- increment address for next cycle
      end loop;
      flag <= '0';  -- de-assert for external monitors
   end procedure uc_wr_msg;
   
end bfm_sharcdsp_master_pkg;

