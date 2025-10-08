// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the testbench code to verify all read cases of n way cache memory module for 8 way implementation.
//
// Author: Ammarah Wakeel.
// Date: 17th, August, 2025.
// Code your testbench here
`timescale 1ns/1ps

module tb_cache_read_hit_preload;

  // Parameters
  localparam int WORD_SIZE       = 32;
  localparam int WORDS_PER_BLOCK = 4;
  localparam int BLOCK_SIZE      = WORDS_PER_BLOCK * WORD_SIZE;
  localparam int NUM_BLOCKS      = 64;
  localparam int NUM_WAYS        = 8;
  localparam int NUM_SETS        = NUM_BLOCKS / NUM_WAYS;
  localparam int INDEX_WIDTH     = $clog2(NUM_SETS);       // = 3
  localparam int OFFSET_WIDTH    = $clog2(WORDS_PER_BLOCK);// = 2
  localparam int TAG_WIDTH       = 32 - (INDEX_WIDTH + OFFSET_WIDTH); // = 27

  // DUT I/O
  logic clk;
  logic [TAG_WIDTH-1:0] tag;
  logic [INDEX_WIDTH-1:0] index;
  logic [OFFSET_WIDTH-1:0] blk_offset;
  logic req_type;
  logic read_en_cache, write_en_cache;
  logic read_en_mem, write_en_mem;
  logic [BLOCK_SIZE-1:0] data_in_mem;
  logic [WORD_SIZE-1:0]  data_in;
  logic [BLOCK_SIZE-1:0] dirty_block_out;
  logic hit;
  logic [WORD_SIZE-1:0]  data_out;
  logic dirty_bit;

  // Instantiate DUT
  cache_memory #(
    .WORD_SIZE(WORD_SIZE),
    .WORDS_PER_BLOCK(WORDS_PER_BLOCK),
    .NUM_BLOCKS(NUM_BLOCKS),
    .NUM_WAYS(NUM_WAYS)
  ) uut (
    .clk(clk),
    .tag(tag),
    .index(index),
    .blk_offset(blk_offset),
    .req_type(req_type),
    .read_en_cache(read_en_cache),
    .write_en_cache(write_en_cache),
    .read_en_mem(read_en_mem),
    .write_en_mem(write_en_mem),
    .data_in_mem(data_in_mem),
    .data_in(data_in),
    .dirty_block_out(dirty_block_out),
    .hit(hit),
    .data_out(data_out),
    .dirty_bit(dirty_bit)
  );

  // Clock
  always #5 clk = ~clk;

  // =========================================
  // Preload set 0 with 8 ways
  // =========================================
  initial begin
    clk = 0;
    for (int s = 0; s < NUM_SETS; s++) begin
      for (int w = 0; w < NUM_WAYS; w++) begin
        uut.cache[s][w] = '0;
      end
    end

    // Each entry format: {128-bit block, 27-bit tag, dirty, valid}

    // Way 0
    uut.cache[0][0] = {
        128'hAAAABBBB_CCCC1111_DDDD2222_EEEE3333,
        27'h0ABCDE,
        1'b0, 1'b1
    };

    // Way 1
    uut.cache[0][1] = {
        128'h12345678_9ABCDEF0_FEDCBA98_76543210,
        27'h0BCDEF,
        1'b0, 1'b1
    };

    // Way 2
    uut.cache[0][2] = {
        128'hFACEFACE_BEEFBEEF_DEADDEAD_CAFECAFE,
        27'h0CDEF0,
        1'b0, 1'b1
    };

    // Way 3
    uut.cache[0][3] = {
        128'h11112222_33334444_55556666_77778888,
        27'h0DEF01,
        1'b0, 1'b1
    };

    // Way 4
    uut.cache[0][4] = {
        128'hAAAA0000_BBBB1111_CCCC2222_DDDD3333,
        27'h0EE001,
        1'b0, 1'b1
    };

    // Way 5
    uut.cache[0][5] = {
        128'h44445555_66667777_88889999_AAAA0000,
        27'h0FF002,
        1'b1, 1'b1 //MADE DIRTY BIT ONE FOR CHECKING RREAD MISS DIRTY CHECKIING
    };

    // Way 6
    uut.cache[0][6] = {
        128'hABCDEF01_23456789_13579BDF_2468ACE0,
        27'h0AA123,
        1'b0, 1'b1
    };

    // Way 7
    uut.cache[0][7] = {
        128'hCAFEBABE_DEADC0DE_FEEDBEEF_ABCD9999,
        27'h0BB456,
        1'b0, 1'b1
    };
    
    // =========================
// Preload Set=1, Way=3
// =========================
uut.cache[1][3] = {
    128'hAAAA1111_BBBB2222_CCCC3333_DDDD4444, // 4 words in block
    27'h11AA33,                               // tag (27 bits)
    1'b0,                                     // dirty = 0 (clean)
    1'b1                                      // valid = 1
};

// =========================
// Preload Set=1, Way=5
// =========================
uut.cache[1][5] = {
    128'h55556666_77778888_9999AAAA_BBBBCCCC,
    27'h22BB44,
    1'b0,
    1'b1
};

// =========================
// Preload Set=1, Way=7
// =========================
uut.cache[1][7] = {
    128'hDEADBEAF_FEEDFACE_CAFEBABE_12345678,
    27'h33CC55,
    1'b0,
    1'b1
};
    
// =========================
// Preload Set=1, Way=1
// =========================
uut.cache[1][1] = {
    128'hFACE1234_C0DE5678_BEEF9ABC_76543210,
    27'h44DD66,
    1'b0,
    1'b1
};
  end

  // ===============================
  // Task: perform_read_hit
  // ===============================
  task automatic perform_read_hit(
      input  logic [INDEX_WIDTH-1:0] index_in,
      input  logic [TAG_WIDTH-1:0]   tag_in,
      input  logic [OFFSET_WIDTH-1:0] blk_offset_in,
      input  logic [WORD_SIZE-1:0]   expected_data,
      input  int                     way_id
  );
  begin
      @(posedge clk);
      index        = index_in;
      tag          = tag_in;
      blk_offset   = blk_offset_in;
      req_type     = 0;
      read_en_cache = 1;

      @(posedge clk);
      read_en_cache = 0;

      @(posedge clk);
      $display("[READ HIT] Way=%0d Hit=%b Data_out=%h", way_id, hit, data_out);

      if (hit && data_out == expected_data)
        $display("[PASS] READ HIT Way%0d worked. Data_out=%h", way_id, data_out);
      else
        $display("[FAIL] READ HIT Way%0d mismatch. Got=%h Expected=%h",
                 way_id, data_out, expected_data);

      $display("-----------------------------------------------------");
  end
  endtask
  
  // ===============================
// Task: perform_read_miss_clean
// ===============================
task automatic perform_read_miss_clean(
    input  logic [3:0]   index_in,        // cache index
    input  logic [25:0]  new_tag,         // tag that will miss
    input  logic [1:0]   blk_offset_in,   // block word offset for miss
    input  logic [127:0] refill_data,     // block to refill from memory
    input  logic [31:0]  expected_word    // expected word after refill
);
begin
    $display("====================================================");
    $display(" READ MISS WITH CLEAN BLOCK (Set=%0d, Tag=%h)", index_in, new_tag);

    // ---- Step 1: Generate a miss ----
    @(posedge clk);
    index         = index_in;
    tag           = new_tag;
    blk_offset    = blk_offset_in;
    req_type      = 0;            // Read
    read_en_cache = 1;

    @(posedge clk); // launch
    @(posedge clk); // wait to see hit=0

    if (!hit)
        $display("[INFO] Miss detected correctly at Set=%0d (expected)", index_in);
    else
        $display("[FAIL] Unexpected hit on miss case.");

    // ---- Step 2: Simulate memory refill ----
    read_en_cache  = 0;
    read_en_mem    = 1;
    write_en_cache = 1;
    data_in_mem    = refill_data;

    @(posedge clk);
    $display("[REFILL] Data_in_mem = %h", data_in_mem);

    @(posedge clk);
    $display("[REFILL] Cache line written at Set=%0d, Way=%0d", 
              index_in, uut.accessed_way);

    read_en_mem    = 0;
    write_en_cache = 0;

    $display("[REFILL] Cache contents (Set=%0d, Way=%0d) = %h", 
             index_in, uut.accessed_way,
             uut.cache[index_in][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

    // ---- Step 3: Read again with same tag/index → should hit ----
    @(posedge clk);
    tag           = new_tag;   // Same tag to hit
    blk_offset    = blk_offset_in;
    req_type      = 0;
    read_en_cache = 1;

    @(posedge clk);
    @(posedge clk); // wait for data_out

    if (hit && data_out == expected_word)
        $display("[PASS] Read Miss Clean → Refetched correctly. Data_out=%h", data_out);
    else
        $display("[FAIL] Read Miss Clean → Incorrect refill. Got=%h Expected=%h",
                  data_out, expected_word);

    $display("-----------------------------------------------------");
end
endtask
  
  
// ===============================
// Task: perform_read_miss_dirty
// ===============================
task automatic perform_read_miss_dirty(
    input  logic [3:0]   index_in,        // cache index
    input  logic [25:0]  new_tag,         // new tag that will cause miss
    input  logic [1:0]   blk_offset_in,   // word offset for request
    input  logic [127:0] refill_data,     // memory block to bring into cache
    input  logic [31:0]  expected_word    // expected word after refill
);
begin
    $display("====================================================");
    $display(" READ MISS WITH DIRTY VICTIM (Set=%0d, Tag=%h)", index_in, new_tag);

    // =================================================
    // Phase B: Issue READ MISS Dirty block
    // =================================================
    @(posedge clk);
    index         = index_in;
    tag           = new_tag;
    blk_offset    = blk_offset_in;
    req_type      = 0;
    read_en_cache = 1;

    @(posedge clk);
    if (!hit)
        $display("[PHASE B] PASS: Miss detected, dirty victim will be evicted.");
    else
        $display("[PHASE B] FAIL: Unexpected hit on dirty miss case.");

    // =================================================
    // Phase C: WRITE-BACK dirty victim
    // =================================================
    write_en_mem = 1;  // handshake with memory for write-back
    @(posedge clk); @(posedge clk);
    $display("[PHASE C] WRITE-BACK: dirty_block_out = %h", dirty_block_out);

    write_en_mem  = 0;
    read_en_cache = 0;

    // =================================================
    // Phase D: REFILL from memory
    // =================================================
    @(posedge clk);
    read_en_mem    = 1;
    write_en_cache = 1;
    data_in_mem    = refill_data;

    @(posedge clk);
    $display("[REFILL] Data_in_mem = %h", data_in_mem);

    @(posedge clk);
    $display("[REFILL] Cache line written at Set=%0d, Way=%0d",
              index_in, uut.accessed_way);

    read_en_mem    = 0;
    write_en_cache = 0;

    // =================================================
    // Phase E: Re-read with new tag → should HIT
    // =================================================
    @(posedge clk);
    tag           = new_tag;
    blk_offset    = blk_offset_in;
    read_en_cache = 1;

    @(posedge clk); @(posedge clk);
    if (hit && data_out == expected_word)
        $display("[PHASE E] PASS: Post-refill HIT. Data_out=%h", data_out);
    else
        $display("[PHASE E] FAIL: Post-refill mismatch. Got=%h Expected=%h",
                  data_out, expected_word);

    @(posedge clk);
    read_en_cache = 0;

    $display("-----------------------------------------------------");
end
endtask


  // =========================================
  // Test stimulus
  // =========================================
  initial begin
    $display("===============================================");
    $display(" READ HIT CASES (8-way, Set=0, TAG=27 bits)");
    $display("===============================================");

    perform_read_hit(3'd0, 27'h0DEF01, 2'd0, 32'h77778888, 3); // Way 3, Word0
    perform_read_hit(3'd0, 27'h0FF002, 2'd1, 32'h88889999, 5); // Way 5, Word2
    perform_read_hit(3'd0, 27'h0BB456, 2'd0, 32'hABCD9999, 7); // Way 7, Word0
    perform_read_hit(3'd0, 27'h0BCDEF, 2'd3, 32'h12345678, 1); // Way 1, Word3
    perform_read_hit(3'd0, 27'h0ABCDE, 2'd2, 32'hCCCC1111, 0); // Way 0, Word2
    perform_read_hit(3'd0, 27'h0CDEF0, 2'd1, 32'hDEADDEAD, 2); // Way 2, Word1
    perform_read_hit(3'd0, 27'h0EE001, 2'd2, 32'hBBBB1111, 4); // Way 4, Word1
    perform_read_hit(3'd0, 27'h0AA123, 2'd3, 32'hABCDEF01, 6); // Way 6, Word3

    $display("-----------------------------------------------------");
    $display("READ HIT CASES COMPLETED");
    $display("READ MISS CLEAN TEST STARTED");

    // =========================
    // READ MISS CLEAN TEST
    // =========================
    perform_read_miss_clean(
        3'd0,                                // index (set = 1 → matches preloaded set)
        27'h11AA35,                          // new tag (≠ 11AA33, so miss occurs)
        2'd0,                                // blk_offset = 0 (word 0 of the block)
        128'hCAFEBABE_FEEDFACE_DEADBEAF_87654321, // refill block from memory
        32'h87654321                         // expected word after refill (word0)
    );

    $display("READ MISS CLEAN TEST COMPLETED");


    // =========================
    // READ MISS DIRTY BLOCK TEST
    // =========================
    perform_read_miss_dirty(
        3'd0,                                // index (set = 1 again)
        27'h22BB47,                          // new tag to cause miss (≠ 22BB44, so miss occurs)
        2'd0,                                // offset = 0
        128'hFEEDFACE_DEADBEAF_CAFEBABE_12345678, // new block to be refilled
        32'h12345678                         // expected word after refill
    );

    $display("READ MISS DIRTY BLOCK TEST COMPLETED");


  // COMPULSORY MISS TESTS FOR SET 1

       $display("===============================================");
    $display(" READ HIT CASES (8-way, Set=1)");
    $display("===============================================");

    // Way 3, expect word0 = 32'hDDDD4444
       $display("===============================================");
    $display(" READ HIT CASES (8-way, Set=1)");
    $display("===============================================");

    // Way 3, expect word0 = 32'hDDDD4444
    perform_read_hit( 3'd1,27'h11AA33,2'd0,32'hDDDD4444,3 );

    // Way 5, expect word3 = 32'h55556666
    perform_read_hit( 3'd1,27'h22BB44,2'd3, 32'h55556666,5);

    // Way 7, expect word0 = 32'h12345678
    perform_read_hit(
        3'd1,27'h33CC55,2'd0,32'h12345678, 7 );

    // Way 1, expect word2 = 32'hBEEF9ABC
    perform_read_hit(
        3'd1,27'h44DD66,2'd1,32'hBEEF9ABC,1);

    $display("-----------------------------------------------------");
    $display(" READ MISS CLEAN CASE (Set=1, New Tag)");
    $display("-----------------------------------------------------");

   perform_read_miss_clean(
        3'd1,                                // index = Set 1
        27'h55EE77,                          // new tag (ensures miss)
        2'd0,                                // blk_offset = word0
        128'hCAFEBABE_FEEDFACE_DEADBEAF_87654321, // refill block
        32'h87654321                         // expected word0 after refill
    );

    $finish;
  end

endmodule

