// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the test code of  cache memory module.
//
// Author: Ayesha Anwar.
// Date: 20th, july, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE

`timescale 1ns/1ps

  // Include the parameter definitions

module cache_tb;
    parameter int WORD_SIZE         = 32; // bits per word
    parameter int WORDS_PER_BLOCK   = 4;  // words per block
    parameter int BLOCK_SIZE        = WORDS_PER_BLOCK * WORD_SIZE;
    parameter int NUM_BLOCKS        = 64; // total blocks
    parameter int NUM_WAYS          = 2;
    parameter int NUM_SETS          = NUM_BLOCKS / NUM_WAYS; // 32 sets
    parameter int CACHE_SIZE        = NUM_BLOCKS * BLOCK_SIZE / 8; // in bytes
    parameter int TAG_WIDTH         = 25;
    parameter int INDEX_WIDTH       = $clog2(NUM_SETS); // indexing by set
    parameter int OFFSET_WIDTH      = $clog2(WORDS_PER_BLOCK);
    // === Inputs ===
    logic clk;
    logic [TAG_WIDTH-1:0] tag;
    logic [INDEX_WIDTH-1:0] index;
    logic [OFFSET_WIDTH-1:0] blk_offset;
    logic req_type;
    logic read_en_cache;
    logic write_en_cache;
    logic [BLOCK_SIZE-1:0] data_in_mem;
    logic [WORD_SIZE-1:0] data_in;
    logic plru [NUM_SETS-1:0];

    // === Outputs ===
    logic [BLOCK_SIZE-1:0] dirty_block_out;
    logic hit;
    logic [WORD_SIZE-1:0] data_out;
    logic dirty_bit;
    logic done_cache;

    // === DUT Instantiation ===
    cache_memory #(
        .WORD_SIZE(WORD_SIZE),
        .WORDS_PER_BLOCK(WORDS_PER_BLOCK),
        .BLOCK_SIZE(BLOCK_SIZE),
        .NUM_BLOCKS(NUM_BLOCKS),
        .TAG_WIDTH(TAG_WIDTH),
        .INDEX_WIDTH(INDEX_WIDTH),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) uut (
        .clk(clk),
        .tag(tag),
        .index(index),
        .blk_offset(blk_offset),
        .req_type(req_type),
        .read_en_cache(read_en_cache),
        .write_en_cache(write_en_cache),
        .data_in_mem(data_in_mem),
        .data_in(data_in),
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out(data_out),
        .dirty_bit(dirty_bit)
       
        
    );

    // === Clock Generation ===
    always #5 clk = ~clk;
    initial begin
      uut.cache[0][0] = {
        128'hDEADBEEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
        25'h1ABCDE,  // TAG
        1'b0,        // Dirty bit
        1'b1         // Valid bit
    };

      uut.cache[0][1] = {
        128'hDEADBEEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
        25'h1ABBDE,  // TAG
        1'b0,        // Dirty bit
        1'b1         // Valid bit
    };
      uut.cache[1][0] = {
        128'hABCDEFEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
        25'h1CBBDE,  // TAG
        1'b0,        // Dirty bit
        1'b1         // Valid bit
    };
      uut.cache[1][1] = {
        128'hFACEB00C_DEADC0DE_C0FFEE11_12345678,  // 4 words (block data)
        25'h0D00D1,  // TAG
        1'b0,        // Dirty bit
        1'b0         // Valid bit
    };
     uut.cache[2][0] = {
       128'hCAFEBABE_FEEDFACE_DEADBEAF_87654321,
       25'h1BAD5,
       1'b0, // dirty
       1'b1  // valid
   };
    uut.cache[2][1] = {
       128'h11112222_33334444_55556666_77778888,
       25'h0C0FF,
       1'b0,
       1'b1
   };
      uut.cache[3][0] = {
    128'hDEAD_BEEF_CAFE_FACE_FEED_FACE_BAAD_F00D, // block data
    25'h3DEAD,  // tag
    1'b1,       // dirty
    1'b1        // valid
   };

// Insert clean valid block in way 1 so PLRU can work
      uut.cache[3][1] = {
    128'h11112222_33334444_55556666_77778888, // block data
    25'hC0FF3,  // tag
    1'b0,       // dirty
    1'b1        // valid
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
        data_in_mem = '0;
        data_in = '0;

         // READ HIT
       @(posedge clk);
       tag = 25'h1ABCDE;
       index = 5'h0;
       blk_offset = 2'h3;
       req_type = 0;  

       @(posedge clk);
       $display("-----------------------------------------------------");
        $display("=== READ HIT TEST (way 0)===");
        $display("Time: %0t ns", $time);
        $display("Stored tag way0: %h", uut.cache[0][0][26:2]);    
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("DATA_OUT: %h", data_out);
        $display("-----------------------------------------------------");
       @(posedge clk);
       tag = 25'h1ABBDE;
       index = 5'h0;
       blk_offset = 2'h2;
       req_type = 0;  

       @(posedge clk);@(posedge clk);
       $display("-----------------------------------------------------");
      $display("=== READ HIT TEST (way 1)===");
      $display("Time: %0t ns", $time);
      $display("Stored tag way0: %h", uut.cache[0][1][26:2]);    
      $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("DATA_OUT: %h", data_out);
        $display("-----------------------------------------------------");
       
       // === WRITE HIT TEST ===
      @(posedge clk);

      // Setup inputs
      tag        = 25'h1CBBDE;
      index      = 5'h1;
      blk_offset = 2'h3;
      req_type   = 1;                     // Write request
      data_in    = 32'hACF0359E;

// Show cache line before write
      $display("-----------------------------------------------------");
      $display("=== WRITE HIT TEST (way 0) BEFORE WRITE ===");
      $display("Time: %0t ns", $time);
      $display("Stored tag way0: %h", uut.cache[1][0][26:2]);
      $display("Dirty bit way0: %0b", uut.cache[1][0][1]);
      $display("Block way0 before: %h", uut.cache[1][0][154:27]);
      $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
      $display("-----------------------------------------------------");

// Perform the write
      @(posedge clk);
      @(posedge clk)
// Show cache line after write
      $display("=== AFTER WRITE ===");    
      $display("Block way0 after : %h", uut.cache[1][0][154:27]); 
      $display("Dirty bit way0: %0b", uut.cache[index][0][1]);
      $display("-----------------------------------------------------");
      
       
      @(posedge clk);
      tag        = 25'h1CFDDE;
      index      = 5'h1;
      blk_offset = 2'h3;
      req_type   = 0;                     // Write request
                      // Enable write
      data_in_mem    = 128'hCAFEB00C_DEADC0DE_C0FFEE11_12345767;
      #1;
// Show cache line before write
      $display("-----------------------------------------------------");
      $display("=== READ MISS TEST (CLEAN BLOCK) BEFORE ALLOCATING ===");
      $display("Time: %0t ns", $time);
      $display("HIT: %0b", hit);
      $display("Valid bit: %h", uut.cache[index][1][0]);
      $display("Stored tag way0: %h", uut.cache[index][1][26:2]);
      $display("Dirty bit way0: %0b", uut.cache[index][1][1]);
      $display("Block way0 before: %h", uut.cache[index][1][154:27]);
      $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
      $display("-----------------------------------------------------");      
      @(posedge clk);
      @(posedge clk);    
// Show cache line after allocating
      $display("=== AFTER ALLOCATING ===");    
      $display("Block way0 after : %h", uut.cache[index][1][154:27]); 
      $display("Dirty bit way0: %0b", uut.cache[index][1][1]);
      $display("-----------------------------------------------------");
     
      // ======= DIRTY BLOCK EVICTION TEST =======

@(posedge clk);
tag        = 25'hC0FF3;
index      = 5'd3;
blk_offset = 2'd0;
req_type   = 0; // read
#1;
@(posedge clk);

// STEP 3: Trigger a read miss with a new tag (causes eviction of dirty way 0)
@(posedge clk);
tag        = 25'hBEEF1; // new tag, no match → read miss
index      = 5'd3;
blk_offset = 2'd0;
req_type   = 0; // read
#1;
@(posedge clk);
@(posedge clk);

// STEP 4: Display dirty_block_out
$display("-----------------------------------------------------");
$display("=== DIRTY BLOCK EVICTION TEST ===");
$display("Time: %0t ns", $time);
$display("Evicted dirty block data (dirty_block_out): %h", dirty_block_out);
$display("-----------------------------------------------------");
      // READ MISS (CONFLICT MISS)
@(posedge clk);
tag        = 25'h1BAD5;
index      = 5'd2;
blk_offset = 2'd0;
req_type   = 0; // read
#1;
@(posedge clk);
@(posedge clk);
tag        = 25'h0C0FE; // new tag, no match → read miss
index      = 5'd2;
blk_offset = 2'd0;
req_type   = 0; // read
data_in_mem=128'hBACDEFEF_55667788_11223344_AABBCCDD;
      #1;
// Show cache line before write
      $display("-----------------------------------------------------");
      $display("=== READ MISS TEST (CLEAN BLOCK)(IN CASE OF CONFLICT MISS)(BEFORE ALLOCATING ===");
      $display("Time: %0t ns", $time);
      $display("HIT: %0b", hit);
      $display("Valid bit: %h", uut.cache[index][1][0]);
      $display("Stored tag way0: %h", uut.cache[index][1][26:2]);
      $display("Dirty bit way0: %0b", uut.cache[index][1][1]);
      $display("Block way0 before: %h", uut.cache[index][1][154:27]);
      $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
      $display("-----------------------------------------------------");      
      @(posedge clk);
      @(posedge clk);    
// Show cache line after allocating
      $display("=== AFTER ALLOCATING ===");    
      $display("Block after : %h", uut.cache[index][1][154:27]); 
      $display("Dirty bit : %0b", uut.cache[index][1][1]);
      $display("-----------------------------------------------------");
     

     $finish;
      
    end

endmodule
