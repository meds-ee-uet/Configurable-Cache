## 1- What is a 2-Way Set Associative Cache?
A set-associative cache allows each memory block to map to a specific set containing multiple lines (ways).

In 2-way set associative, each set contains 2 lines. The cache index selects a set, but within that set, two tags are compared in parallel. Replacement policy (e.g., LRU) decides which line to evict when the set is full
## 2- Specifications of Our 2-Way Set Associative Cache:



| **Parameter**        | **Value (from code)** |
|-----------------------|------------------------|
| Word Size            | 32 bits (per word) |
| Words per Block      | 4 words |
| Block Size           | 128 bits (16 bytes per block) |
| Number of Blocks     | 64 (total cache lines across all sets & ways) |
| Associativity        | 2-way (each set holds 2 cache lines) |
| Number of Sets       | 32 sets (NUM_BLOCKS / NUM_WAYS) |
| Cache Size           | 1 KB (64 blocks × 16 bytes = 1024 bytes) |
| Index Bits           | 5 ($clog2(NUM_SETS) = 32 → 5) |
| Block Offset Bits    | 2 ($clog2(WORDS_PER_BLOCK) = 4 → 2) |
| Tag Width            | 25 bits |
| Valid Bit            | 1 per cache line |
| Dirty Bit            | 1 per cache line |
| Replacement Policy   | PLRU (Pseudo-LRU), maintained as a single bit per set |
| Cache Line Format    | {valid (1), dirty (1), tag (25), block (128 bits)} → total 155 bits per cache line |
| Data Storage         | 2D array: `cache[NUM_SETS][2]` (set-indexed, 2 ways per set) |

## 3- Top-Level Diagram (2-Way vs Direct-Mapped):
 Top level diagram almost remains the same, here is the brief overview:
### ***Inputs***:
- **req_type**: 0 = Read, 1 = Write (same as direct-mapped).

- **req_valid**: Indicates CPU request (same).

- **address [31:0]**: Physical address from CPU. (Difference: address now splits into Tag=25 bits, Index=5 bits, Offset=2 bits).

- **data_in [31:0]**: Data from CPU for write requests(same).

- **data_out_mem [127:0]**: 128-bit block from main memory (same).

- **clk, rst**: System clock and reset. 

### ***Outputs***

- **data_out [31:0]**: Word returned to CPU.(same)

- **done_cache:** Request completed.(same)

- **dirty_block_out [127:0]**: Block sent to memory on eviction.(same)

- **hit:** Indicates tag match in either way (different from direct-mapped where only 1 tag check existed).

## **4- Datapath (2-Way Overview)**:
### ***Similarities***:

- CPU sends requests (req_valid, req_type, address, data_in).

- Cache Decoder still splits address into {Tag, Index, Block Offset}.

- Cache Controller FSM still handles Compare → WriteBack → WriteAllocate → RefillDone states.

- Main memory interface unchanged: 128-bit transfers.

### ***Key Differences***:
1- **Tag Comparison:**

Direct-Mapped → 1 tag check per set.

2-Way → two parallel comparators, one for each way.

2- **Cache Storage:**

Direct-Mapped → cache[NUM_SETS] (one line per set).

2-Way → cache[NUM_SETS][2] (two lines per set).

3- **Replacement Policy:**

Direct-Mapped → No replacement needed (fixed slot).

2-Way → Pseudo-LRU (1 bit per set) decides which way to evict.

4- **Hit Signal:**

Direct-Mapped → hit = valid && (tag == stored_tag).

2-Way → hit = (hit_way0 || hit_way1).

## **5- Cache Controller (FSM Brief)**:
The FSM remains almost identical:

- **IDLE** → wait for req_valid.

- **COMPARE** →

   If hit → serve read/write.

   If miss + clean → fetch from memory.

  If miss + dirty → write-back old block.

- **WRITE_BAC**K → send dirty block to memory.

- **WRITE_ALLOCATE** → request new block from memory.

- **REFILL_DONE** → write block into cache, update PLRU, return to CPU.

## **Module-by-Module Explanation**:
### 1-  ***cache_decoder***:
 #### **Inputs:**

- clk, address [31:0]
#### **Outputs:**

- tag [24:0]

- index [4:0]

- blk_offset [1:0]
#### **Function:**
Splits the 32-bit CPU address into:

- tag (upper bits): sent to both way (contains 2 lines → way0 and way1).comparators.

- index (middle bits): selects the set (contains 5 bits to represent 32 sets)

- block offset (lowest bits): selects word within block.

### 2- Cache controller:
Cache controler module is exactly same as direct mapped cache.

### 3- Main Memory Interface:
main memory interface is also exactly the same as direct mapped cache.

### 4- Cache Memory module:
####  ***Inputs***:

- **clk** – system clock  
- **tag [TAG_WIDTH-1:0]** – extracted tag from CPU address  
- **index [INDEX_WIDTH-1:0]** – selects cache set  
- **blk_offset [OFFSET_WIDTH-1:0]** – selects word within block  
- **req_type** – 0 = Read, 1 = Write  
- **read_en_cache** – enables cache read (CPU-side)  
- **write_en_cache** – enables cache write (CPU-side)  
- **read_en_mem** – enables memory read (refill)  
- **write_en_mem** – enables memory write (eviction)  
- **data_in_mem [BLOCK_SIZE-1:0]** – new block from memory  
- **data_in [WORD_SIZE-1:0]** – single word from CPU  
- **refill** – indicates block replacement/refill operation

#### **Outputs**

- **dirty_block_out [BLOCK_SIZE-1:0]** – evicted dirty block (to memory)  
- **hit** – asserted if tag match in any way  
- **data_out [WORD_SIZE-1:0]** – word returned to CPU on read hit  
- **dirty_bit** – indicates dirty block present in current set  

#### **Internal Structures**

- **Cache Line Format** – `{valid, dirty, tag, block_data}`  
- **cache array** – `cache[NUM_SETS][2]` → 2 ways per set  
- **PLRU array** – `plru[NUM_SETS]` → 1-bit replacement info per set  
- **cache_info_t struct (info0, info1)** – Holds per-way signals: valid, dirty, tag, block, hit .
#### ***Functionality***:
##### i- **Hit/Miss Detection**

For each set, the two ways are checked in parallel:

- If the stored tag matches the CPU tag and valid bit = 1, that way asserts a hit.

- If neither way hits, a miss occurs and replacement must be performed. 

 ##### ii- **Replacement Policy – PLRU**

This design uses **Pseudo-LRU (PLRU)** instead of a true LRU to reduce hardware cost.

##### ***How PLRU Works in This Module***:
- Each set has a single **PLRU bit** (`plru[index]`)  
- This bit points to the victim candidate for the next replacement  
- **If `plru[index] = 0` → way-0** will be replaced on a miss  
- **If `plru[index] = 1` → way-1** will be replaced on a miss  
- Whenever a way is accessed (hit or refill), the PLRU bit **flips** to mark the other way as the future victim  

This ensures that the way least recently accessed is always chosen, but with only **1 bit per set** overhead.

##### ***Example Flow***:
1. CPU hits in **way-0** → `plru[index]` is set to `1` (so way-1 is next victim)  
2. Next miss in that set → **way-1** will be evicted  
3. If CPU then hits in **way-1** → `plru[index]` flips back to `0`  

Thus, PLRU approximates LRU but with far less storage.

##### iii-  **Miss Handling**

When a miss occurs:
- If **one way is invalid** → the block is refilled into that empty way  
- If **both are valid** → the PLRU victim way is chosen  
- If the victim is **clean** → directly overwritten  
- If the victim is **dirty** → the dirty block is written to memory first (`dirty_block_out`), then refilled with new data  



#### iv- **Read and Write Operations**

- **On a Read Hit**  
  - The requested word (`blk_offset`) is selected from the block and sent to `data_out`  
  - PLRU is updated to point to the other way  

- **On a Write Hit**  
  - The word is updated in place and marked **dirty**  
  - PLRU flips to mark the other way as next victim  

- **On a Miss**  
  - Memory is accessed, block is refilled, and PLRU is updated accordingly  

---

#### ***Why PLRU is Efficient Here***
- **Low cost** → Just one bit per set vs. full history bits in true LRU  
- **Good approximation** → Ensures alternate ways are reused fairly  
- **Hardware friendly** → Implemented as simple flip logic in always blocks  

✅ This makes **PLRU** the ideal replacement policy for small, low-complexity 2-way associative caches like this one.

## Testbench Documentation for `cache_memory`

### Purpose
The testbench (`cache_tb`) is designed to verify and validate the functionality of the `cache_memory` module.  
It systematically simulates read and write operations across multiple ways of a set-associative cache, verifying:

- Cache hit/miss detection  
- Dirty bit handling (clean vs. dirty evictions)  
- PLRU replacement policy operation during block eviction  
- Correct refill from memory on misses  

---

### 🔌 DUT Interface

#### Inputs
| **Signal**      | **Description** |
|------------------|-----------------|
| `clk`            | Clock signal (10ns period) |
| `tag`            | Tag field of the memory address |
| `index`          | Index selecting a cache set |
| `blk_offset`     | Word offset within the cache block |
| `req_type`       | Operation type: `0 = Read`, `1 = Write` |
| `read_en_cache`  | Read enable signal |
| `write_en_cache` | Write enable signal |
| `refill`         | Asserted to load a block from memory on miss |
| `data_in_mem`    | Full block data input from memory during refill |
| `data_in`        | Word-level data input for write operations |

#### Outputs
| **Signal**        | **Description** |
|--------------------|-----------------|
| `data_out`         | Word read from cache |
| `hit`              | High (`1`) if access is a hit, low (`0`) if miss |
| `dirty_bit`        | Dirty status of the selected cache block |
| `dirty_block_out`  | Block data to be written back to memory when evicted dirty |
| `done_cache`       | Operation done flag (optional) |

---

### ✅ Test Cases

#### 1. Read Hit
- **Setup**: Tag + index matches valid block in cache  
- **Action**: Assert `read_en_cache = 1`  
- **Expected**:  
  - `hit = 1`  
  - Correct `data_out` returned  
  - `dirty_bit` unchanged  
  - PLRU updated  

#### 2. Write Hit
- **Setup**: Matching tag + index entry exists  
- **Action**: Assert `write_en_cache = 1` with valid `data_in`  
- **Expected**:  
  - `hit = 1`  
  - Word updated in cache  
  - `dirty_bit = 1`  
  - PLRU updated  

#### 3. Read Miss (Clean Block in Set)
- **Setup**: Tag mismatch, chosen way is clean  
- **Action**: Trigger `read_en_cache = 1`, then assert `refill`  
- **Expected**:  
  - `hit = 0`  
  - Block replaced with `data_in_mem`  
  - `dirty_block_out` not used  
  - PLRU updated  

#### 4. Read Miss (Dirty Block Eviction)
- **Setup**: All ways valid, victim is dirty  
- **Action**: Assert `read_en_cache = 1`  
- **Expected**:  
  - `hit = 0`  
  - Evicted block on `dirty_block_out`  
  - Refetched data replaces it  
  - PLRU updated  

#### 5. Write Miss (Clean Victim Way)
- **Setup**: Victim way is clean  
- **Action**: Perform write after refill  
- **Expected**:  
  - Initial `hit = 0`  
  - Block refilled + word written  
  - `dirty_bit = 1`  
  - PLRU updated  

#### 6. Write Miss (Dirty Victim Way)
- **Setup**: Victim way is dirty  
- **Action**: Write request triggers eviction  
- **Expected**:  
  - Initial `hit = 0`  
  - `dirty_block_out` carries evicted block  
  - New block refilled + updated with `data_in`  
  - `dirty_bit = 1`  
  - PLRU updated  

#### 7. Compulsory Miss (Invalid Entry)
- **Setup**: Index not yet allocated  
- **Action**: First read to that set  
- **Expected**:  
  - `hit = 0`  
  - Line filled with `data_in_mem`  
  - `dirty_bit = 0`  
  - PLRU initialized  

#### 8. PLRU Replacement Behavior
- **Setup**: Fill all ways, then access subset  
- **Action**: Trigger miss requiring eviction  
- **Expected**:  
  - PLRU selects least-recently used way  
  - After replacement, PLRU state updated  

---

### 🌟 Features of the Testbench
- **Preloaded Cache Content**: Controlled initialization for targeted tests  
- **Cycle-by-Cycle Verification**: Uses `@(posedge clk)` for stepwise operations  
- **Readable Logs**: Shows hit/miss, dirty bit, PLRU victim, and cache state  
- **Waveform-Friendly**: Clear signal transitions for debugging



## Testing of integrated RTL modules:
[modular_integration](https://github.com/ee-uet/configurable-cache/tree/main/2-WAY%20SET_ASSOCIATIVE%20CACHE/modular_integration)












