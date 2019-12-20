//--------------------------------------------------------------------
//
// Copyright (C) 2015 Fidus Systems Inc.
//
// Project       : simu
// Author        : Arnold Balisch
// Created       : 2015-07-27
//--------------------------------------------------------------------
//--------------------------------------------------------------------
// Description   : This library is responsible for implementing all tasks 
//    or functions that relate to logfile/transcript value to string conversions
//
//   Dependancies:  
//    1> tb/libraries/sim_management_inst.v   
//
//   NOTE: uses SystemVerilog constructs
//
//   Available User routines:
//   - function string    Comma();
//   - function string    Comma();
//   - function string    Vec2HexStr();
//   - function string    Vec2BinStr();
//   - function string    Vec2IntStr();
//   - function string    Vec2SIntStr();
//   - function string    Time2Str();
//   - function string    Float2Str();
//   - function string    SFloat2Str();
//   - function string    Real2Str();
//   - function string    SReal2Str();
//   - task               hex2a ();
//   - function string    hex2str ();
//
// Updated       : date / author - comments
//--------------------------------------------------------------------



//<> check to see if module already included by calling module...avoids duplicate includes
`ifndef TEXT_UTILS
   `define TEXT_UTILS

   //<> define standard alias to logfile output routines (if not already defined)
   `ifndef SIM   
      `define SIM  tb.sim_management_inst
   `endif
     
//* Module declaration
module text_utils ();
   parameter MODULE_NAME = "text_utils";

   string msg;
   integer seed;

   initial 
   begin 
     seed = `SEED_INITIAL_VALUE ;        
     msg.itoa (`SEED_INITIAL_VALUE);
     msg = {"The seed is set to ", msg," for this simulation.\n"};
     sim_management_inst.printMessage (MODULE_NAME, msg);
   end

   //<>------------------------------------------------------------------------
   //<> environment startup routines
   //<>------------------------------------------------------------------------
   always @(sim_management_inst.allBfmsPleaseDoEndOfSimCheck)
   begin
     msg.itoa (`SEED_INITIAL_VALUE);
     msg = {"The seed was set to ", msg," for this simulation.\n"};
     sim_management_inst.printMessage (MODULE_NAME, msg);
   end
    
     
   // -------------------------------------------------------------------
   //<> convert integer to string with 1000's comma notation (SYSTEMVERILOG)
   //   (eg.  12000 -> "12,000")
   // (Note: systemVerilog syntax)
   function string Comma(input logic [63:0] val);
      string s;
      $sformat(s, "%0d", val);
      for (int i=s.len()-4; i>=0; i-=3)
         s = {s.substr(0, i), ",", s.substr(i+1, s.len()-1)};   // parse string inserting commas
      return s;
   endfunction     
   
   // -------------------------------------------------------------------
   //<> convert any integer or bit-vector input to ASCII String equivalent in Hex notation  (SYSTEMVERILOG)
   function string Vec2HexStr;
         input integer vector;   // accepts any integer or bit-vector (reg) of any size.
      begin
         // use systemverilog systask to perform hex converion and return ascii string with hex notation prefix
         $sformat(Vec2HexStr,"0x%0h", vector);  
      end
   endfunction  
   
   // -------------------------------------------------------------------
   //<> convert any integer or bit-vector input to ASCII String equivalent in binary notation  (SYSTEMVERILOG)
   function string Vec2BinStr;
         input integer vector;   // accepts any integer or bit-vector (reg) of any size.
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(Vec2BinStr,"b'%0b", vector);  
      end
   endfunction     
     
   // -------------------------------------------------------------------
   //<> convert any integer or bit-vector input to ASCII String equivalent in integer notation  (SYSTEMVERILOG)
   function string Vec2IntStr;
         input integer vector;   // accepts any integer or bit-vector (reg) of any size.
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(Vec2IntStr,"%0d", vector);  
      end
   endfunction 

   // -------------------------------------------------------------------
   //<> convert any integer or bit-vector input to ASCII String equivalent in integer notation  (SYSTEMVERILOG)
   function string Vec2SIntStr;
         input shortint vector;   // accepts any integer or bit-vector (reg) of any size.
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(Vec2SIntStr,"%0d", vector);  
      end
   endfunction     

   // -------------------------------------------------------------------
   //<> convert simulator timeinput to ASCII String equivalent in current timespec units
   function string Time2Str;
         input time value;   // accepts a 'time' value
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(Time2Str,"%0T", value);  
      end
   endfunction     

   // -------------------------------------------------------------------
   //<> convert simulator real to ASCII String equivalent in scientific notation
   function string Float2Str;
         input real value;   // accepts a 'time' value
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(Float2Str,"%0e", value);  
      end
   endfunction 
   // -------------------------------------------------------------------
   //<> convert simulator shortreal to ASCII String equivalent in scientific notation
   function string SFloat2Str;
         input shortreal value;   // accepts a 'time' value
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(SFloat2Str,"%0e", value);  
      end
   endfunction     
     
   // -------------------------------------------------------------------
   //<> convert simulator real to ASCII String equivalent decimal notation
   function string Real2Str;
         input real value;   // accepts a 'time' value
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(Real2Str,"%0f", value);  
      end
   endfunction 
   // -------------------------------------------------------------------
   //<> convert simulator shortreal to ASCII String equivalent decimal notation
   function string SReal2Str;
         input shortreal value;   // accepts a 'time' value
      begin
         // use systemverilog systask to perform hex converion and return ascii string
         $sformat(SReal2Str,"%0f", value);  
      end
   endfunction     
     
//<>----------------------------------------------------------
//<> Hexadecimal to string conversion   
//<>----------------------------------------------------------
   
   //<>------------------------
   //<> sub-module (called by hex2a)
   //<> - converts a 16bit hex into a four digit string
   task hex2a_16;
      input [15:0] in;
      output string out;
      reg [19:0] ii;
      string oo;
      int i;      
      begin
         ii = in + 20'h10000;         
         oo.hextoa(ii);
         out = oo.substr(1, 4);
         if (out == "")           
           out = "XXXX";
      end
   endtask

   //<>------------------------
   //<> Main Task call
   //<> syntax:    
   //<>     hex2a(tstword, $bits(tstword), msg);
   //<>
   //<> NOTE: 16 words maximum
   //<>
   task hex2a (   input reg [255:0] in,
                  input integer num_bits,
                  output string out
               );   
      string tmp; 
      integer num_16b_words;      // number of 16bit words 
      begin
         num_16b_words = (num_bits%16 == 0)? num_bits/16 : (num_bits/16)+1;   // calculate number of 16bit words...round up if not even 16bit multiple
         if (num_16b_words >= 1 ) 
           begin hex2a_16(in[15:0],tmp);      out ={tmp};         end
         if (num_16b_words >= 2 )             
           begin hex2a_16(in[31:16],tmp);     out ={tmp,"_",out}; end
         if (num_16b_words >= 3 )             
           begin hex2a_16(in[47:32],tmp);     out ={tmp,"_",out}; end
         if (num_16b_words >= 4 )             
           begin hex2a_16(in[63:48],tmp);     out ={tmp,"_",out}; end       
         if (num_16b_words >= 5 )             
           begin hex2a_16(in[79:64],tmp);     out ={tmp,"_",out}; end    
         if (num_16b_words >= 6 )             
           begin hex2a_16(in[95:80],tmp);     out ={tmp,"_",out}; end   
         if (num_16b_words >= 7 )             
           begin hex2a_16(in[111:96],tmp);    out ={tmp,"_",out}; end  
         if (num_16b_words >= 8 )            
           begin hex2a_16(in[127:112],tmp);   out ={tmp,"_",out}; end        
         if (num_16b_words >= 9 )            
           begin hex2a_16(in[143:128],tmp);   out ={tmp,"_",out}; end                     
         if (num_16b_words >= 10 )           
           begin hex2a_16(in[159:144],tmp);   out ={tmp,"_",out}; end
         if (num_16b_words >= 11 )           
           begin hex2a_16(in[175:160],tmp);   out ={tmp,"_",out}; end
         if (num_16b_words >= 12 )           
           begin hex2a_16(in[191:176],tmp);   out ={tmp,"_",out}; end
         if (num_16b_words >= 13 )           
           begin hex2a_16(in[207:192],tmp);   out ={tmp,"_",out}; end
         if (num_16b_words >= 14 )           
           begin hex2a_16(in[223:208],tmp);   out ={tmp,"_",out}; end
         if (num_16b_words >= 15 )           
           begin hex2a_16(in[239:224],tmp);   out ={tmp,"_",out}; end
         if (num_16b_words >= 16 )           
           begin hex2a_16(in[255:240],tmp);   out ={tmp,"_",out}; end    
         out = {"0x",out};    // add standard hex notation prefix
      end     
   endtask  

   //<>------------------------
   //<> sub-module (called by hex2a)
   //<> - converts a 16bit hex into a four digit string
   function string hex2str_16 (input [15:0] in);
         reg [19:0] ii;
         string oo;
         int i;      
      begin
         ii = in + 20'h10000;         
         oo.hextoa(ii);
         hex2str_16 = oo.substr(1, 4);
         if (hex2str_16 == "")           
           hex2str_16 = "XXXX";
      end
   endfunction

   //<>------------------------
   //<> register to hex string notation (Main function call)
   //<> syntax:    
   //<>     string = hex2str(tstword, $bits(tstword));
   //<>
   //<> NOTE: 16 x 16bit words maximum
   //<>   
   function string hex2str (  input reg [255:0] in,
                              input integer num_bits
                           );   
         string tmp; 
         integer num_16b_words;      // number of 16bit words 
      begin
         num_16b_words = (num_bits%16 == 0)? num_bits/16 : (num_bits/16)+1;   // calculate number of 16bit words...round up if not even 16bit multiple
         if (num_16b_words >= 1 ) 
           begin tmp = hex2str_16(in[15:0]);      hex2str ={tmp};         end
         if (num_16b_words >= 2 )             
           begin tmp = hex2str_16(in[31:16]);     hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 3 )             
           begin tmp = hex2str_16(in[47:32]);     hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 4 )             
           begin tmp = hex2str_16(in[63:48]);     hex2str ={tmp,"_",hex2str}; end       
         if (num_16b_words >= 5 )             
           begin tmp = hex2str_16(in[79:64]);     hex2str ={tmp,"_",hex2str}; end    
         if (num_16b_words >= 6 )             
           begin tmp = hex2str_16(in[95:80]);     hex2str ={tmp,"_",hex2str}; end   
         if (num_16b_words >= 7 )             
           begin tmp = hex2str_16(in[111:96]);    hex2str ={tmp,"_",hex2str}; end  
         if (num_16b_words >= 8 )            
           begin tmp = hex2str_16(in[127:112]);   hex2str ={tmp,"_",hex2str}; end        
         if (num_16b_words >= 9 )            
           begin tmp = hex2str_16(in[143:128]);   hex2str ={tmp,"_",hex2str}; end                     
         if (num_16b_words >= 10 )           
           begin tmp = hex2str_16(in[159:144]);   hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 11 )           
           begin tmp = hex2str_16(in[175:160]);   hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 12 )           
           begin tmp = hex2str_16(in[191:176]);   hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 13 )           
           begin tmp = hex2str_16(in[207:192]);   hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 14 )           
           begin tmp = hex2str_16(in[223:208]);   hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 15 )           
           begin tmp = hex2str_16(in[239:224]);   hex2str ={tmp,"_",hex2str}; end
         if (num_16b_words >= 16 )           
           begin tmp = hex2str_16(in[255:240]);   hex2str ={tmp,"_",hex2str}; end    
         hex2str = {"0x",hex2str};    // add standard hex notation prefix
      end     
   endfunction  
   
   
   // //<> experimental looping version of "hex2a" that takes input size as dynamic and automatic  (oct 23/14 - not working)
   // task hex2string ( input reg [] in,
                     // output string out
                  // );   
         // string tmp; 
         // integer num_16b_words;      // number of 16bit words 
         // integer x;
      // begin
         // //<> calculate number of 16bit words...round up if not even 16bit multiple
         // num_16b_words = (num_bits%16 == 0)? num_bits/16 : (num_bits/16)+1;   
         // //<> process first 16b word
         // if (num_16b_words >= 1 ) begin      
            // hex2a_16(in[15:0],tmp);      
            // out ={tmp};         
         // end
         // //<> process subsequent 16b words as needed
         // if (num_16b_words >= 2 ) begin      
            // x = 2;      // initialize loop index to second 16b word portion
            // while (x <= num_16b_words) begin         // process all subsequenct words (adding '_' between words)
               // if (num_16b_words >= x ) begin
                 // hex2a_16( in[(16*x)-1:(16*(x-1))], tmp );     // call 16bit conversion routine for part-indexed section of input 
                 // out ={tmp,"_",out};                        // prefix result to existing string with '_' seperator notation
               // end
               // x++;
            // end
         // end
         // //<> prefix with standard hex notation symbol and return result to calling procedure
         // out = {"0x",out};    
      // end     
   // endtask  

   // // -------------------------------------------------------------------
   // //<> Absolute function
   // function int ABS (input int a);     // 32bit signed integer
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function shortint ABS (input shortint a);     // 16bit signed integer
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function real ABS (input real a);   // 64bit float
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function shortreal ABS (input shortreal a);  //32bit float
       // ABS = (a < 0) ? -a : a;
   // endfunction
   // function reg [$size(a)-1:0] ABS (input reg [$size(a)-1:0] a);  // variable-sized vector
       // ABS = (a < 0) ? -a : a;
   // endfunction

   
endmodule // text_utils

//<> -------------------------------------END-------------------------------------------------

//<> close start of file `ifndef
`endif
