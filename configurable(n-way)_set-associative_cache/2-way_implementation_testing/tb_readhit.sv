// or browse Examples
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

    // preload one block in set=0, way=0 with valid=1
    uut.cache[0][0] = {
      128'hDEADBEEF_55667788_11223344_AABBCCDD,  // block
      25'h1ABCDE,                                // tag
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

    $finish;
  end

endmodule
