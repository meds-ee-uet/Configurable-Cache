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
  // Preload sets
  // =========================================
  initial begin
    clk = 0;
    for (int s = 0; s < NUM_SETS; s++) begin
      for (int w = 0; w < NUM_WAYS; w++) begin
        uut.cache[s][w] = '0;
      end
    end

    // Set 0 preload 8 ways
    uut.cache[0][0] = {128'hAAAABBBB_CCCC1111_DDDD2222_EEEE3333, 27'h0ABCDE, 1'b0, 1'b1};
    uut.cache[0][1] = {128'h12345678_9ABCDEF0_FEDCBA98_76543210, 27'h0BCDEF, 1'b0, 1'b1};
    uut.cache[0][2] = {128'hFACEFACE_BEEFBEEF_DEADDEAD_CAFECAFE, 27'h0CDEF0, 1'b0, 1'b1};
    uut.cache[0][3] = {128'h11112222_33334444_55556666_77778888, 27'h0DEF01, 1'b0, 1'b1};
    uut.cache[0][4] = {128'hAAAA0000_BBBB1111_CCCC2222_DDDD3333, 27'h0EE001, 1'b0, 1'b1};
    uut.cache[0][5] = {128'h44445555_66667777_88889999_AAAA0000, 27'h0FF002, 1'b0, 1'b1};
    uut.cache[0][6] = {128'hABCDEF01_23456789_13579BDF_2468ACE0, 27'h0AA123, 1'b0, 1'b1};
    uut.cache[0][7] = {128'hCAFEBABE_DEADC0DE_FEEDBEEF_ABCD9999, 27'h0BB456, 1'b0, 1'b1};

    // Set 1 preload some ways
    uut.cache[1][3] = {128'hAAAA1111_BBBB2222_CCCC3333_DDDD4444, 27'h11AA33, 1'b0, 1'b1};
    uut.cache[1][5] = {128'h55556666_77778888_9999AAAA_BBBBCCCC, 27'h22BB44, 1'b0, 1'b1};
    uut.cache[1][7] = {128'hDEADBEAF_FEEDFACE_CAFEBABE_12345678, 27'h33CC55, 1'b0, 1'b1};
    uut.cache[1][1] = {128'hFACE1234_C0DE5678_BEEF9ABC_76543210, 27'h44DD66, 1'b0, 1'b1};
  end

  // ===============================
  // Task: perform_write_hit
  // ===============================
  task automatic perform_write_hit(
      input logic [INDEX_WIDTH-1:0]   index_in,
      input logic [TAG_WIDTH-1:0]     tag_in,
      input logic [OFFSET_WIDTH-1:0]  blk_offset_in,
      input logic [WORD_SIZE-1:0]     data_in_val,
      input int                       way_id
  );
  begin
    @(posedge clk);
    index          = index_in;
    tag            = tag_in;
    blk_offset     = blk_offset_in;
    req_type       = 1;              // WRITE
    data_in        = data_in_val;
    write_en_cache = 1;

    @(posedge clk);                  // perform write
    write_en_cache = 0;

    @(posedge clk);
    $display("[WRITE HIT] Set=%0d Way=%0d Tag=%h Offset=%0d Data_in=%h Hit=%b",
              index_in, way_id, tag_in, blk_offset_in, data_in_val, hit);
    $display("           Updated CacheLine=%h",
              uut.cache[index_in][way_id][BLOCK_SIZE+TAG_WIDTH+1 : TAG_WIDTH+2]);
    $display("-----------------------------------------------------");
  end
  endtask

  // ===============================
  // Task: perform_read_hit
  // ===============================
  task automatic perform_read_hit(
      input logic [INDEX_WIDTH-1:0]  index_in,
      input logic [TAG_WIDTH-1:0]    tag_in,
      input logic [OFFSET_WIDTH-1:0] blk_offset_in,
      input logic [WORD_SIZE-1:0]    expected_data,
      input int                      way_id
  );
  begin
    @(posedge clk);
    index        = index_in;
    tag          = tag_in;
    blk_offset   = blk_offset_in;
    req_type     = 0;              // READ
    read_en_cache = 1;

    @(posedge clk);
    read_en_cache = 0;

    @(posedge clk);
    $display("[READ HIT]  Set=%0d Way=%0d Tag=%h Offset=%0d Hit=%b Data_out=%h",
              index_in, way_id, tag_in, blk_offset_in, hit, data_out);

    if (hit && data_out == expected_data)
      $display("           PASS: Read data matched expected=%h", expected_data);
    else
      $display("           FAIL: Expected=%h Got=%h", expected_data, data_out);

    $display("-----------------------------------------------------");
  end
  endtask
  
  // Task: perform_write_miss_clean
// ===============================
task automatic perform_write_miss_clean(
    input  logic [INDEX_WIDTH-1:0]   index_in,       // cache index
    input  logic [TAG_WIDTH-1:0]     new_tag,        // new tag (causes miss)
    input  logic [OFFSET_WIDTH-1:0]  blk_offset_in,  // block offset
    input  logic [WORD_SIZE-1:0]     write_data,     // data to write
    input  logic [BLOCK_SIZE-1:0]    refill_data    // refill block from memory
   
);
begin
    $display("====================================================");
    $display(" WRITE MISS WITH CLEAN BLOCK (Set=%0d, Tag=%h)", index_in, new_tag);

    // ---- Step 1: Generate a miss ----
    @(posedge clk);
    index          = index_in;
    tag            = new_tag;
    blk_offset     = blk_offset_in;
    req_type       = 1;            // WRITE
    data_in        = write_data;
    write_en_cache = 1;

    @(posedge clk); // launch
    @(posedge clk); // wait for hit check

    if (!hit)
        $display("[INFO] Miss detected correctly at Set=%0d (expected)", index_in);
    else
        $display("[FAIL] Unexpected hit on write miss case.");

    // ---- Step 2: Simulate memory refill ----
    write_en_cache = 0;
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

    // ---- Step 3: Retry write → should now hit and update ----
    @(posedge clk);
    tag            = new_tag;
    blk_offset     = blk_offset_in;
    req_type       = 1;
    data_in        = write_data;
    write_en_cache = 1;

    @(posedge clk);
    write_en_cache = 0;
    @(posedge clk);

    
  if (hit)
    $display("[PASS] write Miss Clean → Refetched correctly. cacheline=%h", uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
  else
    $display("[FAIL] write Miss Clean → Did not refill correctly.");

    $display("-----------------------------------------------------");
end
endtask
  
// ======================================
// Task: perform_write_miss_dirty
// ======================================
task automatic perform_write_miss_dirty(
    input  logic [INDEX_WIDTH-1:0]   index_in,        // cache index
    input  logic [TAG_WIDTH-1:0]     new_tag,         // new tag (causes miss + eviction)
    input  logic [OFFSET_WIDTH-1:0]  blk_offset_in,   // block offset for write
    input  logic [WORD_SIZE-1:0]     write_data,      // data to write
    input  logic [BLOCK_SIZE-1:0]    refill_data    // refill block from memory
   
);
begin
    $display("-----------------------------------------------------");
    $display("WRITE MISS WITH DIRTY BLOCK (Set=%0d, Tag=%h)", index_in, new_tag);

    // =================================================
    // Phase A: Issue WRITE MISS → should evict dirty victim
    // =================================================
    @(posedge clk);
    index          = index_in;
    tag            = new_tag;
    blk_offset     = blk_offset_in;
    req_type       = 1;              // WRITE
    write_en_cache = 1;
    data_in        = write_data;

    @(posedge clk);
    if (!hit)
        $display("[PHASE A] PASS: Miss detected, victim is dirty (eviction needed).");
    else
        $display("[PHASE A] FAIL: Unexpected hit on write miss dirty.");

    // =================================================
    // Phase B: WRITE-BACK dirty victim to memory
    // =================================================
    write_en_mem   = 1;
    read_en_cache  = 1;   // handshake to push dirty victim out
    @(posedge clk); @(posedge clk);

    $display("[PHASE B] WRITE-BACK: dirty_block_out = %h", dirty_block_out);

    write_en_mem   = 0;
    read_en_cache  = 0;

    // =================================================
    // Phase C: REFILL from memory
    // =================================================
    @(posedge clk);
    read_en_mem    = 1;
    write_en_cache = 1;
    data_in_mem    = refill_data;

    @(posedge clk);
    $display("[REFILL] Data_in_mem = %h", data_in_mem);

    @(posedge clk);
    $display("[REFILL] Cache line written at Set=%0d, Way=%0d, CacheLine=%h",
             index_in, uut.accessed_way,
             uut.cache[index_in][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

    read_en_mem    = 0;
    write_en_cache = 0;

    // =================================================
    // Phase D: Retry write → should hit and update
    // =================================================
    @(posedge clk);
    tag            = new_tag;
    blk_offset     = blk_offset_in;
    req_type       = 1;
    data_in        = write_data;
    write_en_cache = 1;

    @(posedge clk);
    write_en_cache = 0;
    @(posedge clk);

   if (hit)
  $display("[PHASE E] PASS: Post-refill HIT. cache line=%h",  uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
else
  $display("[PHASE E] FAIL: Post-refill read did not hit.");


    $display("-----------------------------------------------------");
end
endtask

  // ===============================
  // Sequence: write hits then read hit
  // ===============================
  initial begin
    // Wait preload done
    #20;

    // Write Hit requests
    perform_write_hit(3'd0, 27'h0DEF01, 2'd0, 32'hAAAA1111, 3); // Way 3, Word0
    perform_write_hit(3'd0, 27'h0FF002, 2'd1, 32'hBBBB2222, 5); // Way 5, Word1
    perform_write_hit(3'd0, 27'h0BB456, 2'd0, 32'hCCCC3333, 7); // Way 7, Word0

    // Read Hit
    perform_read_hit (3'd0, 27'h0BCDEF, 2'd3, 32'h12345678, 1); // Way 1, Word3

    // More Write Hits
    perform_write_hit(3'd0, 27'h0ABCDE, 2'd2, 32'hDDDD4444, 0); // Way 0, Word2
    perform_write_hit(3'd0, 27'h0CDEF0, 2'd1, 32'hEEEE5555, 2); // Way 2, Word1
    perform_write_hit(3'd0, 27'h0EE001, 2'd2, 32'hFFFF6666, 4); // Way 4, Word2
    perform_write_hit(3'd0, 27'h0AA123, 2'd3, 32'h12345678, 6); // Way 6, Word3

    //  Write Miss Clean (Set=0 example)
    perform_write_miss_clean(
        3'd0,                        // index = Set 0
        27'h666BBB,                  // new tag → not in set 0
        2'd1,                        // blk_offset = word1
        32'hCAFE_BABE,               // data_in (word to write)
        128'hAAAABBBB_CCCC1111_DDDD2222_EEEE3333  // refill block from memory
    );
    
        // ======================================
    // Test: Write Miss with Dirty Victim
    // ======================================
    perform_write_miss_dirty(
        3'd0,                        // index = Set 1
        27'h777CCC,                  // new tag → not in set 1 (forces miss + eviction)
        2'd3,                        // blk_offset = word3
        32'hBEEF_BABE,               // data_in (word to write)
        128'h9999AAAA_BBBBCCCC_DDDD1111_EEEE2222  // refill block from memory
    );

    #50;
    $finish;
  end

endmodule

