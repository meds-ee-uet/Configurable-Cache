// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Author: Ammarah Wakeel, Ayesha Anwar, Eman Nasar.
// Date: 17th, july, 2025.
// ============================================================================
// Module: cache_memory
// Description:
//   Implements a 2-way set associative cache with the following features:
//     - Parameterized cache (word size, block size, number of sets/ways)
//     - Tag, index, and block offset decoding
//     - PLRU (Pseudo-LRU) replacement policy
//     - Dirty-bit management (write-back support)
//     - Read and write hit handling
//     - Refill on misses with dirty/clean eviction
//
// Cache line format per way:
//   --------------------------------------------------------------
//   | Valid (1) | Dirty (1) | Tag (TAG_WIDTH) | Block data (BLOCK_SIZE) |
//   --------------------------------------------------------------
// ============================================================================

module cache_memory #(
    // ---------------- General Cache Parameters ----------------
    parameter int WORD_SIZE         = 32, // Size of a single word in bits
    parameter int WORDS_PER_BLOCK   = 4,  // Words per cache block
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE, // Block size in bits
    parameter int NUM_BLOCKS        = 64, // Total blocks in the cache
    parameter int NUM_WAYS          = 2,  // 2-way set associative
    parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS, // Sets = blocks / ways
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8, // Cache size in bytes
    parameter int TAG_WIDTH         = 25, // Tag bits
    parameter int INDEX_WIDTH       = $clog2(NUM_SETS), // Index bits (select set)
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK) // Offset bits (word select)
)(
    // ---------------- Ports ----------------
    input  logic clk,                                    // System clock
    input  logic [TAG_WIDTH-1:0] tag,                    // Input tag
    input  logic [INDEX_WIDTH-1:0] index,                // Input index
    input  logic [OFFSET_WIDTH-1:0] blk_offset,          // Word offset in block
    input  logic req_type,                               // 0 = Read, 1 = Write
    input  logic read_en_cache,                          // Enable read request
    input  logic write_en_cache,                         // Enable write request
    input  logic [BLOCK_SIZE-1:0] data_in_mem,           // Block data from memory (for refill)
    input  logic [WORD_SIZE-1:0] data_in,                // Single word input (for write)
    output logic [BLOCK_SIZE-1:0] dirty_block_out,       // Block sent back to memory (if dirty eviction)
    output logic hit,                                    // Hit flag
    output logic [WORD_SIZE-1:0] data_out,               // Read data output
    output logic dirty_bit                               // Current dirty bit status
);

    // =========================================================================
    // Cache line representation:
    // Each cache line = {valid, dirty, tag, block}
    // =========================================================================
    typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;

    // Cache: 2D array [set][way]
    cache_line_t cache [NUM_SETS-1:0][1:0];  

    // =========================================================================
    // PLRU (Pseudo-LRU) replacement bits per set
    //  - 0 means way0 is LRU
    //  - 1 means way1 is LRU
    // =========================================================================
    logic plru [NUM_SETS-1:0];

    // =========================================================================
    // Struct to make cache line fields easier to use
    // =========================================================================
    typedef struct packed {
        logic valid;                     // Valid bit
        logic dirty;                     // Dirty bit
        logic [TAG_WIDTH-1:0] tag;       // Tag bits
        logic [BLOCK_SIZE-1:0] block;    // Block data
        logic hit;                       // Hit signal (for this way)
    } cache_info_t; 

    cache_info_t info0, info1;  // Metadata for way0 and way1

    // =========================================================================
    // Decode cache line fields into structured info for each way
    // =========================================================================
    always_comb begin
        // ---------------- Way 0 ----------------
        info0.valid = cache[index][0][0];
        info0.dirty = cache[index][0][1];
        info0.tag   = cache[index][0][TAG_WIDTH+1:2];
        info0.block = cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info0.hit   = info0.valid && (tag == info0.tag);

        // ---------------- Way 1 ----------------
        info1.valid = cache[index][1][0];
        info1.dirty = cache[index][1][1];
        info1.tag   = cache[index][1][TAG_WIDTH+1:2];
        info1.block = cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
        info1.hit   = info1.valid && (tag == info1.tag);
    end

    // Hit occurs if either way matches
    assign hit = info0.hit || info1.hit;

    // =========================================================================
    // Main cache operations
    // =========================================================================
    always_ff @(posedge clk) begin
        // Reset outputs each cycle
        data_out <= '0;
        dirty_block_out <= '0;

        // -------------------------- MISS Handling --------------------------
        if (!hit) begin
            // Case 1: Way 0 invalid → allocate here
            if (!info0.valid && read_en_mem && write_en_cache) begin
                cache[index][0][0] <= 1;                       // Valid
                cache[index][0][1] <= 0;                       // Clean
                cache[index][0][TAG_WIDTH+1:2] <= tag;          // Store tag
                cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem; // Store block
                plru[index] <= 1;                              // Mark way1 as LRU

            // Case 2: Way 1 invalid → allocate here
            end else if (!info1.valid && read_en_mem && write_en_cache) begin
                cache[index][1][0] <= 1;
                cache[index][1][1] <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 0;                              // Mark way0 as LRU

            // Case 3: Both valid → use PLRU to select eviction (clean victim)
            end else if (info0.valid && plru[index] == 0 && !info0.dirty && read_en_mem && write_en_cache) begin
                cache[index][0][0] <= 1;
                cache[index][0][1] <= 0;
                cache[index][0][TAG_WIDTH+1:2] <= tag;
                cache[index][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 1;

            end else if (info1.valid && plru[index] == 1 && !info1.dirty && read_en_mem && write_en_cache) begin
                cache[index][1][0] <= 1;
                cache[index][1][1] <= 0;
                cache[index][1][TAG_WIDTH+1:2] <= tag;
                cache[index][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
                plru[index] <= 0;

            // Case 4: Victim is dirty → write back block to memory first
            end else if (info0.valid && plru[index] == 0 && info0.dirty && read_en_cache && write_en_mem) begin
                dirty_block_out <= info0.block;
                cache[index][1][1] <= 0; // Clear dirty

            end else if (info1.valid && plru[index] == 1 && info1.dirty && read_en_cache && write_en_cache) begin
                dirty_block_out <= info1.block;
                cache[index][1][1] <= 0; // Clear dirty
            end

        // -------------------------- WRITE HIT Handling --------------------------
        end else if (req_type && hit) begin
            if (info0.hit && write_en_cache) begin
                cache[index][0][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in; // Update word
                cache[index][0][1] <= 1;    // Set dirty
                plru[index] <= 1;           // Mark way1 as LRU

            end else if (info1.hit && write_en_cache) begin
                cache[index][1][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
                cache[index][1][1] <= 1;
                plru[index] <= 0;           // Mark way0 as LRU
            end

        // -------------------------- READ HIT Handling --------------------------
        end else if (!req_type && hit) begin
            if (info0.hit && read_en_cache) begin
                data_out <= info0.block[blk_offset*WORD_SIZE +: WORD_SIZE]; // Extract word
                plru[index] <= 1;  // Mark way1 as LRU

            end else if (info1.hit && read_en_cache) begin
                data_out <= info1.block[blk_offset*WORD_SIZE +: WORD_SIZE];
                plru[index] <= 0;  // Mark way0 as LRU
            end
        end
    end
endmodule

