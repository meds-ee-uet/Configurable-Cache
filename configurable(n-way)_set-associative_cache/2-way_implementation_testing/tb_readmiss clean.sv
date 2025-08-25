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
    // Run Read Hit transaction
    // =========================
    @(posedge clk);
    // request read
index        = 0;
tag          = 25'h1ABCDE;
blk_offset   = 2;        // word[2] = 0x55667788
req_type     = 0;
read_en_cache= 1;

@(posedge clk); // request launched
@(posedge clk); // wait one more for data_out

$display("Hit=%b, Data_out=%h", hit, data_out);

if (hit && data_out == 32'h55667788)
  $display("[PASS] Read Hit worked.");
else
  $display("[FAIL] Read Hit mismatch. Got=%h Expected=%h",
           data_out, 32'h55667788);
    $display("READ HIT CASE COMPLETED"); 
   $display("-----------------------------------------------------"); 
     $display("-----------------------------------------------------"); 
    // =========================
    // Run Read MISS CLEAN transaction
    // =========================
    // Step 1: Request with new tag → causes miss
    $display("READ MISS WITH CLEAN BLOCK CASE STARTED");
    
   @(posedge clk);
index        = 0;
tag          = 25'h12345; // new tag = miss
blk_offset   = 1;         // arbitrary word
req_type     = 0;         // read
read_en_cache= 1;

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
$display("[REFILL] Cache line written at set=%0d, way=%0d", index, uut.accessed_way);

@(posedge clk);
read_en_mem   = 0;
write_en_cache= 0;
$display("[REFILL] Cache contents = %h", 
          uut.cache[index][uut.accessed_way][BLOCK_SIZE + TAG_WIDTH + 1 : TAG_WIDTH + 2]);

// Step 3: Read again with same tag/index → should now hit
tag          = 25'h12345;
blk_offset   = 0;
read_en_cache= 1;

@(posedge clk);
@(posedge clk); // wait for data_out

if (hit)
  $display("[PASS] Read Miss Clean → Refetched correctly. Data_out=%h", data_out);
else
  $display("[FAIL] Read Miss Clean → Did not refill correctly.");

    
    

    $finish;
  end

endmodule
