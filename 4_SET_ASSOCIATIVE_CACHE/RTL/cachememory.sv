// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
// Author:  Ammarah Wakeel, Ayesha Anwar, Eman Nasarrr.
// Date: 5th, August, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE

// ============================================================================
// Module: cache_memory (4-way Set-Associative Cache with PLRU Replacement)
// Description:
//   Implements a 4-way set-associative cache with pseudo-LRU (PLRU) replacement
//   policy. Each cache line contains valid, dirty, tag, and block data fields.
//   Supports read, write, refill, and write-back of dirty blocks.
// 
// Parameters:
//   WORD_SIZE       : Number of bits per word (default 32).
//   WORDS_PER_BLOCK : Number of words in one block.
//   BLOCK_SIZE      : Total block size in bits (WORDS_PER_BLOCK * WORD_SIZE).
//   NUM_BLOCKS      : Total number of cache blocks (default 64).
//   NUM_WAYS        : Associativity (default 4).
//   NUM_SETS        : Number of sets (NUM_BLOCKS / NUM_WAYS).
//   CACHE_SIZE      : Cache size in bytes.
//   TAG_WIDTH       : Number of tag bits.
//   INDEX_WIDTH     : Number of index bits (log2(NUM_SETS)).
//   OFFSET_WIDTH    : Number of block offset bits (log2(WORDS_PER_BLOCK)).
//
// Cache Line Format (per block):
//   {valid[0], dirty[1], tag[TAG_WIDTH-1:0], block_data[BLOCK_SIZE-1:0]}
//
// PLRU Replacement Tree:
//   - Represented by 3 bits (b1, b2, b3).
//   - Guides replacement decisions when all ways are valid.
// ============================================================================

module cache_memory #(
    parameter int WORD_SIZE         = 32,
    parameter int WORDS_PER_BLOCK   = 4,
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
    parameter int NUM_BLOCKS        = 64,
    parameter int NUM_WAYS          = 4,
    parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS,
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
    parameter int TAG_WIDTH         = 25,
    parameter int INDEX_WIDTH       = $clog2(NUM_SETS),
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK)
)(
    input  logic clk,
    input  logic [TAG_WIDTH-1:0] tag,       // Tag bits of input address
    input  logic [INDEX_WIDTH-1:0] index,   // Set index
    input  logic [OFFSET_WIDTH-1:0] blk_offset, // Word offset inside block
    input  logic req_type,                  // 0=Read , 1=Write
    input  logic read_en_cache,             // Enable read from cache
    input  logic write_en_cache,            // Enable write to cache
    input  logic read_en_mem,               // Enable read from memory (refill)
    input  logic write_en_mem,              // Enable write to memory (write-back)
    input  logic [BLOCK_SIZE-1:0] data_in_mem, // Block fetched from memory
    input  logic [WORD_SIZE-1:0] data_in,      // Single word input for write
    output logic [BLOCK_SIZE-1:0] dirty_block_out, // Block to write back
    output logic hit,                       // Indicates hit or miss
    output logic [WORD_SIZE-1:0] data_out,  // Word output for read
    output logic dirty_bit                  // Dirty bit of accessed line
);   

    // ------------------ Data Structures ------------------

    // PLRU tree bits per set
    typedef struct {
        logic b1; // Root
        logic b2; // Left child
        logic b3; // Right child
    } tree_bits;

    // Cache line format: {valid, dirty, tag, block}
    typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;

    // Cache array: [set index][way]
    cache_line_t cache [NUM_SETS-1:0][3:0];

    // PLRU state array: one tree per set
    tree_bits plru [NUM_SETS-1:0];    

    // Info struct for each way
    typedef struct  {
        logic valid;
        logic dirty;
        logic [TAG_WIDTH-1:0] tag;
        logic [BLOCK_SIZE-1:0] block;
        logic hit;
    } cache_info_t;

    cache_info_t info0, info1, info2, info3;    

    // ------------------ Cache Line Decoding ------------------
    always_comb begin
        // Way 0
        info0.valid = cache[index][0][0];
        info0.dirty = cache[index][0][1];
        info0.tag   = cache[index][0][TAG_WIDTH+1:2];
        info0.block = cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info0.hit   = info0.valid && (tag == info0.tag);

        // Way 1
        info1.valid = cache[index][1][0];
        info1.dirty = cache[index][1][1];
        info1.tag   = cache[index][1][TAG_WIDTH+1:2];
        info1.block = cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info1.hit   = info1.valid && (tag == info1.tag);

        // Way 2
        info2.valid = cache[index][2][0];
        info2.dirty = cache[index][2][1];
        info2.tag   = cache[index][2][TAG_WIDTH+1:2];
        info2.block = cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info2.hit   = info2.valid && (tag == info2.tag);

        // Way 3
        info3.valid = cache[index][3][0];
        info3.dirty = cache[index][3][1];
        info3.tag   = cache[index][3][TAG_WIDTH+1:2];
        info3.block = cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info3.hit   = info3.valid && (tag == info3.tag);
    end    

    // Hit if any way matches
    assign hit = info0.hit || info1.hit || info2.hit || info3.hit;    

    // ------------------ PLRU Replacement ------------------
    logic [1:0] lru_line; // Selected way for replacement
    always_comb begin
        if (plru[index].b1 == 0) begin
            if (plru[index].b2 == 0) lru_line = 0;
            else                     lru_line = 1;
        end else begin
            if (plru[index].b3 == 0) lru_line = 2;
            else                     lru_line = 3;
        end
    end   

    // Next PLRU state update logic
    logic [2:0] plru_next;
    logic [1:0] accessed_line;
    always_comb begin
        plru_next = {plru[index].b1, plru[index].b2, plru[index].b3}; // Hold default
        case (accessed_line)
            0: begin plru_next[2] = 1; plru_next[1] = 1; end // Access way 0
            1: begin plru_next[2] = 1; plru_next[1] = 0; end // Access way 1
            2: begin plru_next[2] = 0; plru_next[0] = 1; end // Access way 2
            3: begin plru_next[2] = 0; plru_next[0] = 0; end // Access way 3
        endcase
    end

    // ------------------ Main Cache Control ------------------
    always_ff @(posedge clk) begin
        data_out <= '0;
        dirty_block_out<= '0;
        accessed_line <= 'x; // Default

        if (!hit) begin 
            // ---------------- MISS Handling ----------------

            // Allocate into empty ways if available
            if (!info0.valid && read_en_mem && write_en_cache) begin
                cache[index][0][0] <= 1;  // valid
                cache[index][0][1] <= 0;  // dirty=0
                cache[index][0][TAG_WIDTH+1:2] <= tag;
                cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 0;

            end else if (!info1.valid && read_en_mem && write_en_cache) begin
                cache[index][1][0] <= 1;
                cache[index][1][1] <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 1;

            end else if (!info2.valid && read_en_mem && write_en_cache) begin
                cache[index][2][0] <= 1;
                cache[index][2][1] <= 0;
                cache[index][2][TAG_WIDTH+1:2] <= tag;
                cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 2;

            end else if (!info3.valid && read_en_mem && write_en_cache) begin
                cache[index][3][0] <= 1;
                cache[index][3][1] <= 0;
                cache[index][3][TAG_WIDTH+1:2] <= tag;
                cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                accessed_line <= 3;
            
            end else if (read_en_cache && write_en_mem) begin
                // Write-back dirty block before replacement
                case (lru_line)
                    0: if (info0.dirty) begin dirty_block_out <= info0.block; cache[index][0][1] <= 0; accessed_line <= 0; end
                    1: if (info1.dirty) begin dirty_block_out <= info1.block; cache[index][1][1] <= 0; accessed_line <= 1; end
                    2: if (info2.dirty) begin dirty_block_out <= info2.block; cache[index][2][1] <= 0; accessed_line <= 2; end
                    3: if (info3.dirty) begin dirty_block_out <= info3.block; cache[index][3][1] <= 0; accessed_line <= 3; end
                endcase

            end else if (read_en_mem && write_en_cache) begin
                // Replace using PLRU when all ways are valid
                case (lru_line)
                    0: if (!info0.dirty) begin cache[index][0][0] <= 1; cache[index][0][1] <= 0; cache[index][0][TAG_WIDTH+1:2] <= tag;
                        cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; accessed_line <= 0; end 
                    1: if (!info1.dirty) begin cache[index][1][0] <= 1; cache[index][1][1] <= 0; cache[index][1][TAG_WIDTH+1:2] <= tag;
                        cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; accessed_line <= 1; end 
                    2: if (!info2.dirty) begin cache[index][2][0] <= 1; cache[index][2][1] <= 0; cache[index][2][TAG_WIDTH+1:2] <= tag;
                        cache[index][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; accessed_line <= 2; end 
                    3: if (!info3.dirty) begin cache[index][3][0] <= 1; cache[index][3][1] <= 0; cache[index][3][TAG_WIDTH+1:2] <= tag;
                        cache[index][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; accessed_line <= 3; end 
                endcase
            end  

        end else begin 
            // ---------------- HIT Handling ----------------
            if (req_type && write_en_cache) begin
                // Write Hit
                if (info0.hit) begin cache[index][0][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in; cache[index][0][1] <= 1; accessed_line <= 0; end
                else if (info1.hit) begin cache[index][1][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in; cache[index][1][1] <= 1; accessed_line <= 1; end
                else if (info2.hit) begin cache[index][2][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in; cache[index][2][1] <= 1; accessed_line <= 2; end
                else if (info3.hit) begin cache[index][3][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in; cache[index][3][1] <= 1; accessed_line <= 3; end

            end else if (!req_type && read_en_cache) begin
                // Read Hit
                if (info0.hit) begin data_out <= info0.block[blk_offset*WORD_SIZE +: WORD_SIZE]; accessed_line <= 0; end
                else if (info1.hit) begin data_out <= info1.block[blk_offset*WORD_SIZE +: WORD_SIZE]; accessed_line <= 1; end
                else if (info2.hit) begin data_out <= info2.block[blk_offset*WORD_SIZE +: WORD_SIZE]; accessed_line <= 2; end
                else if (info3.hit) begin data_out <= info3.block[blk_offset*WORD_SIZE +: WORD_SIZE]; accessed_line <= 3; end
            end
        end

        // ---------------- Update PLRU ----------------
        if (accessed_line !== 'x) begin
            plru[index].b1 <= plru_next[2];
            plru[index].b2 <= plru_next[1];
            plru[index].b3 <= plru_next[0];
        end
    end

endmodule
