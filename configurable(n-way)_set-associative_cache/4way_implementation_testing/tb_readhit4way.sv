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
    // Run Read Hit transaction
    // =========================
   // =========================
// Run READ HIT transaction (Set=1, Way=0)
// =========================
    $display("READ HIT CASE (4-way, Set=0, Way=0) STARTED");

@(posedge clk);
index          = 4'd0;          // Set = 0 (4 bits)
tag            = 26'h1ABCDE;    // Matches Way=0 preload
blk_offset     = 2'd2;          // Select Word[2] = 0xDDDD2222
req_type       = 0;             // Read
read_en_cache = 1;

@(posedge clk); // launch
@(posedge clk); // wait 1 cycle

$display("Hit=%b, Data_out=%h", hit, data_out);
if (hit && data_out == 32'hCCCC1111) begin
    $display("[PASS] READ HIT Way0 worked. Data_out=%h", data_out);
end else begin
    $display("[FAIL] READ HIT mismatch. Got=%h Expected=%h",
             data_out, 32'hCCCC1111);
end

$display("-----------------------------------------------------");
$display("-----------------------------------------------------");

    $finish;
  end

endmodule