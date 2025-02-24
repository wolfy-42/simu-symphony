------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_spi_sdio_slave_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Sept 15, 2011
--Description : Functions and Procedures for bfm_spi_sdio_slave
--       - provides registered SPIO transaction compliance
--       - Only one "register" ... address portion of header ignored in current version
--
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
--use work.global_signal_pkg.all;  -- contains all board-level interconnect signals for global access

package bfm_spi_sdio_slave_pkg is
   --=========== Package constants =============
   -- constant UC_SPI_PERIOD        : time := 100 ns;   -- 10 MHz                         -- <<??>>
      
   --=========== Procedure headers =============

   --=========== BFM SPI Slave component =============
   component bfm_spi_sdio_slave is
   generic ( --SPI_MODE : integer := 4,     -- 3 or 4 wire operation
             CS_POLARITY : std_logic := '0';  -- Active polarity of chipselect input
             NUM_HEADER_BITS : integer := 8;  -- Active polarity of chipselect input
             NUM_DATA_BITS   : integer := 8;  -- Active polarity of chipselect input
             SPI_WRITE_POL   : std_logic := '0';  -- polarity of RW bit in SPI transaction (value indicates write transaction)
             SPIO_SETTLE_LVL : std_logic := 'H'    -- IDLE default =  pullup
   );
   port (
      i_sclk  : in std_logic ;
      i_cs    : in std_logic ;
      io_sdio : inout std_logic
   );
   end component;    
   
end bfm_spi_sdio_slave_pkg;

--==========================================PACKAGE BODY==========================================
-- package body bfm_spi_sdio_slave_pkg is
   -- -- ==============internal package signals (proceedure <-> Monitor signals) 
   -- --shared variable v_spi_msg_type   : integer := 0;     -- flag to monitor indicating last transaction type
   
-- end bfm_spi_sdio_slave_pkg;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
--use work.global_signal_pkg.all;
use work.bfm_spi_sdio_slave_pkg.all;

entity bfm_spi_sdio_slave is
   generic ( --SPI_MODE : integer := 4,     -- 3 or 4 wire operation
             CS_POLARITY : std_logic := '0';  -- Active polarity of chipselect input
             NUM_HEADER_BITS : integer := 8;  -- Active polarity of chipselect input
             NUM_DATA_BITS   : integer := 8;  -- Active polarity of chipselect input
             SPI_WRITE_POL   : std_logic := '0';  -- polarity of RW bit in SPI transaction (value indicates write transaction)
             SPIO_SETTLE_LVL : std_logic := 'H'    -- IDLE default =  pullup
      );
   port (
      i_sclk  : in std_logic ;
      i_cs    : in std_logic ;
      io_sdio : inout std_logic
   );
end bfm_spi_sdio_slave;

--==========================ARCHITECTURE==========================================
architecture behave of bfm_spi_sdio_slave is
   -- Local Constants 
   constant SDIO_OUT_ENABLE   : std_logic := '1';  -- condition for bi-directional port's OUTPUT_ENABLE assertion
   constant TURNAROUND        : integer := (NUM_HEADER_BITS - 1);     -- 14 bits hearder after RW, minus 3 bits for FF set propagation

   -- INTERNAL SIGNALS
   signal int_sdio_in   : std_logic := '0';
   signal int_sdio_out  : std_logic := '0';
   signal sdio_dir      : std_logic := '0';
   signal hdr_cntr      : integer := 0;
   signal data_cntr     : integer := 0;
   type t_states  is (START, HEADER, DATA);
   signal sm_state   : t_states;
   signal rw_bit     : std_logic := not SDIO_OUT_ENABLE;       -- default port to input mode
   signal data_reg   : std_logic_vector(NUM_DATA_BITS-1 downto 0) := (others => '0');  -- register for holding r/w test data

begin


   -----------------------------------
   -- gated clock driver for USB SPI interface clock
   p_spi_clk_drv: process (i_cs, i_sclk)
   begin
      if (i_cs /= CS_POLARITY) then
         hdr_cntr        <= 0;
         data_cntr      <= NUM_DATA_BITS-1;
         sm_state       <= START;
         rw_bit         <= '0';
      elsif (i_sclk'event and i_sclk = '1') then                                
         case sm_state is
            when START => 
               rw_bit <= int_sdio_in;  -- latch RW flag value for later direction control
               sm_state <= HEADER;
            when HEADER => 
               hdr_cntr <= hdr_cntr + 1;
               if (hdr_cntr = TURNAROUND) then
                  sm_state <= DATA;
               else
                  sm_state <= HEADER;   
               end if;
            when DATA => 
               data_cntr <= data_cntr - 1;
               if (rw_bit = SPI_WRITE_POL)  then   -- write transaction  (slave listening)?
                  data_reg(data_cntr) <= int_sdio_in; -- latch incoming data word
               end if;
               if (data_cntr > 0) then  -- still loading 
                  sm_state <= DATA;  -- stay put...chip select clear will reset statemachine
               else                    -- last data bit
                  sm_state <= START;  -- return to IDLE
               end if;
               -- if (data_cntr > 0) then  -- still loading 
                  -- data_reg(data_cntr) <= int_sdio_in; -- latch incoming data word
               -- else                    -- last data bit
                  -- data_reg(data_cntr) <= int_sdio_in; -- latch last incoming data bit
               -- end if;
            when others =>
               sm_state <= START;    -- fault recovery
         end case;
      end if;
   end process;

   -- flip direction on NEGATIVE edge of SCLK to ensure correct setup/hold for SPI
   process (i_sclk, i_cs)
   begin
      if (i_cs /= CS_POLARITY) then       -- reset SM if no ADC chipselect is active
         int_sdio_out   <= '0';
         sdio_dir   <= not SDIO_OUT_ENABLE;   -- always default to "input" mode
      elsif (i_sclk'event and i_sclk = '0') then     -- negative edge output
         -- sdio_dir <= adc_sdio_flg;
         if (sm_state = DATA) then
            if (rw_bit = SPI_WRITE_POL)  then   -- Write transaction?
               sdio_dir <= not SDIO_OUT_ENABLE;  -- write mode (slave listening)
            else                             
               sdio_dir <= SDIO_OUT_ENABLE;   -- read mode (slave asserting)
               int_sdio_out <= data_reg(data_cntr);
            end if;
         end if;
      end if;
   end process;

   io_sdio <= int_sdio_out when (sdio_dir = SDIO_OUT_ENABLE) else SPIO_SETTLE_LVL;
   int_sdio_in <= io_sdio;
   
end behave;
