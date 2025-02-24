# Fidus Ethernet Test Generator BFM
The ETG BFM creates ethernet/IP traffic on an AXI4-Stream interface.   
Supports protocols including Ethernet, VLAN, IPv4, UDP, RTP.

Files are listed here in compile/dependency order.

**fidus_axis_etg_if.sv**  
Defines the AXI4-Stream interface used for the BFM.

**fidus_axis_packet_gen_bfm.sv**  
Base class for sending data out of the AXI4-stream interface. This base has no 
ethernet specific functionality; see the fidus_axis_etg_bfm child class.

Parameters:  
```
- TDATA_WIDTH - data bus width
- TUSER_WIDTH - user width (fidus_axis_etg_bfm use tuser for the stream index)
- TKEEP_WIDTH - data bus width/8
```

Functions/Tasks:
```
- tSend                  - sends a data frame out the axis bus
- fSetValidBubblePercent - set percent chance that a random tvalid low will be inserted at each word
- fSetValidRateGen       - set the tvalid to a throttled (m/n) rate
- fSetIFGDelay           - set the inter-frame gap to a fixed number of clocks
- fSetIFGDelayRange      - set the inter-frame gap to a random range
- fSetSanitizeBus        - set whether to zero out axis bus between frames
```

**fidus_prbs_pkg.sv**  
Class package for generating/checking PRBS data. fidus_axis_etg_bfm uses this to 
generate PRBS7 data streams. It supports arbitrary data width and other PRBS 
modes, and can be used for other applications.  

Parameters:  
```
- pPRBS_LEN   - length/type of PRBS: 7,9,11,15,23,31
- pDATA_WIDTH - granularity of each data word
```
Functions/Tasks:  
```
- fGenPrbsData   - generate a data word
- tGenPrbsPacket - generate a packet of words
- fChkPrbsInit   - (re)synchronize the checker
- fChkPrbsData   - check a data word
- fChkPrbsPacket - check a packet of words
```

**fidus_axis_etg_pcap_pkg.sv**  
Package with functions for streaming data packets in and out of pcap files. Each
packet is stored/retrieved with a nanosecond timestamps (although it is not 
currently used in this BFM).

Functions/Tasks:  
```
- fOpenNewPacketCaptureFile  - create/replace a file for writing
- fWritePacketCaptureFile    - write a packet to file
- fClosePacketCaptureFile    - close file
- fOpenReadPacketCaptureFile - open a file for reading
- tReadPacketCaptureFile     - read the next packet from file
```

**fidus_axis_etg_stream_pkg**  
Class package for generating/encapsulating ethernet data. Each instance creates
a stream or source of data (from prbs, pcap, counter, or fixed), and attaches 
various ethernet/ip headers or trailers to the payload.  
Length and crc fields in the headers are automatically calculated and updated.  
It contains an instance of the fidus_prbs class.

Functions/Tasks:  
```
- fSetDataPrbs    - configure payload to prbs (default)
- fSetDataFixed   - configure payload to fixed byte
- fSetDataRamp    - configure payload to sequential counter
- fSetDataFile    - configure payload to source from pcap file
- fSetRtpHeader   - configure 12-byte RTP header encapsulation
- fSetUdpHeader   - configure  8-byte UDP header encap
- fSetIPv4Header  - configure 20-byte IPv4 header encap
- fSetEthHeader   - configure 14-byte Ethernet header encap
- fSetVlanHeader  - configure  4-byte VLAN insertion
- fSetVlan2Header - configure  4-byte double VLAN insertion
- fSetEthCrc      - configure  4-byte Eth CRC appended to tail
- fSetEthPreamble - configure  8-byte preamble added to head
- tGetData        - generate/retrieve next data packet
```



**fidus_axis_etg_bfm.sv**  
This is the top level BFM class. It derives from fidus_axis_packet_gen_bfm, and
contains instances of fidus_axis_etg_stream.  
It supports an optional pcap output log of the generated traffic.
1. Construct the class with a user-specified number of streams.  
2. Configure each stream (fidus_axis_etg_stream_pkg) with a data source and any 
desired encap.  
3. Configure the base fidus_axis_packet_gen_bfm class with axis bus settings.
4. Call tGeneratePackets to output some number of packets. (round robin between 
the streams)


Functions/Tasks:  
```
- streams[n].<fSet functions from fidus_axis_etg_stream_pkg>
- <functions from fidus_axis_packet_gen_bfm>
- tGeneratePackets - sends out the specified total number of packets
```

