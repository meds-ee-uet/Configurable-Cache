 //	DECODER FOR 2-WAY

module cache_decoder(clk, addr, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] addr;
    output logic [24:0] tag;
    output logic [4:0] index;
    output logic [1:0] blk_offset;
      
   assign tag = addr[31:7];
   assign index = addr[6:2];
   assign blk_offset = addr[1:0];    
endmodule

 //	DECODER FOR 4-WAY

module cache_decoder(clk, addr, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] addr;
    output logic [25:0] tag;
    output logic [3:0] index;
    output logic [1:0] blk_offset;
    
    
   assign tag = addr[31:6];
   assign index = addr[5:2];
   assign blk_offset = addr[1:0];
    
endmodule

 //	DECODER FOR 8-WAY

module cache_decoder(clk, addr, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] addr;
    output logic [26:0] tag;
    output logic [2:0] index;
    output logic [1:0] blk_offset;
    
    
   assign tag = addr[31:5];
   assign index = addr[4:2];
   assign blk_offset = addr[1:0];
    
endmodule

//	DECODER FOR 12-WAY

module cache_decoder(clk, addr, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] addr;
    output logic [27:0] tag;
    output logic [1:0] index;
    output logic [1:0] blk_offset;
    
    
   assign tag = addr[31:4];
   assign index = addr[3:2];
   assign blk_offset = addr[1:0];
    
endmodule