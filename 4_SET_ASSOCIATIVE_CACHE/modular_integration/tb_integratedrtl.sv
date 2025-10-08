// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
//Description : this file contains test code for integrated RTL of all modules of 4 way set associative cache.
// Author:  Eman Nasar.
// Date: 5th, August, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE

`timescale 1ns/1ps
module tb_cache_top_4way;

  // Parameters
  localparam WORD_SIZE       = 32;
  localparam WORDS_PER_BLOCK = 4;
  localparam BLOCK_SIZE      = WORDS_PER_BLOCK * WORD_SIZE; // 128b
  localparam NUM_BLOCKS      = 64;
  localparam NUM_WAYS        = 4;
  localparam NUM_SETS        = NUM_BLOCKS / NUM_WAYS;
  localparam TAG_WIDTH       = 26;
  localparam INDEX_WIDTH     = 4;
  localparam OFFSET_WIDTH    = 2;

  // Clock/reset
  logic clk;
  logic rst;

  // CPU interface
  logic req_valid;
  logic req_type; // 0=read, 1=write
  logic [31:0] address;
  logic [31:0] data_in;
  logic [31:0] data_out;
  logic done_cache;

  // Memory side
  logic [127:0] data_out_mem;
  logic ready_mem;
  logic valid_mem;
  

  // DUT instantiation
  top dut (
    .clk(clk),
    .rst(rst),
    .req_valid(req_valid),
    .req_type(req_type),
    .address(address),
    .data_in(data_in),
    .data_out(data_out),
    
    .done_cache(done_cache),
    .data_out_mem(data_out_mem),
    .ready_mem(ready_mem),
    .valid_mem(valid_mem)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset + preload cache
  initial begin
    clk = 0;
    rst = 1;
    req_valid = 0;
    req_type = 0;
    data_in = 0;
    address = 0;
    data_out_mem = 0;
    ready_mem = 0;
    valid_mem = 0;
    #15;
    rst = 0;

    // ----------------- Preload cache line for hits -----------------
    // Put block at set index=2, way=0 with tag=0x1AAAA
    dut.cache.cache[0][0] = {
        128'hDEADBEEF_55667788_11223344_AABBCCDD,
        26'h1ABCDE,
        1'b1,
        1'b1
    };
    dut.cache.cache[0][1] = {
        128'hDAADBEEF_65667788_31223344_BABBCDDD,
        26'h1CBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[0][2] = {
        128'hDAADBEEF_65667788_31223344_BABBCDDD,
        26'h1BBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[0][3] = {
        128'hDAADBEEF_65667788_41223344_BABBCDDD,
        26'h1DBBDE,
        1'b0,
        1'b1
    };

    dut.cache.cache[4'd2][0] = {
        128'h11112222_33334444_55556666_77778888, // block data
        26'h1AAAA,                               // TAG
        1'b0,                                    // dirty=0
        1'b1                                     // valid=1
    };

    // preload some other lines
    dut.cache.cache[1][0] = {
        128'hDEFDBEEF_55667788_11223344_AABBCCDD,
        26'h1ABCDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[1][1] = {
        128'hDAADBEEF_65667788_31223344_BABBCDDD,
        26'h1CBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[1][2] = {
        128'hDAADBEEF_65667788_31223344_BABBCDDD,
        26'h1BBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[1][3] = {
        128'hDAADBEEF_65667788_41223344_BABBCDDD,
        26'h1DBBDE,
        1'b0,
        1'b1
    };
dut.cache.cache[3][0] = {
        128'hDDDDBEEF_55667788_17293344_AABBCCDD,
        26'h1ABCDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[3][1] = {
        128'hDAADBEEF_65667788_39223384_BABBCDDD,
        26'h1CBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[3][2] = {
        128'hDAADBEEF_65667788_81224344_BABBCDDD,
        26'h1BBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[3][3] = {
        128'hDAADBEEF_65667788_91223344_BABBCDDD,
        26'h1DBBDE,
        1'b0,
        1'b1
    };
dut.cache.cache[6][0] = {
        128'hDEADBEEF_55667788_11223344_AABBCCDD,
        26'h1ABCDE,
        1'b1,
        1'b1
    };
    dut.cache.cache[6][1] = {
        128'hDAADBEEF_65667788_31223344_BABBCDDD,
        26'h1CBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[6][2] = {
        128'hDAADBEEF_65667788_31223344_BABBCDDD,
        26'h1BBBDE,
        1'b0,
        1'b1
    };
    dut.cache.cache[6][3] = {
        128'hDAADBEEF_65667788_41223344_BABBCDDD,
        26'h1DBBDE,
        1'b0,
        1'b1
    };

   
  
   

   // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST ON WAY 0 INDEX 0 ===");
    @(posedge clk);
    address  = {26'h1ABCDE, 4'h0, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
   
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST ON WAY 1 INDEX 0 ===");
    @(posedge clk);
    address  = {26'h1CBBDE, 4'h0, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
   
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST ON WAY 2 INDEX 0 ===");
    @(posedge clk);
    address  = {26'h1BBBDE, 4'h0, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
   
   
   
    $display("\n=== READ HIT TEST ON WAY 3 INDEX 0 ===");
    @(posedge clk);
    address  = {26'h1DBBDE, 4'h0, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
    $display("\n===========================================================");

    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST 1 ON WAY 0 INDEX 1 ===");
    @(posedge clk);
    address  = {26'h1ABCDE, 4'h1, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
    
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST 2 ON WAY 2 INDEX 1===");
    @(posedge clk);
    address  = {26'h1CBBDE, 4'h1, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
    
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST 3 ON WAY 3 INDEX 1===");
    @(posedge clk);
    address  = {26'h1BBBDE, 4'h1, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
    
    
   
    $display("\n=== READ HIT TEST 4 ON WAY 4 INDEX1===");
    @(posedge clk);
    address  = {26'h1DBBDE, 4'h1, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
    $display("\n===========================================================");
     // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST ON WAY 1 INDEX 3 ===");
    @(posedge clk);
    address  = {26'h1ABCDE, 4'h3, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
    
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST ON WAY 2 INDEX 3===");
    @(posedge clk);
    address  = {26'h1CBBDE, 4'h3, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
    
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST ON WAY 3 INDEX 3 ===");
    @(posedge clk);
    address  = {26'h1BBBDE, 4'h3, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
    
    
   
    $display("\n=== READ HIT TEST ON WAY 4 INDEX 4 ===");
    @(posedge clk);
    address  = {26'h1DBBDE, 4'h3, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
                       $display("\n===========================================================");

    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST on way 0  Index 6 ===");
    @(posedge clk);
    address  = {26'h1ABCDE, 4'h6, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
    
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST on way 1 Index 6 ===");
    @(posedge clk);
    address  = {26'h1CBBDE, 4'h6, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
     
    
    // ---------------- READ HIT ----------------
    $display("\n=== READ HIT TEST on way 2 Index 6 ===");
    @(posedge clk);
    address  = {26'h1BBBDE, 4'h6, 2'b01};
    req_type = 0; // read
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ HIT: data_out=%h, done_cache=%b", data_out, done_cache);
    
    
    
    $display("\n===========================================================");
    @(posedge clk);
    $display("\n=== WRITE HIT TEST ON INDEX 2 ===");
    @(posedge clk);
    address  = {26'h1AAAA, 4'd2, 2'b10}; // word2 in block
    data_in  = 32'hCAFEBABE;
    req_type = 1; // write
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("WRITE HIT: updated block[2] with %h", data_in);

    // ---------------- READ BACK to confirm write ----------------
    $display("\n=== READ BACK after WRITE ===");
    @(posedge clk);
    address  = {26'h1AAAA, 4'd2, 2'b10}; // same word
    req_type = 0;
    req_valid= 1;
    @(posedge clk);
    req_valid= 0;

    repeat(2) @(posedge clk);
    $display("READ AFTER WRITE: data_out=%h (should be CAFEBABE)", data_out);
    
    $display("\n===========================================================");
    $display("\n=== READ MISS CLEAN  INDEX 4 ===");
      
    @(posedge clk);
    address = {26'h1FBCEE, 4'h3, 2'h3}; 
      req_type = 0;
      req_valid=1; 
      rst=0;
       @(posedge clk);
      valid_mem=1;
      ready_mem=1;
      req_valid=0;
      data_out_mem=128'hFAAABEEF_55667788_11223344_AABBCCDD;
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
     
      $display("Dirty bit: %b", dut.cache.info3.dirty);
      $display("Valid bit: %b", dut.cache.info3.valid);
      $display("Next:",dut.controller.next_state);
     $display("BEFORE WRITE cache line: %h", 
              dut.cache.cache[3][0][155:28]);
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
    $display("ready_cache: %0b", dut.controller.ready_cache);
    @(posedge clk);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
 
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
        $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[3][0][155:28]);
    $display("PLRU: %b", dut.cache.plru[3].b1);
    $display("PLRU: %b", dut.cache.plru[3].b2);
    $display("PLRU: %b", dut.cache.plru[3].b3);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
     $display("\n===========================================================");

      $display("\n=== READ MISS DIRTY ON INDEX 0  ===");
    @(posedge clk);
    address = {26'h1FBCEE, 4'h0, 2'h3};
      req_type = 0;
      req_valid=1;
      rst=0;
       @(posedge clk);
      valid_mem=1;
      ready_mem=1;
      req_valid=0;
      data_out_mem=128'hFAAABEEF_55667788_11223344_AABBCCDD;
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
     
      $display("Dirty bit: %b", dut.cache.info0.dirty);
    $display("Valid bit: %b", dut.cache.info0.valid);
      $display("Next:",dut.controller.next_state);
     $display("BEFORE WRITE cache line: %h",
              dut.cache.cache[0][0][155:28]);
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
    $display("ready_cache: %0b", dut.controller.ready_cache);
    ready_mem=1;
    @(posedge clk);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
      ready_mem=1;
    $display("Valid_cache : %b",dut.controller.valid_cache);
      $display("ready_mem: %b",dut.controller.ready_mem);
      $display("Write_en_mem %b: ",dut.cache.write_en_mem);
      $display("read_en_cache : %b",dut.cache.read_en_cache);
      $display("Dirty block out : %h",dut.cache.dirty_block_out);
   
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
        $display("[%0t] AFTER WRITE cache line: %h",
                  $time,
                 dut.cache.cache[0][0][155:28]);
    $display("PLRU: %b", dut.cache.plru[0].b1);
    $display("PLRU: %b", dut.cache.plru[0].b2);
    $display("PLRU: %b", dut.cache.plru[0].b3);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
     
      valid_mem=1;              
      req_valid=0;
     
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
     
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("\n===========================================================");
     // ---------------- -------------------------------------- ----------------
    
    $display("\n=== WRITE MISS CLEAN TEST ON  INDEX 1 ===");
    @(posedge clk);  
    @(posedge clk);
    address = {26'h1FBCEE, 4'h1, 2'h3}; 
      req_type = 0;
      req_valid=1; 
      rst=0;
       @(posedge clk);
      valid_mem=1;
      ready_mem=1;
      req_valid=0;
      data_out_mem=128'hFFFBBEEF_55667788_11223344_AABBCCDD;
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
     
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
      $display("Next:",dut.controller.next_state);
     $display("BEFORE WRITE cache line: %h", 
              dut.cache.cache[1][0][155:28]);
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
    $display("ready_cache: %0b", dut.controller.ready_cache);
    @(posedge clk);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
 
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
        $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[1][0][155:28]);
    $display("PLRU: %b", dut.cache.plru[1].b1);
    $display("PLRU: %b", dut.cache.plru[1].b2);
    $display("PLRU: %b", dut.cache.plru[1].b3);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("\n===========================================================");
      $display("\n=== WRITE MISS DIRTY  Index 6 ===");
    @(posedge clk); 
    @(posedge clk);
    address = {26'h1FBCEE, 4'h6, 2'h3}; 
      req_type = 1;
      data_in=32'hABCDABCD;
      req_valid=1; 
      rst=0;
       @(posedge clk);
      valid_mem=1;
      ready_mem=1;
      req_valid=0;
      data_out_mem=128'hAAAABEEF_55667788_11223344_AABBCCDD;
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
     
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
      $display("Next:",dut.controller.next_state);
     $display("BEFORE WRITE cache line: %h", 
              dut.cache.cache[6][0][155:28]);
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
    $display("ready_cache: %0b", dut.controller.ready_cache);
    ready_mem=1;
    @(posedge clk);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
      ready_mem=1;
    $display("Valid_cache : %b",dut.controller.valid_cache);
      $display("ready_mem: %b",dut.controller.ready_mem);
      $display("Write_en_mem %b: ",dut.cache.write_en_mem);
      $display("read_en_cache : %b",dut.cache.read_en_cache);
      $display("Dirty block out : %h",dut.cache.dirty_block_out);
   
       @(posedge clk);
    $display("Current:",dut.controller.current_state);
    $display("Next:",dut.controller.next_state);
        $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[6][0][155:28]);
    $display("PLRU: %b", dut.cache.plru[6].b1);
    $display("PLRU: %b", dut.cache.plru[6].b2);
    $display("PLRU: %b", dut.cache.plru[6].b3);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
               dut.cache.cache[6][0][155:28]);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
     
      valid_mem=1;              
      req_valid=0;
      
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Refill: %h", dut.controller.refill);
      $display("Read_en_cache: %b", dut.controller.read_en_cache);
     $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
              dut.cache.cache[6][0][155:28]);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("----------------------------END-------------------------");
   $finish;
  
  end
endmodule
