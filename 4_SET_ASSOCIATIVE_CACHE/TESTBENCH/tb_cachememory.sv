// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
// Description : This file contains the test bench for the modular testing of 4 way set associative cache memory.
// Author:  Eman Nasarrr.
// Date: 10th, August, 2025.
// `timescale 1ns/1ps

module tb_cache_memory_read_hit;

  // === Parameters ===
  localparam WORD_SIZE       = 32;
  localparam WORDS_PER_BLOCK = 4;
  localparam BLOCK_SIZE      = WORD_SIZE * WORDS_PER_BLOCK;
  localparam NUM_BLOCKS      = 64;
  localparam NUM_WAYS        = 4;
  localparam TAG_WIDTH       = 25;
  localparam INDEX_WIDTH     = $clog2(NUM_BLOCKS / NUM_WAYS);
  localparam OFFSET_WIDTH    = $clog2(WORDS_PER_BLOCK);

  // === DUT Signals ===
  logic clk;
  logic [TAG_WIDTH-1:0] tag;
  logic [INDEX_WIDTH-1:0] index;
  logic [OFFSET_WIDTH-1:0] blk_offset;
  logic req_type;                
  logic read_en_cache;
  logic write_en_cache;
  logic read_en_mem;
  logic write_en_mem;
  logic [BLOCK_SIZE-1:0] data_in_mem;
  logic [WORD_SIZE-1:0] data_in;
  logic [BLOCK_SIZE-1:0] dirty_block_out;
  logic hit;
  logic [WORD_SIZE-1:0] data_out;
  logic dirty_bit;

  // === Instantiate DUT ===
  cache_memory uut (
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

  // === Clock Generation ===
  always #5 clk = ~clk;

  // === Preload Cache Lines ===
  initial begin
    // preload set 0, way 0
    uut.cache[0][0] = {
      128'hDEADBEEF_55667788_11223344_AABBCCDD,  
      25'h1ABCDE,  
      1'b0,        // dirty bit
      1'b1         // valid bit
    };

    // preload set 0, way 1
    uut.cache[0][1] = {
      128'hDEADBEEF_55667788_11223344_AABBCCDD,  
      25'h1ABBDE,  
      1'b0,        // dirty bit
      1'b1         // valid bit
    };
    // preload a clean block into set3, way0
    uut.cache[3][0] = {
      128'hDEADBEEF_11223344_55667788_99AABBCC,  // block data
      25'h0C0FF,   // tag
      1'b0,        // dirty = 0 (clean)
      1'b1         // valid = 1
    };
    uut.cache[2][0] = {
        128'hAAAAAAAA_BBBBBBBB_CCCCCCCC_DDDDDDDD, // garbage data
        25'hABCDE,   // garbage tag
        1'b0,        // dirty = 0
        1'b0         // valid = 0 (forces compulsory miss)
    };
  end

  // === Test Procedure ===
  initial begin
    // Initialize all inputs
    clk = 0;
    tag = '0;
    index = '0;
    blk_offset = '0;
    req_type = 0;
    read_en_cache = 0;
    write_en_cache = 0;
    read_en_mem = 0;
    write_en_mem = 0;
    data_in_mem = '0;
    data_in = '0;

    // =====================================================
    // 1) READ HIT on way 0
    // =====================================================
    @(posedge clk);
    tag = 25'h1ABCDE;
    index = 0;
    blk_offset = 3;  // word 3 of the block
    req_type = 0;  
    read_en_cache = 1;

    $display("PLRU before (set %0d): b1=%0b b2=%0b b3=%0b", 
              index, uut.plru[index].b1, uut.plru[index].b2, uut.plru[index].b3);

    @(posedge clk);  // wait for data_out
    $display("-----------------------------------------------------");
    $display("=== READ HIT TEST (way 0)===");
    $display("Time: %0t ns", $time);
    $display("Stored tag way0: %h", uut.cache[0][0][TAG_WIDTH+1:2]);    
    $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
    $display("HIT: %0b", hit);
    $display("DATA_OUT: %h", data_out);
    @(posedge clk);  // extra cycle for PLRU update
    $display("PLRU after (set 0): b1=%b b2=%b b3=%b",
              uut.plru[0].b1, uut.plru[0].b2, uut.plru[0].b3);
    $display("-----------------------------------------------------");

    // =====================================================
    // 2) READ HIT on way 1
    // =====================================================
    @(posedge clk);
    tag = 25'h1ABBDE;
    index = 0;
    blk_offset = 2;  
    req_type = 0;  
    read_en_cache = 1;

    $display("PLRU before (set %0d): b1=%0b b2=%0b b3=%0b", 
              index, uut.plru[index].b1, uut.plru[index].b2, uut.plru[index].b3);

    @(posedge clk);  // wait for data_out
    $display("-----------------------------------------------------");
    $display("=== READ HIT TEST (way 1)===");
    $display("Time: %0t ns", $time);
    $display("Stored tag way1: %h", uut.cache[0][1][TAG_WIDTH+1:2]);    
    $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
    $display("HIT: %0b", hit);
    $display("DATA_OUT: %h", data_out);
    @(posedge clk);  // extra cycle for PLRU update
    $display("PLRU after (set 0): b1=%b b2=%b b3=%b",
              uut.plru[0].b1, uut.plru[0].b2, uut.plru[0].b3);
    $display("-----------------------------------------------------");

    // =====================================================
    // 3) WRITE HIT TEST (way 0)
    // =====================================================
    @(posedge clk);
    tag        = 25'h1ABCDE;   // tag of way0 we preloaded
    index      = 0;
    blk_offset = 2;            // write to word 2
    req_type   = 1;            // Write request
    data_in    = 32'hACF0359E; // new data
    write_en_cache = 1;

    // Show cache line before write
    $display("-----------------------------------------------------");
    $display("=== WRITE HIT TEST (way 0) BEFORE WRITE ===");
    $display("Time: %0t ns", $time);
    $display("Stored tag way0: %h", uut.cache[index][0][TAG_WIDTH+1:2]);
    $display("Dirty bit way0: %0b", uut.cache[index][0][1]);
    $display("Block way0 before: %h", uut.cache[index][0][BLOCK_SIZE+TAG_WIDTH+2-1:TAG_WIDTH+2]);
    $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
    $display("PLRU before (set %0d): b1=%0b b2=%0b b3=%0b",
              index, uut.plru[index].b1, uut.plru[index].b2, uut.plru[index].b3);
    $display("-----------------------------------------------------");

    // Perform the write
    @(posedge clk);
    @(posedge clk);

    // Show cache line after write
    $display("=== AFTER WRITE ===");    
    $display("Block way0 after : %h", uut.cache[index][0][BLOCK_SIZE+TAG_WIDTH+2-1:TAG_WIDTH+2]);
    $display("Dirty bit way0: %0b", uut.cache[index][0][1]);
    $display("PLRU after (set %0d): b1=%0b b2=%0b b3=%0b",
              index, uut.plru[index].b1, uut.plru[index].b2, uut.plru[index].b3);
    $display("-----------------------------------------------------");

    write_en_cache = 0;
    // ======= READ MISS WITH CLEAN (NON-DIRTY) VICTIM =======
// STEP 1: Show preloaded block
    @(posedge clk);
    $display("-----------------------------------------------------");
    $display("Preloaded block in Set 3, Way 0:");
    $display("Tag: %h", uut.cache[3][0][TAG_WIDTH+1:2]);
    $display("Valid: %b, Dirty: %b",
             uut.cache[3][0][0], uut.cache[3][0][1]);
    $display("Block Data: %h",
             uut.cache[3][0][BLOCK_SIZE+TAG_WIDTH+1 : TAG_WIDTH+2]);
    $display("-----------------------------------------------------");

    // STEP 2: Trigger a read miss with new tag → conflict miss
    @(posedge clk);
    tag        = 25'h0BEEF;     // new tag, conflict miss
    index      = 5'd3;
    blk_offset = 2'd1;
    req_type   = 0;             // read
    read_en_mem    = 1;
    write_en_cache = 1;
    data_in_mem    = 128'h112233445566778899AABBCCDDEEFF00;
    #1;
    @(posedge clk);
    read_en_mem    = 0;
    write_en_cache = 0;

    // STEP 3: Display results
    $display("-----------------------------------------------------");
    $display("=== CONFLICT MISS TEST (Clean victim, No dirty writeback) ===");
    $display("Time: %0t ns", $time);
    $display("Evicted block dirty? expected clean → dirty_block_out = %h", dirty_block_out);
    @(posedge clk);
    $display("New block installed in Set3, Way0: %h",
             uut.cache[index][0][BLOCK_SIZE+TAG_WIDTH+1 : TAG_WIDTH+2]);
    $display("-----------------------------------------------------");
        // =====================================================
    // COMPULSORY MISS CASE
    // =====================================================
    @(posedge clk);
    $display("-----------------------------------------------------");
    $display("=== COMPULSORY MISS TEST ===");

    // Choose set 2, way 0, but make it invalid
    index      = 5'd2;
    tag        = 25'h0C0FF;   // some new tag
    blk_offset = 2'd0;
    req_type   = 0;           // read

   
 

    // Trigger compulsory miss
    read_en_mem    = 1;
    write_en_cache = 1;
    data_in_mem    = 128'hCAFEBABE_DEADBEEF_11223344_55667788;

    #1;
    @(posedge clk);
    read_en_mem    = 0;
    write_en_cache = 0;

    // Display results after compulsory miss refill
    $display("Compulsory miss at Set%0d, Way0", index);
    $display("Installed block: %h",
             uut.cache[index][0][BLOCK_SIZE+TAG_WIDTH+1 : TAG_WIDTH+2]);
    $display("Stored tag: %h", uut.cache[index][0][TAG_WIDTH+1:2]);
    $display("Valid bit: %b, Dirty bit: %b",
             uut.cache[index][0][0], uut.cache[index][0][1]);
    $display("-----------------------------------------------------");

    
    
    #20 $finish;
  end

endmodule
