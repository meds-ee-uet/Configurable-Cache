// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: This file contains the testbench code to verify all write cases of n way cache memory module for 4 way implementation.
//
// Author: Ammarah Wakeel.
// Date: 15th, August, 2025.
`timescale 1ns/1ps

module tb_cache_read_hit_preload;

  // Parameters
  localparam int WORD_SIZE       = 32;
  localparam int WORDS_PER_BLOCK = 4;
  localparam int BLOCK_SIZE      = WORDS_PER_BLOCK * WORD_SIZE;
  localparam int NUM_BLOCKS      = 64;
  localparam int NUM_WAYS        = 4;
  localparam int NUM_SETS        = NUM_BLOCKS / NUM_WAYS;
  localparam int INDEX_WIDTH     = $clog2(NUM_SETS);
  localparam int OFFSET_WIDTH    = $clog2(WORDS_PER_BLOCK);
  localparam int TAG_WIDTH       = 32 - (INDEX_WIDTH + OFFSET_WIDTH);

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

  initial begin
    clk = 0;
    // In testbench before preload
for (int s = 0; s < NUM_SETS; s++) begin
  for (int w = 0; w < NUM_WAYS; w++) begin
    uut.cache[s][w] = '0;   // zero whole line
  end
end


    // preload one block in set=0, way=0 with valid=1
    // Preload Set=0, Way=0
    uut.cache[0][0] = {
    128'hAAAABBBB_CCCC1111_DDDD2222_EEEE3333, // block (word3=AAAA..., word2=CCCC..., word1=DDDD..., word0=EEEE...)
    26'h1ABCDE,                               // tag
    1'b0,                                     // dirty
    1'b1                                      // valid
};

// Preload Set=0, Way=1
    uut.cache[0][1] = {
    128'h12345678_9ABCDEF0_FEDCBA98_76543210, // block
    26'h2BCDEF,                               // tag
    1'b0,                                     // dirty
    1'b1                                      // valid
};
    // Preload Set=0, Way=2
uut.cache[0][2] = {
    128'hFACEFACE_BEEFBEEF_DEADDEAD_CAFECAFE, // block
    26'h3CDEF0,                               // tag
    1'b0,                                     // dirty
    1'b1                                      // valid
};

// Preload Set=0, Way=3
uut.cache[0][3] = {
    128'h11112222_33334444_55556666_77778888, // block
    26'h4DEF01,                               // tag
    1'b0,                                     // dirty
    1'b1                                      // valid
};



    // =========================
    // Run WRITE Hit transaction
    // =========================
   // =========================
// Run WRITE HIT transaction (Set=1, Way=0)
// =========================
    $display("WRITE HIT CASE (4-way, Set=0, Way=0) STARTED");

@(posedge clk);
index          = 4'd0;          // Set = 0 (4 bits)
tag            = 26'h1ABCDE;    // Matches Way=0 preload
blk_offset     = 2'd2;          // Select Word[2] = 0xDDDD2222
req_type       = 1;             // WRITE
write_en_cache = 1;
data_in= 32'hA1B2C3D4;

@(posedge clk); // launch
@(posedge clk); // wait 1 cycle
// Directly display what’s inside the cache after write
$display("Got Cache Block     = %h", 
          uut.cache[0][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
$display("Expected Cache Block= %h", 
          {32'hAAAABBBB, 32'hA1B2C3D4, 32'hDDDD2222, 32'hEEEE3333});

if (hit && uut.cache[0][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] 
              == {32'hAAAABBBB, 32'hA1B2C3D4, 32'hDDDD2222, 32'hEEEE3333})
  $display("[PASS] Write Hit worked. Cache block updated correctly.");
else
  $display("[FAIL] Write Hit mismatch.\n Got      = %h\n Expected = %h",
           uut.cache[0][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2],
           {32'hAAAABBBB, 32'hA1B2C3D4, 32'hDDDD2222, 32'hEEEE3333});

$display("write CASE COMPLETED");
        // =========================
    // WRITE HIT cases for 4-way cache
    // =========================
    $display("WRITE HIT CASES (4-way, Set=0)");

    // -------- Way 2 read hit(because i want to check write miss clean block case) --------
    @(posedge clk);
    index      = 4'd0;
    tag        = 26'h3CDEF0;   // Matches Way=2 preload
    blk_offset = 2'd1;         // Word1 = 32'hDEADDEAD
    req_type   = 0;            // read
    read_en_cache = 1;
   

    @(posedge clk);
    write_en_cache = 0;

    @(posedge clk);
    $display("[ READ HIT] Hit=%b Data_out=%h Way=%0d", hit, data_out, 2);

    // -------- Way 3 WRITE hit --------
    @(posedge clk);
    index      = 4'd0;
    tag        = 26'h4DEF01;   // Matches Way=3 preload
    blk_offset = 2'd0;         // Word0 = 32'h77778888
    req_type   = 1;            //  WRITE
    write_en_cache = 1;
  data_in = 32'hDEADBEEF;
    @(posedge clk);
    write_en_cache = 0;

    @(posedge clk);
    $display("[WRITE HIT] Hit=%b Data_out=%h Way=%0d", hit, uut.cache[0][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2], 3);

    // -------- Way 1 WRITE hit --------
    @(posedge clk);
    index      = 4'd0;
    tag        = 26'h2BCDEF;   // Matches Way=1 preload
    blk_offset = 2'd3;         // Word3 = 32'h12345678
    req_type   = 1;            //WRITE
     write_en_cache = 1;
    data_in = 32'hCAFEBABE;
    @(posedge clk);
    write_en_cache = 0;

    @(posedge clk);
    $display("[WRITE HIT] Hit=%b Data_out=%h Way=%0d", hit, uut.cache[0][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2], 1);

    $display("-----------------------------------------------------");
$display("-----------------------------------------------------");
$display("-----------------------------------------------------");
      // =========================
  // WRITE MISS WITH CLEAN BLOCK (4-way, Set=0)
  // =========================
  $display("WRITE MISS WITH CLEAN BLOCK CASE STARTED");

  // ---- Step 1: Generate a miss ----
  @(posedge clk);
  index        = 0;
  tag          = 26'h1ABCD1;   // New tag (does not match any preloaded way)
  blk_offset   = 2'd2;         // Arbitrary word
  req_type     = 1;            // WRITE
  write_en_cache= 1;
   data_in = 32'h0F0F0F0F;

  @(posedge clk); // launch
  @(posedge clk); // wait to see hit=0

  if (!hit)
    $display("[INFO] Miss detected correctly at Set=%0d (expected)", index);
  else
    $display("[FAIL] Unexpected hit on miss case.");

  // ---- Step 2: Simulate memory refill ----
  read_en_cache = 0;
  read_en_mem   = 1;
  write_en_cache= 1;
  data_in_mem   = 128'hCAFEBABE_FEEDFACE_DEADBEAF_87654321;
    
@(posedge clk);
  $display("[REFILL] Data_in_mem = %h", data_in_mem);

  @(posedge clk);
  $display("[REFILL] Cache line written at Set=%0d, Way=%0d", index, uut.accessed_way);

  read_en_mem   = 0;
  write_en_cache= 0;

  $display("[REFILL] Cache contents (Set=%0d, Way=%0d) = %h", 
            index, uut.accessed_way,
            uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

  // ---- Step 3: write again with same tag/index → should hit ----
  @(posedge clk);
  tag          = 26'h1ABCD1;   // Same tag to hit
  blk_offset   = 2'd0;
  req_type     = 1;
  write_en_cache= 1;
  data_in = 32'h0F0F0F0F;

  @(posedge clk);
  @(posedge clk); // wait for data_out

  if (hit)
    $display("[PASS] write Miss Clean → Refetched correctly. cacheline=%h", uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
  else
    $display("[FAIL] write Miss Clean → Did not refill correctly.");

  $display("-----------------------------------------------------");
    $display("WRITE MISS WITH DIRTY BLOCK CASE STARTED");
    // =================================================
// Phase B: Issue WRITE MISS Dirty block (new tag → should evict dirty way0)
// =================================================
@(posedge clk);
index         = 0;
tag           = 26'h1EEEEF;    // new tag
blk_offset    = 1;
req_type      = 1;
write_en_cache = 1;
data_in= 32'hFFFFFFFF;
    
@(posedge clk);
if (!hit)
  $display("[PHASE B] PASS: Miss detected, victim should be way0 (dirty).");
else
  $display("[PHASE B] FAIL: Unexpected hit.");

// =================================================
// Phase C: WRITE-BACK dirty victim (way0)
// =================================================
write_en_mem = 1; 
read_en_cache=1;// handshake with dirty eviction
@(posedge clk); @(posedge clk);
$display("[PHASE C] WRITE-BACK: dirty_block_out = %h", dirty_block_out);

write_en_mem   = 0;
read_en_cache  = 0;

// =================================================
// Phase D: REFILL from memory
// =================================================
@(posedge clk);
read_en_mem    = 1;
write_en_cache = 1;
data_in_mem    = 128'hFEEDFACE_DEADBEAF_CAFEBABE_12345678;

@(posedge clk);
$display("[REFILL] Data_in_mem = %h", data_in_mem);

@(posedge clk);
    $display("[REFILL] Cache line written at set=%0d, way=%0d, cache line=%h", index, uut.accessed_way,  uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

read_en_mem    = 0;
write_en_cache = 0;

// =================================================
// Phase E: Re-read with new tag → should HIT in cache
// =================================================
@(posedge clk);
tag           = 26'h1EEEEF;
blk_offset    = 1;
write_en_cache = 1;
data_in= 32'hFFFFFFFF;
    

@(posedge clk); @(posedge clk);
if (hit)
  $display("[PHASE E] PASS: Post-refill HIT. cache line=%h",  uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
else
  $display("[PHASE E] FAIL: Post-refill read did not hit.");

@(posedge clk);
write_en_cache = 0;

$display("-----------------------------------------------------");
    $display("TESTS FOR VERIFIYING COMPULSORY MISSES ARE HANDLED CORRECTLY");    
    // =========================================================
// PRELOAD set=1: way0 and way2
// =========================================================
$display("============================================");
$display("PRELOAD Set=1: Way0 (valid+clean), Way2 (valid+clean)");
$display("============================================");

uut.cache[1][0] = {
  128'hAAAAAAAA_BBBBBBBB_CCCCCCCC_DDDDDDDD,  // block (way0)
  26'h111111,                                // tag way0
  1'b0,                                      // dirty=0
  1'b1                                       // valid=1
};

uut.cache[1][2] = {
  128'h11112222_33334444_55556666_77778888,  // block (way2)
  26'h222222,                                // tag way2
  1'b0,                                      // dirty=0
  1'b1                                       // valid=1
};

// =========================================================
// READ HIT on way0
// =========================================================
$display("-----------------------------------------------------");
$display("READ HIT on set=1 way=0 STARTED");
@(posedge clk);
index         = 1;
tag           = 26'h111111;    // way0 tag
blk_offset    = 0;
req_type      = 0;             // read
read_en_cache = 1;

@(posedge clk); @(posedge clk);
if (hit && uut.accessed_way == 0)
  $display("[PASS] Read HIT on set=1 way=0. data_out=%h", data_out);
else
  $display("[FAIL] Expected HIT on way=0, got hit=%0b, accessed_way=%0d", hit, uut.accessed_way);

@(posedge clk);
read_en_cache = 0;

// =========================================================
// READ HIT on way2
// =========================================================
$display("-----------------------------------------------------");
$display("READ HIT on set=1 way=2 STARTED");
@(posedge clk);
index         = 1;
tag           = 26'h222222;    // way2 tag
blk_offset    = 1;
req_type      = 0;             // read
read_en_cache = 1;

@(posedge clk); @(posedge clk);
if (hit && uut.accessed_way == 2)
  $display("[PASS] Read HIT on set=1 way=2. data_out=%h", data_out);
else
  $display("[FAIL] Expected HIT on way=2, got hit=%0b, accessed_way=%0d", hit, uut.accessed_way);

@(posedge clk);
read_en_cache = 0;

// =========================================================
// WRITE MISS with CLEAN victim (set=1)
// =========================================================
$display("-----------------------------------------------------");
    $display("write MISS WITH CLEAN BLOCK (set=1)");
@(posedge clk);
index         = 1;
tag           = 26'h333333;   // new tag (not present)
blk_offset    = 2;
req_type      = 1;            // write
write_en_cache = 1;
data_in= 32'h89ABCDEF;
@(posedge clk); @(posedge clk); // wait for hit result
if (!hit)
  $display("[INFO] Correctly detected MISS at set=1.");
else
  $display("[FAIL] incorrectly showed hit when a miss should occur.");
    
    
$display("DEBUG: Cache[1][0] V=%b D=%b TAG=%h BLK=%h",
  uut.cache[1][0][0],                                   // valid
  uut.cache[1][0][1],                                   // dirty
  uut.cache[1][0][TAG_WIDTH+1 : 2],                     // tag
  uut.cache[1][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]); // block

$display("DEBUG: Cache[1][1] V=%b D=%b TAG=%h BLK=%h",
  uut.cache[1][1][0],
  uut.cache[1][1][1],
  uut.cache[1][1][TAG_WIDTH+1 : 2],
  uut.cache[1][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

$display("DEBUG: Cache[1][2] V=%b D=%b TAG=%h BLK=%h",
  uut.cache[1][2][0],
  uut.cache[1][2][1],
  uut.cache[1][2][TAG_WIDTH+1 : 2],
  uut.cache[1][2][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

$display("DEBUG: Cache[1][3] V=%b D=%b TAG=%h BLK=%h",
  uut.cache[1][3][0],
  uut.cache[1][3][1],
  uut.cache[1][3][TAG_WIDTH+1 : 2],
  uut.cache[1][3][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);



// REFILL sequence
@(posedge clk);
 // ---- Step 2: Simulate memory refill ----
  read_en_cache = 0;
  read_en_mem   = 1;
  write_en_cache= 1;
  data_in_mem   = 128'hCAFEBABE_FEEDFACE_DEADBEAF_87654321;

  @(posedge clk);
  $display("[REFILL] Data_in_mem = %h", data_in_mem);

  @(posedge clk);
  $display("[REFILL] Cache line written at Set=%0d, Way=%0d", index, uut.accessed_way);

  read_en_mem   = 0;
  write_en_cache= 0;

  $display("[REFILL] Cache contents (Set=%0d, Way=%0d) = %h", 
            index, uut.accessed_way,
            uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

  // ---- Step 3: Read again with same tag/index → should hit ----
  @(posedge clk);
  tag          = 26'h333333;   // Same tag to hit
  blk_offset   = 2'd0;
  req_type     = 1;
  write_en_cache= 1;
    data_in= 32'h89ABCDEF;

  @(posedge clk);
  @(posedge clk); // wait for data_out

  if (hit)
    $display("[PASS] write Miss Clean → Refetched correctly. cache content =%h",  uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
  else
    $display("[FAIL] write Miss Clean → Did not refill correctly.");

  $display("-----------------------------------------------------");

    $finish;
  end

endmodule

