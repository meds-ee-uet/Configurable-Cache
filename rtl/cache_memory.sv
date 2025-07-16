`define BLOCKS 64
`define WORDS 4
`define WORD_SIZE 32
`define BLOCK_SIZE 128 // 128 bits
module cache_memory (
    input logic clk,                                          
    input logic [23:0] tag,              // From decoder           
    input logic [5:0] index,             // From decoder
    input logic [1:0] blk_offset,            // From decoder
    input logic req_type,                // 0=Read , 1=Write
    input logic read_en_cache,                   
    input logic write_en_cache,            
    input logic refill,
    input [`BLOCK_SIZE-1:0] data_in_mem,     // 128-bit block from memory
    input logic [31:0] data_in, //32 bits data from cpu
    output logic [`BLOCK_SIZE-1:0] dirty_block_out,
    output logic hit,
    output logic [31:0] data_out,
    output logic dirty_bit,
    output logic done_cache
);
    //Declaring cache
    reg [`BLOCK_SIZE+25:0] cache [`BLOCKS-1:0]; 
    // Cache field extraction
    logic valid;
    logic [23:0] stored_tag;
    assign valid       = cache[index][0];
    assign dirty_bit       = cache[index][1];
    assign stored_tag = cache[index][25:2];               // tag_bits of cache_line
    assign [`BLOCK_SIZE-1:0] block = cache[index][153:26];
    
     // HIT logic
    always_comb begin
        hit = (valid && (tag == stored_tag)) ? 1 : 0;
    end
    always_ff @(posedge clk)begin  
            
        if (!req_type && hit && read_en_cache) begin
            case (blk_offset)
                2'b00: data_out <= block[0   +: 32];
                2'b01: data_out <= block[32  +: 32];
                2'b10: data_out <= block[64  +: 32];
                2'b11: data_out <= block[96  +: 32];
            endcase
         end            
        else if (dirty_bit && !hit && read_en_cache) begin
                dirty_block_out <= block; 
                 
        end         
        else if ( write_en_cache) begin
                cache[index][0]      <= 1'b1;         // valid bit
                cache[index][1]      <= 1'b0;         // clean block
                cache[index][25:2]   <= tag;          // store tag for future comparisons
                cache[index][153:26] <= data_in_mem;  //   Write the full block to cache
        end
           // WRITE HIT — update selected word in the block
        else if (req_type && hit && write_en_cache) begin
             case (blk_offset)
                2'b00: cache[57:26] <= data_in;
                2'b01: cache[89:58] <= data_in;
                2'b10: cache[121:90] <= data_in;
                2'b11: cache[153:122] <= data_in;
                default: ; // do nothing
             endcase
            cache[index][1] <= 1'b1;  // mark dirty
        end
    end  
endmodule
