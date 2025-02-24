------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_uc_master_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Nov 21, 2011
------------------------------------------------------------------------
--Description : Functions and Procedures for bfm_uc_master_package
--
-- Included Function Calls:
--    - uc_msg()
-- 
-- External Constants from "global_signals_pkg" used:
--       - <none>
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

package bfm_uc_master_pkg is
   --=========== Package constants =============
   constant CS_POLARITY : std_logic := '0';   -- active level of ALE strobe
   constant ADDR_IDLE_STATE : std_logic := '0';   -- active level of ALE strobe
   -- constant NUM_XFER_PER_ACCESS : integer := '4';   -- number sequential transfers per rd/wr request
   constant DSP_UC_DA_WIDTH : integer := 8;     -- width of data and address bus
   
   -- Bus cycle timing constraints (minimums) READ (@ 19.44MHz)
   constant ts_RRCSS       : time := 15 ns;  -- Read assert setup before CS Assert
   constant ts_RR          : time := 60 ns;  -- Read/write pulse width
   constant ts_RRRW        : time := 40 ns;  -- Read de-assert to next read assert 
   constant ts_ADRW        : time := 15 ns;  -- address setup before RD/WR Assertion
   constant ts_ADCSH       : time := 12 ns;  -- address hold after CS Deassertion
   constant ts_RDCSCS      : time := 60 ns;--30 ns;  -- min delay between read CS transactions
   
   -- Bus cycle timing constraints (minimums) WRITE  (@ 9.21MHz)
   constant ts_CSWR        : time := 60 ns;  -- CS assert to Write Assert
   constant ts_WW          : time := 60 ns;  -- Read/write pulse width
   constant ts_WRH         : time := 40 ns;  -- write de-assert to next write assert 
   constant ts_DWS         : time := 15 ns;  -- data setup before WRn de-assert
   constant ts_WRCSCS      : time := 60 ns;--30 ns;  -- min delay between write CS transactions
   constant ts_RWCSRS      : time := 15 ns;  -- delay from read/write deassertion to Chipselect deassertion
   -- constant ts_ADWH        : time := 0 ns;  -- ADDR release after Write de-assert
   -- constant ts_DWH         : time := 0 ns;  -- data hold after WRn de-assert

   -- type t_bfm_dsp_uc_dat_array is array (1 to NUM_XFER_PER_ACCESS) of std_logic_vector(DSP_UC_DAT_ADD_WIDTH-1 downto 0);
   
   --=========== Procedure addresss =============
   -- generic SPI Read/Write transaction 
   procedure uc_rd_msg(
                     base_addr: in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data1 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data2 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data3 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data4 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal databus : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic);
   
   procedure uc_wr_msg(
                     base_addr: in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data1 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data2 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data3 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data4 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal databus : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic);
                         
end bfm_uc_master_pkg;

--==========================================PACKAGE BODY==========================================
package body bfm_uc_master_pkg is

   
   -- ==============internal package signals (proceedure <-> Monitor signals) 
   -- shared variable v_uc_msg_type   : integer := 0;     -- flag to monitor indicating last transaction type
   
 
   ------------------------------------------------------------------------
   -- DSP parallel bus READ transaction
   ------------------------------------------------------------------------
   procedure uc_rd_msg(
                     base_addr: in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data1 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data2 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data3 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     r_data4 : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal databus : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic
   ) is
      variable v_addr  : std_logic_vector(base_addr'range);
   begin
      printMessage ( "uc_rd_msg", (" INFO: read cycle base addr:" & hstr(base_addr)));
      flag <= '1';  -- assert for external monitors
      chipsel <= not CS_POLARITY;   -- ensure cs de-asserted before starting
      wrn <= '1';          -- ensure write inactive
      -- <>--- cycle 1
      v_addr := base_addr;     -- assert first address
      ad <= v_addr;        -- assert first address
      rdn <= '0';          -- assert RD strb
      wait for ts_RRCSS ;  -- wait setup ahead of chipselct active
      chipsel <= CS_POLARITY; -- assert chipselct active
      wait for ts_RR;      -- wait rd strobe active duration 
      r_data1 := databus;  -- capture read data 1
      rdn <= '1';          -- de-assert read
      -- <>--- cycle 2
      wait for (ts_RRRW - ts_ADRW);    -- wait interburst gap - address setup
      v_addr := v_addr + 1;     -- assert first address
      ad <= v_addr;        -- assert 2nd address
      wait for ts_ADRW;    -- address setup
      rdn <= '0';          -- assert RD strb
      wait for ts_RRCSS ;  -- wait setup ahead of chipselct active
      wait for ts_RR;      -- wait rd strobe active duration 
      r_data2 := databus;  -- capture read data 1
      rdn <= '1';          -- de-assert read
      -- <>--- cycle 3
      wait for (ts_RRRW - ts_ADRW);    -- wait interburst gap - address setup
      v_addr := v_addr + '1';     -- increment address
      ad <= v_addr;        -- assert 3rd address
      wait for ts_ADRW;    -- address setup
      rdn <= '0';          -- assert RD strb
      wait for ts_RRCSS ;  -- wait setup ahead of chipselct active
      wait for ts_RR;      -- wait rd strobe active duration 
      r_data3 := databus;  -- capture read data 1
      rdn <= '1';          -- de-assert read
      -- <>--- cycle 4
      wait for (ts_RRRW - ts_ADRW);    -- wait interburst gap - address setup
      v_addr := v_addr + '1';     -- increment address
      ad <= v_addr;        -- assert 4th address
      wait for ts_ADRW;    -- address setup
      rdn <= '0';          -- assert RD strb
      wait for ts_RRCSS ;  -- wait setup ahead of chipselct active
      wait for ts_RR;      -- wait rd strobe active duration 
      r_data4 := databus;  -- capture read data 1
      rdn <= '1';          -- de-assert read
      wait for ts_RWCSRS;
      chipsel <= not CS_POLARITY; -- assert chipselct active
      -- <>--- idle address 
      wait for ts_ADCSH;
      ad <= (others => ADDR_IDLE_STATE);
      wait for ts_RDCSCS; -- pad out required wait between CS assertions
      -- <>--- return
      flag <= '0';  -- de-assert for external monitors
   end  uc_rd_msg;
   
   ------------------------------------------------------------------------
   -- DSP parallel bus READ transaction
   ------------------------------------------------------------------------
   procedure uc_wr_msg(
                     base_addr: in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data1 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data2 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data3 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     w_data4 : in std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal ad : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal databus : out std_logic_vector(DSP_UC_DA_WIDTH-1 downto 0);
                     signal chipsel : out std_logic;
                     signal wrn : out std_logic;
                     signal rdn : out std_logic;
                     signal flag : out std_logic
   ) is
      variable v_addr  : std_logic_vector(base_addr'range);
   begin
      printMessage ( "uc_wr_msg", (" INFO: write cycle base addr:" & hstr(base_addr)));
      flag <= '1';  -- assert for external monitors
      chipsel <= not CS_POLARITY;   -- ensure cs de-asserted before starting
      rdn <= '1';          -- ensure read inactive
      -- cycle 1
      v_addr := base_addr;       -- assert first address
      ad <= v_addr;              -- assert 4th address
      databus <= w_data1;        -- assert write data 1
      wait for ts_DWS ;          -- wait data setup ahead of chip select
      chipsel <= CS_POLARITY;    -- assert chipselct active
      wait for ts_CSWR ;         -- wait setup ahead of chipselct active
      wrn <= '0';                -- assert wr strb
      wait for ts_WW ;  -- wait wr strobe active duration - initial chipselect delay
      wrn <= '1';                -- de-assert write
      -- cycle 2
      wait for (ts_WRH - ts_ADRW);  -- wait interburst gap - address setup
      -- ad <= base_addr + 1;       -- increment address
      v_addr := v_addr + '1';    -- increment address
      ad <= v_addr;              -- assert 4th address
      databus <= w_data2;        -- assert write data 2
      wait for ts_DWS;           -- address/data setup
      wrn <= '0';                -- assert wr strb
      wait for ts_WW;            -- wait wr strobe active duration 
      wrn <= '1';                -- de-assert write
      -- cycle 3
      wait for (ts_WRH - ts_ADRW);    -- wait interburst gap - address setup
      -- ad <= base_addr + 2;        -- increment address
      v_addr := v_addr + '1';    -- increment address
      ad <= v_addr;              -- assert 4th address
      databus <= w_data3;        -- assert write data 2
      wait for ts_DWS;           -- address/data setup
      wrn <= '0';                -- assert wr strb
      wait for ts_WW;            -- wait wr strobe active duration 
      wrn <= '1';                -- de-assert write
      -- cycle 4
      wait for (ts_WRH - ts_ADRW);    -- wait interburst gap - address setup
      -- ad <= base_addr + 3;         -- increment address
      v_addr := v_addr + '1';    -- increment address
      ad <= v_addr;              -- assert 4th address
      databus <= w_data4;        -- assert write data 2
      wait for ts_DWS;           -- address/data setup
      wrn <= '0';                -- assert wr strb
      wait for ts_WW;            -- wait wr strobe active duration 
      wrn <= '1';                -- de-assert write
      wait for ts_RWCSRS;
      chipsel <= not CS_POLARITY; -- de-assert chipselct active
      -- idle address 
      wait for ts_ADCSH;
      ad <= (others => ADDR_IDLE_STATE);
      for i in 0 to DSP_UC_DA_WIDTH-1 loop  -- tristate bus
          databus(i) <= 'Z';  
      end loop;
      wait for ts_WRCSCS; -- pad out required wait between CS assertions
      -- return
      flag <= '0';  -- de-assert for external monitors
   end procedure uc_wr_msg;
   
end bfm_uc_master_pkg;

