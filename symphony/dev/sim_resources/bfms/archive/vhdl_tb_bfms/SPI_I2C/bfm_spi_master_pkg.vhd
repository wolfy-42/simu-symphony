------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_spi_master_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : March 16, 2011
--Description : Functions and Procedures for bfm_spi_master
--
--
------------------------------------------------------------------------
-- $Author: Arnold.Balisch $     $Revision: 1.10 $    $Date: 2012-11-12 09:15:38 $
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;

package bfm_spi_master_pkg is
   --=========== Package constants =============
   -- constant FRAME_BITS     : integer := 208;
   constant SPI_CLK_PERIOD : time := 100 ns;    -- 10 MHz 
   constant ts_MO          : time := 10 ns;  -- data out stable after rising sclk
   constant ts_SI          : time := 20 ns;  -- data in stable after falling sclk
   constant ts_CS_SET      : time := 40 ns;  -- Chipselect set to first sclk rising edge
   constant ts_CS_OFF      : time := 40 ns;  -- Chipselect release to last sclk falling edge
   constant ts_CS_INT      : time := 100 ns;  -- minimum inter-transaction gap

   constant CLK_GAPPING : std_logic := '0';  -- If set to '1', the spi transfer will be suspended/frozen by GAP_DELAY every 16bits until end of frame is reached.
   constant GAP_DELAY   : time := 50 us;
   
   --=========== Procedure headers =============
   function Spi_Chksum (frame   : in std_logic_vector) return std_logic_vector; 

   procedure spi_msg (      w_dat   : in std_logic_vector;  -- data to output
                     signal r_dat   : out std_logic_vector; -- data returning
                     signal clock   : in std_logic;         -- spi clock
                     signal miso    : in std_logic;         -- miso from DUT
                     signal mosi    : out std_logic;        -- mosi to DUT
                     signal csn     : out std_logic;        -- spi chipselect (active low)
                     signal clk_en  : out std_logic ;      -- spi gated clock enable
                            fault   : in std_logic := '0' ) ;      -- checksum fault injection ('1'=inject fault)

   procedure spi_dbl_nogap_msg( 
                     w_dat_1   : in std_logic_vector;  -- data to output
                     w_dat_2   : in std_logic_vector;  -- data to output
                     signal clock   : in std_logic;         -- spi clock
                     signal miso    : in std_logic;         -- miso from DUT
                     signal mosi    : out std_logic;        -- mosi to DUT
                     signal csn     : out std_logic;        -- spi chipselect (active low)
                     signal clk_en  : out std_logic;        -- spi gated clock enable   
                            fault   : in std_logic := '0' ) ;     -- checksum fault injection ('1'=inject fault)
                            

   --=========== BFM Driver component =============
   component bfm_spi_master_clk_driver is
      generic (
         SPI_CLK_PERIOD  : time := 100 ns    -- 10 MHz 
         );
      port (
         i_sclk_en   : in std_logic;
         o_sclk  : out std_logic := '0'
         );
   end component;    
   
end bfm_spi_master_pkg;

--==========================================PACKAGE BODY==========================================
package body bfm_spi_master_pkg is
   --<>----------------------------------------------------------------------
   --<> SPI Checksum Generator - generates a checksum for frame passed and returns frame
   --<>    with result in last 16bits of passed frame (overwrites previous values).
   --<> Method : Break MOSI frame into 16 bits words and sum all but least significant word together. 
   --<>     - the 16 bits checksum represents the value required to render the the above sum = X”0000”.
   --<>----------------------------------------------------------------------
   function Spi_Chksum (frame   : in std_logic_vector) return std_logic_vector is 
      variable ptr : integer; -- loop pointer
      variable field  :  std_logic_vector(15 downto 0); -- selected field
      variable cropped  :  std_logic_vector(15 downto 0); -- selected field
      variable cum_sum : integer := 0; -- cumulative sum
      variable tmp_chksum :  integer; -- checksum result
      variable chksum :  std_logic_vector(15 downto 0); -- checksum result
   begin  
      cum_sum := 0;  -- initialize
      for ptr in ((frame'length-1)/16) downto 1 loop -- ignore LSW
         field := frame((16*(ptr+1))-1 downto (16*ptr));
         -- printMessage ("Spi_Chksum()", ("selected field #" &str(ptr) & " : "& hstr(field)));
         cum_sum := cum_sum + CONV_INTEGER(field);  -- cumulative summation
         cropped := CONV_STD_LOGIC_VECTOR(cum_sum,16);   --crop result to 16bits equivalent
         cum_sum := CONV_INTEGER(cropped); -- return to integer for next field
      end loop;
      -- printMessage ("Spi_Chksum()", ("....   cumulative sum :" & str(cum_sum)));
      tmp_chksum := 0 - cum_sum;  -- find value to add to yield zero result...this is "checksum" value to return
      chksum := CONV_STD_LOGIC_VECTOR(tmp_chksum,16);
      -- printMessage ("Spi_Chksum()", (".......|| checksum :" & hstr(chksum)));
      return chksum;
   end function;
   
   
   --<>----------------------------------------------------------------------
   --<> SPI MASTER (interface independant operation)
   --<>  - scalable input based on length of w_dat vector passed.
   --<>  - assumes gated clock controlled by i_sclk_en
   --<>  - MSbit out first
   --<>  NOTE: use of 'signal' prefix in parameter declaration enables external 
   --<>    net passthru drive and read throughout call and retains last driven 
   --<>    value (sticky) after task returns
   --<>----------------------------------------------------------------------
   procedure spi_msg(       w_dat   : in std_logic_vector;  -- data to output
                     signal r_dat   : out std_logic_vector; -- data returning
                     signal clock   : in std_logic;         -- spi clock
                     signal miso    : in std_logic;         -- miso from DUT
                     signal mosi    : out std_logic;        -- mosi to DUT
                     signal csn     : out std_logic;        -- spi chipselect (active low)
                     signal clk_en  : out std_logic;        -- spi gated clock enable   
                            fault   : in std_logic := '0' ) is      -- checksum fault injection ('1'=inject fault)
      variable i, wrd : integer; -- loop index
      variable tx_dat_w_chk : std_logic_vector(w_dat'range); -- temp to ensure defined size for transfer
      variable tmp_rx_dat   : std_logic_vector(w_dat'range); -- temp to ensure defined size for transfer
   begin
      for i in w_dat'high downto 0 loop -- input nd output frames are same length...we are given input size so use it for output range
         r_dat(i) <= '0';  -- clear output frame ahead of transaction
      end loop;
      --<> checksum insertion
      tx_dat_w_chk := w_dat;     -- copy input frame to temporary buffer for checksum override                     
      if (fault /= '1') then     -- Insert checksum in last 16 bits of frame
         tx_dat_w_chk(15 downto 0) := Spi_Chksum(w_dat); -- overwrite last word with proper checksum value
      else
         printMessage ("spi_msg()", "NOTE: sending SPI Frame with BAD CHECKSUM ");
      end if;  
      -- printMessage ("<DEBUG> spi_msg()", ("send message :" & str(tx_dat_w_chk)));
      --<> frame transmission and return capture
      csn <= '0';
      wait for ts_CS_SET;
      clk_en <= '1';                              -- indicate spi transaction underway (start clock)
      wrd := 0;
      for i in w_dat'high downto w_dat'low loop   -- count down to ensure MSbit first write/read
         clk_en <= '1';                              -- restart clock (if gapped)
         wait until (clock'event and clock = '1');
         wrd := wrd + 1;
         tmp_rx_dat(i) := miso;                   -- latch in current bit
         wait for ts_MO;                          -- pause for data output delay
         mosi <= tx_dat_w_chk(i);                        -- drive out current bit
         wait until (clock'event and clock = '0');
         wait for ts_SI;                          -- pause for data input setup delay
         if (((wrd mod 16) = 0) and (CLK_GAPPING = '1')) then -- find 16 bit boundary
            clk_en <= '0';  -- halt clk
            wait for GAP_DELAY;
         end if;
      end loop;
      clk_en <= '0';                              -- indicate spi transaction completed (stop clock)
      wait for ts_CS_OFF;
      csn <= '1';
      mosi <= 'L';                                -- return net to default rest
      r_dat <= tmp_rx_dat; 
      wait for ts_CS_INT;                         -- ensure proper inter-transaction gap
   end procedure spi_msg;
   
   procedure spi_dbl_nogap_msg( 
                     w_dat_1   : in std_logic_vector;  -- data to output
                     w_dat_2   : in std_logic_vector;  -- data to output
                     signal clock   : in std_logic;         -- spi clock
                     signal miso    : in std_logic;         -- miso from DUT
                     signal mosi    : out std_logic;        -- mosi to DUT
                     signal csn     : out std_logic;        -- spi chipselect (active low)
                     signal clk_en  : out std_logic;        -- spi gated clock enable   
                            fault   : in std_logic := '0' ) is      -- checksum fault injection ('1'=inject fault)
      variable i : integer; -- loop index
      variable tx_dat_1_w_chk : std_logic_vector(w_dat_1'range); -- temp to ensure defined size for transfer
      variable tx_dat_2_w_chk : std_logic_vector(w_dat_2'range); -- temp to ensure defined size for transfer
      -- variable tmp_rx_dat   : std_logic_vector(w_dat'range); -- temp to ensure defined size for transfer
   begin
      -- for i in w_dat'high downto 0 loop -- input nd output frames are same length...we are given input size so use it for output range
         -- r_dat(i) <= '0';  -- clear output frame ahead of transaction
      -- end loop;
      --<> checksum insertion
      tx_dat_1_w_chk := w_dat_1;     -- copy input frame to temporary buffer for checksum override                     
      tx_dat_2_w_chk := w_dat_2;     -- copy input frame to temporary buffer for checksum override                     
      if (fault /= '1') then     -- Insert checksum in last 16 bits of frame
         tx_dat_1_w_chk(15 downto 0) := Spi_Chksum(w_dat_1); -- overwrite last word with proper checksum value
         tx_dat_2_w_chk(15 downto 0) := Spi_Chksum(w_dat_2); -- overwrite last word with proper checksum value
      else
         printMessage ("spi_msg()", "NOTE: sending SPI Frame with BAD CHECKSUM ");
      end if;  
      -- printMessage ("<DEBUG> spi_msg()", ("send message :" & str(tx_dat_w_chk)));
      --<> frame transmission and return capture
      csn <= '0';
      wait for ts_CS_SET;
      clk_en <= '1';                              -- indicate spi transaction underway (start clock)
      for i in w_dat_1'high downto w_dat_1'low loop   -- count down to ensure MSbit first write/read
         wait until (clock'event and clock = '1');
         -- tmp_rx_dat(i) := miso;                   -- latch in current bit
         wait for ts_MO;                          -- pause for data output delay
         mosi <= tx_dat_1_w_chk(i);                        -- drive out current bit
         wait until (clock'event and clock = '0');
         wait for ts_SI;                          -- pause for data input setup delay
      end loop;
      for i in w_dat_2'high downto w_dat_2'low loop   -- count down to ensure MSbit first write/read
         wait until (clock'event and clock = '1');
         -- tmp_rx_dat(i) := miso;                   -- latch in current bit
         wait for ts_MO;                          -- pause for data output delay
         mosi <= tx_dat_2_w_chk(i);                        -- drive out current bit
         wait until (clock'event and clock = '0');
         wait for ts_SI;                          -- pause for data input setup delay
      end loop;
      clk_en <= '0';                              -- indicate spi transaction completed (stop clock)
      wait for ts_CS_OFF;
      csn <= '1';
      mosi <= 'L';                                -- return net to default rest
      -- r_dat <= tmp_rx_dat; 
      wait for ts_CS_INT;                         -- ensure proper inter-transaction gap
   end procedure spi_dbl_nogap_msg;
  
end bfm_spi_master_pkg;



--<>==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use work.bfm_spi_master_pkg.all;

entity bfm_spi_master_clk_driver is
   generic (SPI_CLK_PERIOD  : time := 100 ns    -- 10 MHz 
   );
   port (
      i_sclk_en   : in std_logic;
      o_sclk      : out std_logic := '0'
   );
end bfm_spi_master_clk_driver;

--<>==========================ARCHITECTURE==========================================
architecture behave of bfm_spi_master_clk_driver is

--<> INTERNAL CLOCK SIGNALS
signal spi_clk_int            : std_logic := '0';

begin

   --<>---------------------------------
   --<> gated clock driver for SPI interface clock
   p_spi_clk_drv: process
   begin
      if (i_sclk_en = '1') then              -- wait on global flag
         spi_clk_int <= not spi_clk_int;     -- initiate clock 
         wait for SPI_CLK_PERIOD/2;          -- delay for 50% duty-cycle of period
      else
         spi_clk_int <= '0';                 -- ensure clock floats GND during IDLE
         wait until (i_sclk_en = '1');       -- suspend process until next transaction
      end if;
   end process;
   o_sclk <= spi_clk_int;

end behave;
