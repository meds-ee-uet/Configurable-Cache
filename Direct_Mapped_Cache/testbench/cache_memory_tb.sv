// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//Description : this file contains test bench for the  RTL of cache memory module of direct mapped cache.
// Author:  Ammarah Wakeel.
// Date: 28th, june, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE
`timescale 1ns/1ps

`include "cache_params.svh"  // Include the parameter definitions

module cache_tb;

    // === Inputs ===
    logic clk;
    logic [TAG_WIDTH-1:0] tag;
    logic [INDEX_WIDTH-1:0] index;
    logic [OFFSET_WIDTH-1:0] blk_offset;
    logic req_type;
    logic read_en_cache;
    logic write_en_cache;
    logic refill;
    logic [BLOCK_SIZE-1:0] data_in_mem;
    logic [WORD_SIZE-1:0] data_in;

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
        .refill(refill),
        .data_in_mem(data_in_mem),
        .data_in(data_in),
        .dirty_block_out(dirty_block_out),
        .hit(hit),
        .data_out(data_out),
        .dirty_bit(dirty_bit),
        .done_cache(done_cache)
    );

    // === Clock Generation ===
    always #5 clk = ~clk;

    // === Initialize Cache (Optional Preloaded Entries) ===
    initial begin
        // Example preload (can be extended for tests)
        uut.cache[0] = 154'b0001001000110100010101100111100011011110101011011011111011101111110010101111111010111010101111100000101110101101111100000000110110101011110011011110000001;
        uut.cache[1] = 154'b0100010001000100010001000100010000110011001100110011001100110011001000100010001000100010001000100001000100010001000100010001000100000000000010101011110001;
        uut.cache[2] = 154'b0010101011110011011110111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001101;
        uut.cache[3] = 154'b110101110111000110101010111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001101000011110011;
        uut.cache[4] = 154'b101011000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001111000011110000111100001110101100101;
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
        refill = 0;
        data_in_mem = '0;
        data_in = '0;

         // READ HIT
        @(posedge clk);
        tag = 24'b101010111100110111100000;
        index = 6'd0;
        blk_offset = 2'b11;
        req_type = 0;
        read_en_cache = 1;       
        @(posedge clk);
        read_en_cache = 0;
        #10;
        $display("-----------------------------------------------------");
        $display("=== READ HIT TEST ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("DATA_OUT: %h", data_out);
        $display("DIRTY_BIT: %0b\n", dirty_bit);
        $display("-----------------------------------------------------");
        //---------- Write Hit ----------
        @(posedge clk);
        tag = 24'b000000000000101010111100;
        index = 6'b000001;
        blk_offset = 2'b11;
        req_type = 1;
        write_en_cache = 1;
        data_in = 32'b11001010111111101011101010111110;
        @(posedge clk);
        write_en_cache = 0;
        #1;
        $display("-----------------------------------------------------");
        $display("=== WRITE HIT TEST ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("Cache Line Dirty Bit: %0b", dirty_bit);
        $display("Cache DataIn: %0b", data_in);
        $display("Cache Line at index %0d:\n%154b", index, uut.cache[index]); 
        $display("-----------------------------------------------------");
        // ---------- Read Miss withyout Dirt Block ----------
        
        @(posedge clk);      
        tag = 24'b000110100010101100111100;
        index = 6'b000010;
        blk_offset = 2'd0;
        req_type = 0;
        read_en_cache = 1;
        @(posedge clk);
        read_en_cache = 0;

// Display hit status BEFORE refill or write
      $display("-----------------------------------------------------");
        $display("=== READ MISS (with clean block PRE-REFILL CHECK ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index %0d:\n%154b", index, uut.cache[index]);
     

// Now trigger refill and write (simulate cache load from memory)
        refill = 1;
        write_en_cache = 1;
        data_in_mem = 128'b11001010111111101011101010111110111100001111000010101010101010100001110001111000111100001111000011110000111100001111000011110000;

        @(posedge clk);
        refill = 0;
        write_en_cache = 0;
        @(posedge clk);
      $display("=== READ MISS (with clean block POST-REFILL CHECK ===");
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index   %0d after modification :\n%154b", index, uut.cache[index]);
        $display("-----------------------------------------------------");
        // ---------- Read Miss with Dirty Block ----------
        @(posedge clk);
        tag = 24'b001111000011110000111100;
        index = 6'b000011;
        blk_offset = 2'b00;
        req_type = 0;
        read_en_cache = 1;

        @(posedge clk);
        read_en_cache = 0;
        @(posedge clk);
        $display("-----------------------------------------------------");
        $display("=== Dirty block to be evicted and related info ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %1b", hit);
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index %0d:\n%154b", index, uut.cache[index]);
      
        $display("Dirty Block Out: %128b", dirty_block_out);
        $display("-----------------------------------------------------");
       // ---------- Write Miss without Dirty Block ----------
        @(posedge clk);
        tag = 24'b000110100010101100111100;
        index = 6'b000100;
        blk_offset = 2'd0;
        req_type = 1;
        data_in = 32'b11001010111111101011101010111110;
        write_en_cache = 1;
        @(posedge clk);
        write_en_cache = 0;
        $display("-----------------------------------------------------");
// Display hit status BEFORE refill or write
      $display("=== WRITE MISS (WITH CLEAN BLOCK) PRE-REFILL CHECK ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index %0d:\n%154b", index, uut.cache[index]);    
// Now trigger refill and write (simulate cache load from memory)
        refill = 1;
        write_en_cache = 1;
        data_in_mem = 128'b11001010111111101011101010111110111100001111000010101010101010100001110001111000111100001111000011110000111100001111000011111111;
        @(posedge clk);
        refill = 0;
        write_en_cache = 0;
        @(posedge clk);
        $display("=== WRITE MISS (WITH CLEAN BLOCK) POST-REFILL CHECK ===");
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index after modification  %0d:\n%154b", index, uut.cache[index]);
        $display("-----------------------------------------------------");
         //---------- Verifying Write Hit in case of write miss after allocating block  ----------
        @(posedge clk);
        tag = 24'b000110100010101100111100;
        index = 6'b000100;
        blk_offset = 2'b11;
        req_type = 1;
        write_en_cache = 1;
        data_in = 32'b01001010111111101011101010111110; 
        @(posedge clk);
        write_en_cache = 0;
        #1;
        $display("-----------------------------------------------------");
        $display("=== WRITE HIT TEST (FOR verifying Write Hit in case of write miss after allocating block  ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);       
        $display("Cache Line Dirty Bit: %0b", dirty_bit);
        $display("WRITE DATA: %32b", data_in);
        $display("Cache Line at index %0d:\n%154b", index, uut.cache[index]);
        $display("-----------------------------------------------------");
      // ---------- Read (compulsory) Miss without Dirty Block ----------
        @(posedge clk);
       // Set up address and request type
        tag = 24'b000110100010101100111100;
        index = 6'b000111;
        blk_offset = 2'd0;
        req_type = 0;
        read_en_cache = 1;

// Wait one cycle to evaluate hit *before* modifying anything
        @(posedge clk);
        read_en_cache = 0;

// Display hit status BEFORE refill or write
        $display("-----------------------------------------------------");
        $display("=== READ MISS PRE-REFILL CHECK ===");
        $display("Time: %0t ns", $time);
        $display("Tag: %h, Index: %d, Offset: %d", tag, index, blk_offset);
        $display("HIT: %0b", hit);
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index %0d:\n%154b", index, uut.cache[index]);
     

// Now trigger refill and write (simulate cache load from memory)
        refill = 1;
        write_en_cache = 1;
        data_in_mem = 128'b11001010111111101011101010111110111100001111000010101010101010100001110001111000111100001111000011110000111100001111000011110000;

        @(posedge clk);
        refill = 0;
        write_en_cache = 0;
        @(posedge clk);
      $display("=== READ MISS POST-REFILL CHECK ===");
        $display("DIRTY_BIT: %0b", dirty_bit);
        $display("Cache Line at index after modification  %0d:\n%154b", index, uut.cache[index]);
        $display("-----------------------------------------------------");
        $finish;
    end
endmodule

