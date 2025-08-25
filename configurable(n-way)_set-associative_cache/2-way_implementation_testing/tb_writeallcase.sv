`timescale 1ns/1ps

module tb_cache_read_hit_preload;

  // Parameters
  localparam int WORD_SIZE       = 32;
  localparam int WORDS_PER_BLOCK = 4;
  localparam int BLOCK_SIZE      = WORDS_PER_BLOCK * WORD_SIZE;
  localparam int NUM_BLOCKS      = 64;
  localparam int NUM_WAYS        = 2;
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
   
  // Way 0 (clean + valid)
  uut.cache[0][0] = {
    128'hDEADBEEF_55667788_11223344_AABBCCDD,  // block
    25'h1ABCDE,                                // tag
    1'b0,                                      // dirty
    1'b1                                       // valid
  };

  // Way 1 (clean + valid)
  uut.cache[0][1] = {
    128'hFACEB00C_DEADC0DE_C0FFEE11_12345678,  // block
    25'h0C0FF,                                 // tag (different from way 0)
    1'b0,                                      // dirty
    1'b1                                       // valid
  };



    // =========================
    // Run WRITE Hit transaction
    // =========================
    @(posedge clk);
    // request read
index        = 0;
tag          = 25'h1ABCDE;
blk_offset   = 2;        // word[2] = 0x55667788
req_type     = 1;
data_in = 32'h11112222;
write_en_cache= 1;

@(posedge clk); // request launched
@(posedge clk); // wait one more

$display("Hit=%b, Data_out=%h", hit, data_out);

// Directly display what’s inside the cache after write
$display("Got Cache Block    = %h", 
          uut.cache[0][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
$display("Expected Cache Block = %h", 
          {32'hDEADBEEF, 32'h11112222, 32'h11223344, 32'hAABBCCDD});

if (hit && uut.cache[0][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2] 
              == {32'hDEADBEEF, 32'h11112222, 32'h11223344, 32'hAABBCCDD})
  $display("[PASS] Write Hit worked. Cache block updated correctly.");
else
  $display("[FAIL] Write Hit mismatch.\n Got      = %h\n Expected = %h",
           uut.cache[0][0][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2],
           {32'hDEADBEEF, 32'h11112222, 32'h11223344, 32'hAABBCCDD});

$display("write CASE COMPLETED"); 
$display("-----------------------------------------------------"); 
$display("-----------------------------------------------------");  
    // =========================
    // Run WRITE MISS CLEAN transaction
    // =========================
    // Step 1: Request with new tag → causes miss
    $display("WRITE MISS WITH CLEAN BLOCK CASE STARTED");
    
   @(posedge clk);
index        = 0;
tag          = 25'h12345; // new tag = miss
blk_offset   = 1;         // arbitrary word
req_type     = 1;         // write
write_en_cache= 1;
data_in = 32'h33334444;

@(posedge clk); // launch
@(posedge clk); // wait to see hit=0

if (!hit)
  $display("[INFO] Miss detected correctly.");
else
  $display("[FAIL] Unexpected hit on miss case.");

// Step 2: Emulate memory sending refill
    
read_en_cache = 0;
read_en_mem   = 1;
write_en_cache= 1;
data_in_mem   = 128'hCAFEBABE_FEEDFACE_DEADBEAF_87654321;
// After refill cycle
@(posedge clk);

    $display("[REFILL] Data_in_mem = %h", data_in_mem);

@(posedge clk);
    $display("[REFILL] Cache line written at set=%0d, way=%0d", index, uut.accessed_way);
    
read_en_mem   = 0;
write_en_cache= 0;
$display("[REFILL] Cache contents = %h", 
          uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

// Step 3: Read again with same tag/index → should now hit
tag          = 25'h12345;
blk_offset   = 1;
write_en_cache= 1;

@(posedge clk);
@(posedge clk); // wait for data_out

if (hit)
  $display("[PASS] WRITE Miss Clean → Refetched correctly. cache_line modified as=%h", uut.cache[0][1][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
else
  $display("[FAIL] write Miss Clean → Did not refill correctly.");
   
    $display("-----------------------------------------------------"); 
     $display("-----------------------------------------------------");
  // =========================
  // Run write MISS DIRTY transaction
  // =========================
    $display("write MISS WITH DIRTY BLOCK CASE STARTED");
// =========================================================
// write MISS with DIRTY victim (train PLRU via a hit on way1)
// =========================================================
$display("============================================");
    $display("write MISS WITH DIRTY: Train PLRU on way1, evict way0");
$display("============================================");

// Preload set=1: way0 = DIRTY+valid, way1 = CLEAN+valid
uut.cache[1][0] = {
  128'hAAAAAAAA_BBBBBBBB_CCCCCCCC_DDDDDDDD,  // block (dirty)
  25'h2AAAA,                                 // tag way0
  1'b1,                                      // dirty = 1
  1'b1                                       // valid = 1
};
uut.cache[1][1] = {
  128'h11111111_22222222_33333333_44444444,  // block (clean)
  25'h2BBBB,                                 // tag way1
  1'b0,                                      // dirty = 0
  1'b1                                       // valid = 1
};

// -------- Phase A: Read HIT on way1 to set PLRU (way0 becomes LRU)
@(posedge clk);
index         = 1;
tag           = 25'h2BBBB;    // this is way1's tag
blk_offset    = 0;
req_type      = 0;            // read
read_en_cache = 1;

@(posedge clk); @(posedge clk); // allow hit to settle
if (hit && uut.accessed_way == 1)
  $display("[PHASE A] PASS: Hit on set=1 way=1, PLRU should mark way0 as LRU.");
else
  $display("[PHASE A] WARN: Expected hit on way=1; hit=%0b, accessed_way=%0d", hit, uut.accessed_way);

// Deassert cache read before next phase
@(posedge clk);
read_en_cache = 0;

// -------- Phase B: Issue a READ MISS with a new tag (should evict LRU = way0)
@(posedge clk);
index         = 1;
tag           = 25'h2CCCC;    // new tag → miss
blk_offset    = 2;
req_type      = 1;            // write
write_en_cache = 1;
data_in = 32'h77778888;
@(posedge clk); // miss recognized by DUT
if (!hit)
  $display("[PHASE B] MISS detected at set=1");
else
  $display("[PHASE B] FAIL: Unexpected hit during dirty-miss setup.");


// -------- Phase C: WRITE-BACK (dirty victim) — handshake (read_en_cache && write_en_mem)
read_en_cache=1;
write_en_mem = 1;       // with read_en_cache still 1
@(posedge clk);
@(posedge clk);
    $display("[PHASE C] WRITE-BACK: dirty_block_out = %h", dirty_block_out);
write_en_mem = 0;
read_en_cache=0;
 
// -------- Phase D: REFILL (write-allocate) — handshake (read_en_mem && write_en_cache)
@(posedge clk);
read_en_mem    = 1;
write_en_cache = 1;
data_in_mem    = 128'hFEEDFACE_DEADBEAF_CAFEBABE_12345678; // new line from memory

// After refill cycle
@(posedge clk);

    $display("[REFILL] Data_in_mem = %h", data_in_mem);

@(posedge clk);
    $display("[REFILL] Cache line written at set=%0d, way=%0d", index, uut.accessed_way);
    
read_en_mem   = 0;
write_en_cache= 0;
$display("[REFILL] Cache contents = %h", 
          uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

// -------- Phase E: Read again with same tag → should HIT new line
@(posedge clk);
tag           = 25'h2CCCC;
blk_offset    = 0;
write_en_cache = 1;

@(posedge clk); @(posedge clk);
if (hit)
  $display("[PHASE E] PASS: Post-refill write HIT. cache line modified after write=%h", uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);
else
  $display("[PHASE E] FAIL: Post-refill read did not hit.");

@(posedge clk);
write_en_cache = 0;


    
    

    $finish;
  end

endmodule
