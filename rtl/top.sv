module top (
    input  logic clk,
    input  logic rst,

    // From CPU
    input  logic        req_valid,
    input  logic        req_type,        // 0 = Read, 1 = Write
    input  logic [31:0] data_in,
    input logic [31:0] address,
    // To CPU
    output logic [31:0] data_out,
    output logic        done_cache
);
    // Decoder outputs
    logic [23:0] tag;
    logic [5:0] index;
    logic [1:0] blk_offset;
    //Cache_mem signals I/O
    logic  refill, read_en_cache, write_en_cache,[`BLOCK_SIZE-1:0] dirty_block_out, dirty_bit,hit;
    //Mem signals
    logic read_en_mem, write_en_mem, [`BLOCK_SIZE-1:0] data_out_mem, ready_mem, [`BLOCK_SIZE-1:0] dirty_block_in;

    //Instantiation
    cache_decoder decoder (
    .tag(tag),
    .index(index),
    .blk_offset(blk_offset)
    );
    cache_controller controller (
    .clk(clk),
    .rst(rst),
    .req_valid(req_valid),
    .req_type(req_type),
    .hit(hit),
    .dirty_bit(dirty_bit),
    .ready_mem(ready_mem),
    .read_en_mem(read_en_mem),
    .write_en_mem(write_en_mem),
    .write_en_cache(write_en_cache),
    .read_en_cache(read_en_cache),
    .refill(refill)
    );
    cache_memory cache (
    .clk(clk),
    .tag(tag),
    .index(index),
    .blk_offset(blk_offset),
    .req_type(req_type),
    .read_en_cache(read_en_cache),
    .write_en_cache(write_en_cache),
    .refill(refill),
    .data_in_mem(data_out_mem),         // From main memory
    .data_in(data_in),       // Word from CPU
    .dirty_block_out(dirty_block_out), // To memory
    .hit(hit),
    .data_out(data_out),
    .dirty_bit(dirty_bit),                // You'll need to expose this from cache
    .done_cache(done_cache)                
   );
  
endmodule
