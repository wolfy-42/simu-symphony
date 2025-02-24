/*-----------------------------------------------------------------------------
// Title         : Ethernet packet generator
// Project       : Ethernet packet generator BFM
//-----------------------------------------------------------------------------
// File          : fidus_axis_etg_full_pkt_crc_pkg.sv
// Author        : Bassem Sleiman
// Created       : 22/04/2020
//-----------------------------------------------------------------------------
this package provide the pakcet with a 4 bytes of CRC at the end
//----------------------------------------------------------------------------*/

package fidus_axis_etg_full_pkt_pkg;

    import sim_management_pkg::*;

    typedef logic [7:0] byte_array_t [];

    //--------------------------------------------------------------------------
    // These functions generate the data to be used in the frame.
    //--------------------------------------------------------------------------
    function automatic byte_array_t rand_byte_array(int min_size, int max_size = min_size);
        int actual_size = $urandom_range(min_size, max_size);
        byte_array_t byte_array;

        // The two statement are because we are not restricted to +8 as number of bytes and we could have a packet with
        while(byte_array.size/4 != actual_size/4)
            byte_array = {>>{byte_array,8'($urandom)}};

        while(byte_array.size%4 != actual_size%4)
            byte_array = {>>{byte_array,8'($urandom)}};

        return byte_array;
    endfunction

    function automatic byte_array_t ramp_byte_array(int min_size, int max_size = min_size);
        int actual_size = $urandom_range(min_size, max_size);
        static logic [7:0] val = 1;
        byte_array_t byte_array;

        while(byte_array.size/4 != actual_size/4)
            byte_array = {>>{byte_array,val++}};

        while(byte_array.size%4 != actual_size%4)
            byte_array = {>>{byte_array,8'(val++)}};

        return byte_array;
    endfunction

    function automatic byte_array_t fixed_byte_array(int min_size, int max_size = min_size,logic [7:0] data);
        int actual_size = $urandom_range(min_size, max_size);
        //static logic [7:0] val = 1;
        byte_array_t byte_array;

        while(byte_array.size/4 != actual_size/4)
            byte_array = {>>{byte_array,data}};

        while(byte_array.size%4 != actual_size%4)
            byte_array = {>>{byte_array,data}};

        return byte_array;
   endfunction


///////////////////////////this is the main class of the package ///////////////////////////////////////////////////////////////////////////////////////////////////////////////


class fidus_axis_etg_full_pkt_bfm ;
    //Variable
    byte_array_t payload;
    sim_management s;

    typedef struct packed {
        logic [47 : 0] dst_mac;
        logic [47 : 0] src_mac;
        logic [15 : 0] ethertype;
    } Ethernet_hdr_t;

    Ethernet_hdr_t Ethernet_hdr;


    typedef struct packed {
        logic [ 3 : 0] version;
        logic [ 3 : 0] ihl;
        logic [ 5 : 0] dscp;
        logic [ 1 : 0] ecn;
        logic [15 : 0] tot_len;
        logic [15 : 0] id;
        logic [ 2 : 0] flags;
        logic [12 : 0] frag_offset;
        logic [ 7 : 0] ttl;
        logic [ 7 : 0] protocol;
        logic [15 : 0] hdr_cksm;
        logic [31 : 0] src_ip;
        logic [31 : 0] dst_ip;
    } ipv4_hdr_t;

    ipv4_hdr_t ipv4_hdr;


    typedef struct packed {
        logic [31 : 0] Sequence_id_base;
    } Sequence_id_t;

    Sequence_id_t Sequence_id;


    // only Ethernet and seqId
    typedef struct packed {
        Ethernet_hdr_t Ethernet_hdr;
        Sequence_id_t Sequence_id;
    } Eth_seqid_hdr_t;

    Eth_seqid_hdr_t Eth_seqid_hdr;


    //ethernet vlan sequenceid
    typedef struct packed {
        Ethernet_hdr_t Ethernet_hdr;
        logic [15 : 0] Vlan;
        Sequence_id_t Sequence_id;
    } Eth_vlan_seqid_hdr_t;

    Eth_vlan_seqid_hdr_t Eth_vlan_seqid_hdr;

    //ethernet vlan ipv4 sequence id
    typedef struct packed {
        Ethernet_hdr_t Ethernet_hdr;
        logic [15 : 0] Vlan;
        ipv4_hdr_t ipv4_hdr;
        Sequence_id_t Sequence_id;
    } Eth_vlan_ipv4_seqid_hdr_t;

    Eth_vlan_ipv4_seqid_hdr_t Eth_vlan_ipv4_seqid_hdr;

    // ethernet ipv4 sequence id
    typedef struct packed {
        Ethernet_hdr_t  Ethernet_hdr;
        ipv4_hdr_t ipv4_hdr;
        Sequence_id_t Sequence_id;
    } Eth_ipv4_seqid_hdr_t;

    Eth_ipv4_seqid_hdr_t Eth_ipv4_seqid_hdr;

    typedef struct packed {
        Sequence_id_t Sequence_id;
    } not_ethernet_pkt_t;

    not_ethernet_pkt_t not_ethernet_pkt;

    logic ethernet_header = 1;
    logic vlan_header     = 1;
    logic ipv4_header     = 1;
    logic crc_enable      = 1;
    logic crc_error       = 0;

    logic [31 : 0] CRC_VALUE;

    string  CLASS_NAME;


    //-----------------------------------------------------------
    // Constructor
    //
    //      name: name used in logs
    //-----------------------------------------------------------

    function new(
        string name                              = ""
    );
        static int frame_count                   = 0;

        Eth_vlan_ipv4_seqid_hdr.ipv4_hdr         = '0;
        Eth_vlan_ipv4_seqid_hdr.ipv4_hdr.version = 'd4;
        Eth_vlan_ipv4_seqid_hdr.ipv4_hdr.ihl     = 'd5;
        Eth_vlan_ipv4_seqid_hdr.ipv4_hdr.tot_len = 'd20; // those are some default value
        Eth_vlan_ipv4_seqid_hdr.ipv4_hdr.ttl     = 'd128;

        Eth_ipv4_seqid_hdr.ipv4_hdr              = '0;
        Eth_ipv4_seqid_hdr.ipv4_hdr.version      = 'd4;
        Eth_ipv4_seqid_hdr.ipv4_hdr.ihl          = 'd5;
        Eth_ipv4_seqid_hdr.ipv4_hdr.tot_len      = 'd20; // those are some default value
        Eth_ipv4_seqid_hdr.ipv4_hdr.ttl          = 'd128;

        CRC_VALUE                                = 32'h0;

        //Sequence_id.Sequence_id_base           = 0;

        if (name == "")
            this.CLASS_NAME = $sformatf("fidus_axis_etg_full_pkt_bfm");
        else
            this.CLASS_NAME = name;

        frame_count = frame_count + 1;

    endfunction : new

    //-----------------------------------------------------------
    // CRC calculation function
    //-----------------------------------------------------------
    localparam CRC32POL = 32'hEDB88320; /* Ethernet CRC-32 Polynom, reverse Bits */

    function automatic bit[31:0] nextCRC32_D8( byte_array_t pkt_total);
        int unsigned i, j;
        bit [31:0] crc32_val = 32'hffffffff; // shiftregister,startvalue
        bit [7:0]  data;

        //The result of the loop generate 32-Bit-mirrowed CRC
        for (i = 0; i < pkt_total.size; i++)  // Byte-Stream
        begin
            data = pkt_total[i];
            for (j=0; j < 8; j++) // Bitwise from LSB to MSB
            begin
                if ((crc32_val[0]) != (data[0])) begin
                    crc32_val = (crc32_val >> 1) ^ CRC32POL;
                end else begin
                    crc32_val >>= 1;
                end
                data >>= 1;
            end
        end
        crc32_val ^= 32'hffffffff; //invert results
        return crc32_val;
    endfunction

    //-----------------------------------------------------------
    // This function configure the frame to the required fields.
    //
    //-----------------------------------------------------------
    function automatic void configure_frame (input ethernet_header,input vlan_header, input ipv4_header ,input crc_enable,input crc_error) ;

        this.ethernet_header = ethernet_header;
        this.vlan_header     = vlan_header;
        this.ipv4_header     = ipv4_header;
        this.crc_enable      = crc_enable;
        this.crc_error       = crc_error;

    endfunction

    //-----------------------------------------------------------
    //This function calculate the header checksum of the IPV4 header
    //
    //-----------------------------------------------------------
    function automatic logic [15:0] calc_ipv4_cksm(ipv4_hdr_t hdr);
        logic [31:0] cksm = 0;
        hdr.hdr_cksm = '0;
        for (int i=0; i < $bits(hdr); i+=16)
            cksm += hdr[i+:16];
        while (cksm[31:16] > 0)
            cksm = cksm[31:16] + cksm[15:0];
        return ~(cksm[15:0]);
    endfunction

    //-----------------------------------------------------------------------------------------------------
    //This function and based on the frame configuration return the header and caluclate crc when enabled
    //
    //-----------------------------------------------------------------------------------------------------
    function automatic byte_array_t full_pkt(input byte_array_t sub_hdr = {}); // to byte_array should replace the name

        if (crc_enable && ~crc_error) begin

            if (ethernet_header) begin

                if (vlan_header) begin
                    if (ipv4_header) begin  // ethernet, vlan, IPv4
                        return ({>>{Eth_vlan_ipv4_seqid_hdr,payload,nextCRC32_D8({>>{Eth_vlan_ipv4_seqid_hdr,payload}})}});
                    end else begin          // ethernet, vlan
                        return ({>>{Eth_vlan_seqid_hdr,payload,nextCRC32_D8({>>{Eth_vlan_seqid_hdr,payload}})}});
                    end
                end else if (~vlan_header) begin
                    if (ipv4_header) begin  // ethernet, IPv4
                        return ({>>{Eth_ipv4_seqid_hdr,payload,nextCRC32_D8({>>{Eth_ipv4_seqid_hdr,payload}})}});
                    end else begin          // ethernet
                        return ({>>{Eth_seqid_hdr,payload,nextCRC32_D8({>>{Eth_seqid_hdr,payload}})}});
                    end
                end
            end else if (~ethernet_header) begin    // no header
                return ({>>{not_ethernet_pkt,payload,nextCRC32_D8({>>{not_ethernet_pkt,payload}})}});
            end
        end else if (~crc_enable) begin

            if (ethernet_header) begin
                if (vlan_header) begin
                    if (ipv4_header) begin  // ethernet, vlan, IPv4
                        return ({>>{{Eth_vlan_ipv4_seqid_hdr},payload}});
                    end else begin          // ethernet, vlan
                        return ({>>{Eth_vlan_seqid_hdr,payload}});
                    end
                end else if (~vlan_header) begin
                    if (ipv4_header) begin  // ethernet, IPv4
                        return ({>>{Eth_ipv4_seqid_hdr,payload}});
                    end else begin          // ethernet
                        return  ({>>{Eth_seqid_hdr,payload}});
                    end
                end
            end else if (~ethernet_header) begin    // no header
                return ({>>{not_ethernet_pkt,payload}});
            end
        end else if (crc_error && crc_enable) begin

            if (ethernet_header) begin
                if (vlan_header) begin
                    if (ipv4_header) begin  // ethernet, vlan, IPv4
                        return ({>>{Eth_vlan_ipv4_seqid_hdr,payload,CRC_VALUE}});
                    end else begin          // ethernet, vlan
                        return ({>>{Eth_vlan_seqid_hdr,payload,CRC_VALUE}});
                    end
                end else if (~vlan_header) begin
                    if (ipv4_header) begin  // ethernet, IPv4
                        return ({>>{Eth_ipv4_seqid_hdr,payload,CRC_VALUE}});
                    end else begin          // ethernet
                        return ({>>{Eth_seqid_hdr,payload,CRC_VALUE}});
                    end
                end
            end else if (~ethernet_header) begin    // no header
                return ({>>{not_ethernet_pkt,payload,CRC_VALUE}});
            end
        end
    endfunction



// This function set the payload and set some variable based on the mux selected.
    function automatic void set_payload (byte_array_t p);
        payload = p;

        case ({ethernet_header,vlan_header,ipv4_header}) // change hte seque id to be pkt count
        {1'b0,1'b0,1'b0} :
            begin
                not_ethernet_pkt.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf("the type of the packet is a Raw packet "));
            end

        {1'b0,1'b1,1'b0} :
            begin
                not_ethernet_pkt.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf("the type of the packet is a Raw packet "));
            end


        {1'b0,1'b0,1'b1} :
            begin
                not_ethernet_pkt.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf("the type of the packet is a Raw packet "));
            end


        {1'b0,1'b1,1'b1} :
            begin
                not_ethernet_pkt.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf(" Raw packet NO Header just sequence ID  "));
            end

        {1'b1,1'b0,1'b0} :
            begin
                Eth_seqid_hdr.Sequence_id.Sequence_id_base=$time;
                 s.printMessage( CLASS_NAME,$sformatf("only Ethernet header "));
            end

        {1'b1,1'b1,1'b0} :
            begin
                Eth_vlan_seqid_hdr.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf(" Ethernet header and 1 VLAN tag  "));
            end

        {1'b1,1'b0,1'b1} :
            begin
                Eth_ipv4_seqid_hdr.ipv4_hdr.tot_len  = p.size + 'd20;
                Eth_ipv4_seqid_hdr.ipv4_hdr.hdr_cksm = calc_ipv4_cksm(Eth_ipv4_seqid_hdr.ipv4_hdr);
                Eth_ipv4_seqid_hdr.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf(" Ethernet header and IPV4 header no VLAN tag   "));
            end


        {1'b1,1'b1,1'b1} :
            begin
                Eth_vlan_ipv4_seqid_hdr.ipv4_hdr.tot_len  = p.size + 'd20;
                Eth_vlan_ipv4_seqid_hdr.ipv4_hdr.hdr_cksm = calc_ipv4_cksm(Eth_vlan_ipv4_seqid_hdr.ipv4_hdr);
                Eth_vlan_ipv4_seqid_hdr.Sequence_id.Sequence_id_base=$time;
                s.printMessage( CLASS_NAME,$sformatf(" Ethernet header and IPV4 header  VLAN tag and IPV4 header  "));

            end

        endcase


    endfunction

endclass

endpackage




