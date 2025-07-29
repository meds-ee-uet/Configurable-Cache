module cache_decoder(clk, address, tag, index, blk_offset);
    input logic clk;
    input logic [31:0] address;
    output logic [23:0] tag;
    output logic [5:0] index;
    output logic [1:0] blk_offset;
    
    
    assign tag = address[31:8];
    assign index = address[7:2];
    assign blk_offset = address[1:0];
    
endmodule