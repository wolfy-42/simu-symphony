------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_spi_sdio_slave_pkg.vhd
--Project     : VIP
--Author      : Arnold Balisch   
--Created     : Sept 15, 2011
--Description : Functions and Procedures for bfm_spi_sdio_slave
--
--
------------------------------------------------------------------------
-- $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2011-09-14 20:06:18 $
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use work.global_signal_pkg.all;  -- contains all board-level interconnect signals for global access

package bfm_spi_sdio_slave_pkg is
   --=========== Package constants =============
   -- constant UC_SPI_PERIOD        : time := 100 ns;   -- 10 MHz                         -- <<??>>
      
   --=========== Procedure headers =============

   --=========== BFM SPI Slave component =============
   component bfm_spi_sdio_slave is
   generic ( SPI_MODE : integer;     -- 3 or 4 wire operation
             CS_POLARITY : std_logic  -- Active polarity of chipselect input
      );
   port ( 
      i_sclk  : out std_logic ;
      i_cs    : in std_logic ;
      i_sdi   : in std_logic ;
      io_sdio : inout std_logic ;
      o_sdo   : out std_logic   
      );
   end component;    
   
end bfm_comm_traffic_pkg;

--==========================================PACKAGE BODY==========================================
package body bfm_comm_traffic_pkg is

   -- ==============internal package signals (proceedure <-> Monitor signals) 
   shared variable v_spi_msg_type   : integer := 0;     -- flag to monitor indicating last transaction type
   
end bfm_spi_sdio_slave;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use work.global_signal_pkg.all;
use work.bfm_comm_traffic_pkg.all;

entity bfm_spi_sdio_slave is
   generic ( --SPI_MODE : integer := 4,     -- 3 or 4 wire operation
             CS_POLARITY : std_logic := '0';  -- Active polarity of chipselect input
             NUM_HEADER_BITS : integer := 8;  -- Active polarity of chipselect input
             NUM_DATA_BITS   : integer := 8  -- Active polarity of chipselect input
      );
   port (
      i_sclk  : out std_logic ;
      i_csn    : in std_logic ;
      i_sdi   : in std_logic ;
      io_sdio : inout std_logic := 'z';
      o_sdo   : out std_logic  := 'z'
   );
end bfm_spi_sdio_slave;

--==========================ARCHITECTURE==========================================
architecture behave of bfm_spi_sdio_slave is

-- INTERNAL CLOCK SIGNALS
-- signal             : std_logic := '0';

begin

   io_sdio <= int_sdo when (sdio_dir = SDIO_OUT_ENABLE) else 'Z';
   int_sdio_in <= io_sdio;

   -----------------------------------
   -- gated clock driver for USB SPI interface clock
   p_spi_clk_drv: process
   begin
      if (i_cs = CS_POLARITY) then
      else
      end if;
   end process;
end behave;
