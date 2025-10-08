// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the test code of integrated 2 way cache memory with other module.
//
// Author:  Ayesha Anwar.
// Date: 21st, july, 2025.
// CACHE CONTROLLER IS SAME AS DIRECT MAPPED CACHE, 2 WAY CACHE AND N WAY CACHE

`timescale 1ns/1ps
module tb_top;
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

    // Clock and reset
    logic clk;
    logic rst;

    // CPU request signals
    logic req_valid;
    logic req_type; // 0=read, 1=write
    logic [31:0] data_in;
    logic [31:0] address;
    logic [BLOCK_SIZE-1:0] data_out_mem;
    logic valid_mem;
    logic ready_mem;
  //Outputs from DUT
    logic [31:0] data_out;
    logic        done_cache;

    // Instantiate DUT
    top dut (
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .req_type(req_type),
        .data_in(data_in),
        .address(address),
        .data_out(data_out),
        .data_out_mem(data_out_mem),
        .valid_mem(valid_mem),
        .ready_mem(ready_mem),
        .done_cache(done_cache)
    );

    // Clock generation
    always #5 clk = ~clk;
    initial begin
        dut.cache.cache[0][0] = {
           128'hDEADBEEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
        25'h1ABCDE,  // TAG
        1'b0,        // Dirty bit
        1'b1         // Valid bit
    };
      dut.cache.cache[0][1] = {
    128'hDAADBEEF_65667788_21223344_BABBCDDD,
    25'h1CBBDE,
    1'b0,
    1'b1
    };
      dut.cache.cache[1][0] = {
           128'hAAADBEEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
        25'h1DBCDE,  // TAG
        1'b0,        // Dirty bit
        1'b1         // Valid bit
    };
      dut.cache.cache[1][1] = {
    128'hEAADBEEF_65667788_21223344_BABBCDDD,
    25'h1FBBDE,
    1'b0,
    1'b1
    };
      dut.cache.cache[2][0] = {
           128'hDDDDBEEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
        25'h1CBCDE,  // TAG
        1'b0,        // Dirty bit
        1'b1         // Valid bit
    };
      dut.cache.cache[2][1] = {
    128'hDEEEBEEF_65667788_21223344_BABBCDDD,
    25'h1ABBDE,
    1'b0,
    1'b1
    };       
       dut.cache.cache[3][0] = {
           128'hBEEFBEEF_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
           25'h1EECDE,  // TAG
           1'b0,        // Dirty bit
           1'b1         // Valid bit
    };
       dut.cache.cache[3][1] = {
          128'hDAADDAAD_65667788_21223344_BABBCDDD,
          25'h1FFBDE,
          1'b1,
          1'b1
    };       
       dut.cache.cache[4][0] = { 
          128'hDEADDEAD_55667788_11223344_AABBCCDD,  // 4 words of 4 bytes each
          25'h1CADDE,  // TAG
          1'b0,        // Dirty bit
          1'b1         // Valid bit
    };
       dut.cache.cache[4][1] = {
         128'hBAAFBEEF_65667788_21223344_BABBCDDD,
       25'h1DACDE,
       1'b1,
       1'b1
};       
    end
    initial begin
        // Init
        clk = 0;
        rst = 1;
        req_valid = 0;
        req_type = 0;
        data_in = 0;
        address = 0;
           // Release reset
       @(posedge clk);
       address = 32'hD5E6F03;
       req_type = 0;  
       req_valid=1;
       rst=0;
       @(posedge clk);
       @(posedge clk);       
       req_valid=0;
       
      $display("------------------------READ HIT TEST-----------------------------");
      $display("=== READ HIT TEST ===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
      
      $display("Ready_en_cache: %0b", dut.controller.read_en_cache);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      $display("----------------------------	END-------------------------");
       @(posedge clk);
       address = {25'h1CBBDE, 5'h0, 2'h3};
       data_in = 32'hBACDEFEF;
       req_type = 1;  
       req_valid=1;
       @(posedge clk);
       @(posedge clk);    
        req_valid=0;
       
      $display("--------------------------WRITE HIT TEST---------------------------");
      $display("=== WRITE HIT TEST===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);   
      $display("write_en_cache: %0b", dut.controller.write_en_cache);
      
       @(posedge clk);
      $display("CACHE LINE : %h", dut.cache.cache[0][1][154:27]);
      $display("Dirty bit: %0b",dut.cache.cache[0][1][1]);
      $display("-------------------------END----------------------------");

      // READ MISS TEST (CLEAN BLOCK)
      @(posedge clk);
      address = {25'h1DBCDE,5'h1,2'h3}; 
      req_type = 0;  
      req_valid=1;
      rst=0;
      
       @(posedge clk);
       @(posedge clk);       
       req_valid=0;
       
      $display("---------------------------READ MISS TEST (CLEAN BLOCK) --------------------------");
      $display("=== READ MISS TEST ===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
      
      $display("Ready_en_cache: %0b", dut.controller.read_en_cache);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      $display("-----------------------------------------------------");      
     
      @(posedge clk);
      address = {25'h1BBCEE, 5'h1, 2'h3}; 
      req_type = 0;
      req_valid=1; 
      rst=0;
       @(posedge clk);
      valid_mem=1;              
      req_valid=0;
      data_out_mem=128'hFAAABEEF_55667788_11223344_AABBCCDD;
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[0]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
      $display("Next:",dut.controller.next_state);
     $display("BEFORE WRITE cache line: %h", 
                 dut.cache.cache[1][1][154:27]);
       @(posedge clk);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[0]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
       @(posedge clk);
        $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[1][1][154:27]);
        $display("PLRU: %b", dut.cache.plru[0]);
        $display("Refill: %h", dut.controller.refill);
        $display("Read_en_cache: %b", dut.controller.read_en_cache);
       $display("DATA_OUT: %h", data_out);
       @(posedge clk);
       $display("Current_State:",dut.controller.current_state);
       $display("Next:",dut.controller.next_state);
       $display("Refill: %h", dut.controller.refill);
       $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("DATA_OUT: %h", data_out);
      $display("----------------------------END-------------------------");
      
      // WRITE MISS TEST (CLEAN BLOCK)
      @(posedge clk);
      address = {25'h1CBCDE,5'h2,2'h3};
      req_type = 0;  
      req_valid=1;
      rst=0;
      
       @(posedge clk);
       @(posedge clk);       
       req_valid=0;
       
      $display("----------------------------WRITE MISS TEST(CLEAN BLOCK)-------------------------");
      $display("=== WRITE MISS TEST ===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
      
      $display("Ready_en_cache: %0b", dut.controller.read_en_cache);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      $display("-----------------------------------------------------");      
     
      @(posedge clk);
      address = {25'h1BFCDE, 5'h2, 2'h3}; 
      req_type = 1;
      req_valid=1; 
      data_in=32'hABCDEFBF;
      rst=0;
       @(posedge clk);
      valid_mem=1;              
      req_valid=0;
      data_out_mem=128'hDAAABEEF_55667788_11223344_AABBCCDD;
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[0]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
      $display("Next:",dut.controller.next_state);
     $display("BEFORE WRITE cache line: %h", 
                 dut.cache.cache[2][1][154:27]);
       @(posedge clk);
      $display("read_en_mem: %0b", dut.cache.read_en_mem);
      $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[0]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
       @(posedge clk);
      $display("[%0t] AFTER REFILL cache line: %h", 
                  $time, 
                 dut.cache.cache[2][1][154:27]);
        $display("PLRU: %b", dut.cache.plru[0]);
        $display("Refill: %h", dut.controller.refill);
        $display("Read_en_cache: %b", dut.controller.read_en_cache);
       
       @(posedge clk);
       $display("Current_State:",dut.controller.current_state);
       $display("Next:",dut.controller.next_state);
       $display("Refill: %h", dut.controller.refill);
       $display("Read_en_cache: %b", dut.controller.read_en_cache);
      $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[2][1][154:27]);
      
     
      $display("--------------------------END---------------------------");
      // READ MISS TEST (DIRTY BLOCK)
      @(posedge clk);
      address = {25'h1EECDE,5'h3,2'h3};
      req_type = 0;  
      req_valid=1;
      rst=0;
      
       @(posedge clk);
       @(posedge clk);       
       req_valid=0;
       
      $display("--------------------------READ MISS TEST(DIRTY BLOCK)---------------------------");
      $display("=== READ MISS TEST ===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
      
      $display("Ready_en_cache: %0b", dut.controller.read_en_cache);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      $display("-----------------------------------------------------");      
     
      @(posedge clk);
      address = {25'h1CCCDE, 5'h3, 2'h3}; 
      req_type = 0;
      req_valid=1; 
      rst=0;
      data_out_mem=128'hFFFFBEEF_55667788_11223344_AABBCCDD;
       @(posedge clk);
                
      req_valid=0;
          
          
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Hit : %b:",dut.cache.hit);
      @(posedge clk);
      ready_mem=1;
      
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Valid_cache : %b",dut.controller.valid_cache);
      $display("ready_cache : %b",dut.controller.ready_cache);
      
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Valid_cache : %b",dut.controller.valid_cache);
      $display("ready_mem: %b",dut.controller.ready_mem);
      $display("Write_en_mem %b: ",dut.cache.write_en_mem);
      $display("read_en_cache : %b",dut.cache.read_en_cache);
      
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Dirty block out : %h",dut.cache.dirty_block_out);
      valid_mem=1;              
      req_valid=0;
      
      
       @(posedge clk);
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
        $display("read_en_mem: %0b", dut.cache.read_en_mem);
        $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[3]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
      
       @(posedge clk);
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
        $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[3][1][154:27]);
        $display("read_en_mem: %0b", dut.cache.read_en_mem);
        $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[3]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
        $display("DATA_OUT: %h", data_out);
        
      $display("--------------------------END---------------------------"); 
                          //WRITE MISS TEST DIRTY BLOCK
      @(posedge clk);
      address = {25'h1CADDE,5'h4,2'h3};
      req_type = 0;  
      req_valid=1;
      rst=0;
      
       @(posedge clk);
       @(posedge clk);       
       req_valid=0;
       
      $display("--------------------------WRITE MISS TEST DIRTY BLOCK---------------------------");
      $display("=== READ MISS TEST ===");
      $display("addr_in=%h tag_in_decoder=%h index=%h block offset=%h",dut.u_decoder.address,dut.u_decoder.tag,dut.u_decoder.index,dut.u_decoder.blk_offset);
      $display("HIT: %h", dut.cache.hit);
      $display("Request type: %b", dut.controller.req_type);
      $display("Controller_hit: %0b", dut.controller.hit);
      
      $display("Ready_en_cache: %0b", dut.controller.read_en_cache);
      @(posedge clk);
      $display("DATA_OUT: %h", data_out);
      $display("-----------------------------------------------------");      
     
      @(posedge clk);
      address = {25'h1EECDE, 5'h4, 2'h3}; 
      req_type = 1;
      data_in = 32'hCACDEFEF;
      req_valid=1; 
      rst=0;
       @(posedge clk);
                
      req_valid=0;
          data_out_mem=128'hFAAFBEEF_55667788_11223344_AABBCCDD;
          
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Hit : %b:",dut.cache.hit);
      @(posedge clk);
      ready_mem=1;
      
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Valid_cache : %b",dut.controller.valid_cache);
      $display("ready_cache : %b",dut.controller.ready_cache);
      
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      $display("Valid_cache : %b",dut.controller.valid_cache);
      $display("ready_mem: %b",dut.controller.ready_mem);
      $display("Write_en_mem %b: ",dut.cache.write_en_mem);
      $display("read_en_cache : %b",dut.cache.read_en_cache);
      $display("Dirty block out : %h",dut.cache.dirty_block_out);
      @(posedge clk);
      $display("Current_State:",dut.controller.current_state);
      $display("Next:",dut.controller.next_state);
      valid_mem=1;              
      req_valid=0;
      
      
       @(posedge clk);
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
        $display("read_en_mem: %0b", dut.cache.read_en_mem);
        $display("write_en_cache: %0b", dut.cache.write_en_cache);
        $display("PLRU: %b", dut.cache.plru[4]);
        $display("Dirty bit: %b", dut.cache.info1.dirty);
        $display("Valid bit: %b", dut.cache.info1.valid);
      
       @(posedge clk);
        $display("Current_State:",dut.controller.current_state);
        $display("Next:",dut.controller.next_state);
        $display("[%0t] AFTER WRITE cache line: %h", 
                  $time, 
                 dut.cache.cache[4][1][154:27]);
       
       $display("-------------------------END----------------------------");    
      
$finish;
end 
endmodule


