// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the code of n way set associative  cache memory.
//
// Author: Ammarah Wakeel, Ayesha Anwar, Eman Nasar.
// Date: 20th, August, 2025.
// Code your design here
// ============================================================================
// N-way Set-Associative Cache with Tree-based PLRU (Write-back, Write-allocate)
// ----------------------------------------------------------------------------
// - NUM_WAYS must be a power of two (>=2). Uses (NUM_WAYS-1) PLRU bits per set.
// - Cache line encoding: { valid[0], dirty[1], tag[TAG_WIDTH-1:0], block[BLOCK_SIZE-1:0] }
// - Handshake style matches your earlier 2/4-way designs:
//     * Refill when (read_en_mem && write_en_cache)
//     * Writeback when (read_en_cache && write_en_mem) and victim is dirty
// - On refill: line is inserted clean and marked MRU in PLRU
// - On write hit: line marked dirty and PLRU updated to MRU
// ============================================================================

module cache_memory #(
  parameter int WORD_SIZE         = 32,
  parameter int WORDS_PER_BLOCK   = 4,
  parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE,
  parameter int NUM_BLOCKS        = 64,
  parameter int NUM_WAYS          = 2, // Change the associativity factor according to your need.
  parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS,
  parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8,
  parameter int INDEX_WIDTH       = $clog2(NUM_SETS),
  parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK),
  parameter int TAG_WIDTH         = 32 - (INDEX_WIDTH + OFFSET_WIDTH)
)(
  input  logic                          clk,
  input  logic [TAG_WIDTH-1:0]          tag,
  input  logic [INDEX_WIDTH-1:0]        index,
  input  logic [OFFSET_WIDTH-1:0]       blk_offset,
  input  logic                          req_type,        // 0 = Read, 1 = Write
  input  logic                          read_en_cache,
  input  logic                          write_en_cache,
  input  logic                          read_en_mem,
  input  logic                          write_en_mem,
  input  logic [BLOCK_SIZE-1:0]         data_in_mem,
  input  logic [WORD_SIZE-1:0]          data_in,
  output logic [BLOCK_SIZE-1:0]         dirty_block_out,
  output logic                          hit,
  output logic [WORD_SIZE-1:0]          data_out,
  output logic                          dirty_bit
);

  localparam int DEPTH = (NUM_WAYS > 1) ? $clog2(NUM_WAYS) : 1;
  localparam int TREE_BITS = NUM_WAYS - 1;

  initial begin
    if (NUM_WAYS < 2 || (NUM_WAYS & (NUM_WAYS - 1)) != 0) begin
      $error("NUM_WAYS (%0d) must be a power of two and >= 2", NUM_WAYS);
    end
  end

  typedef logic [BLOCK_SIZE + TAG_WIDTH + 2 - 1 : 0] cache_line_t;
  cache_line_t cache [NUM_SETS-1:0][NUM_WAYS-1:0];

  logic [TREE_BITS-1:0] plru [NUM_SETS-1:0];

  typedef struct packed {
    logic valid;
    logic dirty;
    logic [TAG_WIDTH-1:0] tag;
    logic [BLOCK_SIZE-1:0] block;
    logic hit;
  } cache_info_t;

  cache_info_t info [NUM_WAYS-1:0];

  genvar w;
generate
  for (w = 0; w < NUM_WAYS; w++) begin : decode_lines
    always_comb begin
      info[w].valid = cache[index][w][0];
      info[w].dirty = cache[index][w][1];
      info[w].tag   = cache[index][w][TAG_WIDTH+1:2];
      info[w].block = cache[index][w][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2];
      info[w].hit   = (info[w].valid == 1'b1) && (tag == info[w].tag);
    end
  end
endgenerate

  

  logic hit_comb;
  always_comb begin
    hit_comb = 1'b0;
    for (int i = 0; i < NUM_WAYS; i++) begin
      if (info[i].hit) hit_comb = 1'b1;
    end
  end
  assign hit = hit_comb;

  // Dirty if the selected victim is dirty
  logic [$clog2(NUM_WAYS)-1:0] victim_way;
  assign dirty_bit = info[victim_way].dirty && info[victim_way].valid;

  // ----------------- Invalid Way Search -----------------
  logic [$clog2(NUM_WAYS)-1:0] invalid_way;
  logic invalid_found;
  always_comb begin
    invalid_found = 1'b0;
    invalid_way = '0;
    for (int i = 0; i < NUM_WAYS; i++) begin
      if (!info[i].valid && !invalid_found) begin
        invalid_way = i;
        invalid_found = 1'b1;
      end
    end
  end

  // ----------------- PLRU Victim Way -----------------
  always_comb begin
    automatic int node;   //  fixed
    int lvl;              //  fixed
    logic dir;
    victim_way = '0;
    node = 0;
    for (lvl = 0; lvl < DEPTH; lvl++) begin
      dir = plru[index][node];
      if (dir) begin
        victim_way |= (1 << (DEPTH-1-lvl));
        node = 2*node + 2;
      end else begin
        node = 2*node + 1;
      end
    end
  end

  // ----------------- PLRU Update Logic -----------------
  logic [$clog2(NUM_WAYS)-1:0] accessed_way;
  logic accessed_valid;
  logic [TREE_BITS-1:0] plru_next;

  always_comb begin
    automatic int node;   // declare first
    int lvl;
    logic dir;

    plru_next = plru[index];  // statements after declarations
    node = 0;
    for (lvl = 0; lvl < DEPTH; lvl++) begin
      dir = accessed_way[DEPTH-1-lvl];
      plru_next[node] = ~dir;
      node = dir ? (2*node + 2) : (2*node + 1);
    end
end


  // ----------------- Refill Tracking -----------------
  logic writeback_pending;                       //  moved up before use
  logic [$clog2(NUM_WAYS)-1:0] pending_victim_way;

  // ----------------- Main Control -----------------
  always_ff @(posedge clk) begin
    data_out <= '0;
    dirty_block_out <= '0;
    accessed_valid <= 1'b0;
    accessed_way <= '0;

    // Handle post-writeback refill
    if (writeback_pending && read_en_mem && write_en_cache) begin
      cache[index][pending_victim_way][0] <= 1'b1;
      cache[index][pending_victim_way][1] <= 1'b0;
      cache[index][pending_victim_way][TAG_WIDTH+1:2] <= tag;
      cache[index][pending_victim_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;

      accessed_way <= pending_victim_way;
      accessed_valid <= 1'b1;
      writeback_pending <= 1'b0;
    end

    // Miss Handling
    else if (!hit) begin
      if (invalid_found) begin
        if (read_en_mem && write_en_cache) begin
          cache[index][invalid_way][0] <= 1'b1;
          cache[index][invalid_way][1] <= 1'b0;
          cache[index][invalid_way][TAG_WIDTH+1:2] <= tag;
          cache[index][invalid_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
          accessed_way <= invalid_way;
          accessed_valid <= 1'b1;
        end
      end else begin
        if (!info[victim_way].dirty) begin
          if (read_en_mem && write_en_cache) begin
            cache[index][victim_way][0] <= 1'b1;
            cache[index][victim_way][1] <= 1'b0;
            cache[index][victim_way][TAG_WIDTH+1:2] <= tag;
            cache[index][victim_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] <= data_in_mem;
            accessed_way <= victim_way;
            accessed_valid <= 1'b1;
          end
        end else begin
          if (read_en_cache && write_en_mem) begin
            dirty_block_out <= info[victim_way].block;
            cache[index][victim_way][1] <= 1'b0;
            writeback_pending <= 1'b1;
            pending_victim_way <= victim_way;
          end
        end
      end
    end

    // Hit Handling
    else begin
      if (req_type && write_en_cache) begin
        for (int i = 0; i < NUM_WAYS; i++) begin
          if (info[i].hit) begin
            cache[index][i][TAG_WIDTH + 2 + blk_offset * WORD_SIZE +: WORD_SIZE] <= data_in;
            cache[index][i][1] <= 1'b1;
            accessed_way <= i;
            accessed_valid <= 1'b1;
          end
        end
      end else if (!req_type && read_en_cache) begin
        for (int i = 0; i < NUM_WAYS; i++) begin
          if (info[i].hit) begin
            data_out <= info[i].block[blk_offset*WORD_SIZE +: WORD_SIZE];
            accessed_way <= i;
            accessed_valid <= 1'b1;
          end
        end
      end
    end

    //  Apply PLRU update only if access occurred
    if (accessed_valid) begin
      plru[index] <= plru_next;
    end
  end

endmodule
