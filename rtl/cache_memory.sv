`include "cache_defines.svh"
module cache_memory #() (
    input  logic clk,
    input  logic [TAG_WIDTH-1:0] tag,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [OFFSET_WIDTH-1:0] blk_offset,
    input  logic req_type,                // 0=Read , 1=Write
    input  logic read_en_cache,
    input  logic write_en_cache,
    input  logic refill,
    input  logic [BLOCK_SIZE-1:0] data_in_mem,
    input  logic [WORD_SIZE-1:0] data_in,
    output logic [BLOCK_SIZE-1:0] dirty_block_out,
    output logic hit,
    output logic [WORD_SIZE-1:0] data_out,
    output logic dirty_bit,
    output logic done_cache
);

    cache_line_t cache [NUM_BLOCKS-1:0];

    // Field extraction
    logic valid;
    logic [TAG_WIDTH-1:0] stored_tag;
    logic [BLOCK_SIZE-1:0] block;

    assign valid       = cache[index][0];
    assign dirty_bit   = cache[index][1];
    assign stored_tag  = cache[index][TAG_WIDTH+1:2];
    assign block       = cache[index][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];

    // HIT logic
    always_comb begin
        hit = (valid && (tag == stored_tag)) ? 1 : 0;
    end

    always_ff @(posedge clk) begin
        done_cache <= 0;
        if (read_en_mem && write_en_cache) begin
            cache[index][0] <= 1'b1;
            cache[index][1] <= 1'b0;
            cache[index][TAG_WIDTH+1:2] <= tag;
            cache[index][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
            done_cache <= 1;
        end 
        else if (req_type && hit && write_en_cache) begin
            cache[index][BLOCK_SIZE + TAG_WIDTH + 1 - blk_offset*WORD_SIZE -: WORD_SIZE] <= data_in;
            cache[index][1] <= 1'b1;
            done_cache <= 1;
        end 
        else if (!req_type && hit && read_en_cache) begin
            data_out <= cache[index][BLOCK_SIZE + TAG_WIDTH + 1 - blk_offset*WORD_SIZE -: WORD_SIZE];
            done_cache <= 1;
        end 
        else begin
            data_out <= '0;
        end

        if (dirty_bit && !hit && read_en_cache) begin
            dirty_block_out <= block;
        end else begin
            dirty_block_out <= '0;
        end
    end

endmodule
