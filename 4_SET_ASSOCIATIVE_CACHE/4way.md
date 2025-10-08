# 4-Way Set-Associative Cache

## 1. Overview

A **4-Way Set-Associative Cache** is a cache memory organization where each set contains four cache lines. Compared to a 2-way set-associative cache, it provides even more placement flexibility, further reducing conflict misses and improving cache hit rates for workloads with frequent memory reuse.

### Structure

- **Cache Division**: The cache is divided into multiple sets, each containing four cache lines.
- **Address Breakdown**: A memory address is divided into three parts:
  - **Tag**: Identifies the specific block in memory.
  - **Set Index**: Determines which set the data might reside in.
  - **Block Offset**: Specifies the exact location within the cache line.

### Operation

When a memory request is made:

1. The **Set Index** part of the address is used to select a set.
2. All four cache lines within the selected set are checked for a match using the **Tag**.
3. If any line contains the requested data, it is a cache hit; otherwise, it is a miss, and the data is fetched from main memory.

### Comparison with 2-Way Set-Associative Cache

| Feature               | 2-Way Set-Associative Cache | 4-Way Set-Associative Cache |
|-----------------------|-----------------------------|-----------------------------|
| Cache Lines per Set    | 2                           | 4                           |
| Placement Flexibility  | Moderate (2 choices per set)| Higher (4 choices per set) |
| Conflict Misses        | Low                         | Lower                       |
| Hardware Complexity    | Moderate                    | Higher                      |
| Performance            | Good for many access patterns| Better for high-conflict access patterns |

### Benefits Over 2-Way Set-Associative Cache

- **Further Reduced Conflict Misses**: More options for placing memory blocks within a set reduces the chance of cache conflicts.
- **Improved Cache Hit Rate**: Especially beneficial for programs with repeated accesses to multiple memory addresses that map to the same set.
- **Better Performance for Complex Workloads**: Handles high-frequency accesses more efficiently without dramatically increasing the cache size.

## 2- Specifications of Our 4-Way Set Associative Cache:



| **Parameter**        | **Value (from code)** |
|-----------------------|------------------------|
| Word Size            | 32 bits (per word) |
| Words per Block      | 4 words |
| Block Size           | 128 bits (16 bytes per block) |
| Number of Blocks     | 64 (total cache lines across all sets & ways) |
| Associativity        | 4-way (each set holds 4 cache lines) |
| Number of Sets       | 16 sets (NUM_BLOCKS / NUM_WAYS) |
| Cache Size           | 1 KB (64 blocks × 16 bytes = 1024 bytes) |
| Index Bits           | 4 ($clog2(NUM_SETS) = 16 → 4) |
| Block Offset Bits    | 2 ($clog2(WORDS_PER_BLOCK) = 4 → 2) |
| Tag Width            | 26 bits |
| Valid Bit            | 1 per cache line |
| Dirty Bit            | 1 per cache line |
| Replacement Policy   | PLRU (Pseudo-LRU), maintained as a single bit per set |
| Cache Line Format    | {valid (1), dirty (1), tag (26), block (128 bits)} → total 156 bits per cache line |
| Data Storage         | 2D array: `cache[NUM_SETS][4]` (set-indexed, 4 ways per set) |

## 3- Top-Level Diagram (4-Way vs Direct-Mapped):
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

## **4- Datapath (4-Way Overview)**:
### ***Similarities***:

- CPU sends requests (req_valid, req_type, address, data_in).

- Cache Decoder still splits address into {Tag, Index, Block Offset}.

- Cache Controller FSM still handles Compare → WriteBack → WriteAllocate → RefillDone states.

- Main memory interface unchanged: 128-bit transfers.

### ***Key Differences***:
1- **Tag Comparison:**

Direct-Mapped → 1 tag check per set.

2-Way → two parallel comparators, one for each way.

4-Way → four parallel comparators, one for each way.

2- **Cache Storage:**

Direct-Mapped → cache[NUM_SETS] (one line per set).

2-Way → cache[NUM_SETS][2] (two lines per set).

4-Way → cache[NUM_SETS][4] (four lines per set).

3- **Replacement Policy:**

Direct-Mapped → No replacement needed (fixed slot).

2-Way → Pseudo-LRU (1 bit per set) decides which way to evict.

4-Way → Pseudo-LRU (1 bit per set) decides which way to evict.

4- **Hit Signal:**

Direct-Mapped → hit = valid && (tag == stored_tag).

2-Way → hit = (hit_way0 || hit_way1).

4-Way → hit = (hit_way0 || hit_way1 || hit_way2 || hit_way3).

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

- tag [25:0]

- index [3:0]

- blk_offset [1:0]
#### **Function:**
Splits the 32-bit CPU address into:

- tag (upper bits): sent to all ways (contains 4 lines → way0, way1, way2, way3).comparators.

- index (middle bits): selects the set (contains 4 bits to represent 16 sets)

- block offset (lowest bits): selects word within block.

### 2- Cache controller:
Cache controler module is exactly same as direct mapped cache & 2-way set-associative cache.

### 3- Main Memory Interface:
main memory interface is also exactly the same as direct mapped cache & 2-way set-associative cache.

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
- **cache array** – `cache[NUM_SETS][4]` → 4 ways per set  
- **PLRU array** – `plru[NUM_SETS]` → 3-bit replacement info per set (tree-based PLRU)
- **cache_info_t struct (info0, info1, info2, info3)** – Holds per-way signals: valid, dirty, tag, block, hit .
#### ***Functionality***:
##### i- **Hit/Miss Detection**

For each set, the four ways are checked in parallel:

- If the stored tag matches the CPU tag and valid bit = 1, that way asserts a hit.

- If neither way hits, a miss occurs and replacement must be performed. 

 ##### ii- **Replacement Policy – PLRU**

This design uses **Pseudo-LRU (PLRU)** instead of a true LRU to reduce hardware cost.

##### ***How PLRU Works in This Module***:
- Each set maintains **3 PLRU bits** (`plru[index].b1`, `plru[index].b2`, `plru[index].b3`).
- These bits form a **binary tree** that encodes the least-recently-used (LRU) way.
- **Victim selection on miss**:
  - `b1` decides which subtree to evict from:
    - `0` → go left subtree (ways 0–1)
    - `1` → go right subtree (ways 2–3)
  - If left subtree chosen:
    - `b2=0` → victim = way-0
    - `b2=1` → victim = way-1
  - If right subtree chosen:
    - `b3=0` → victim = way-2
    - `b3=1` → victim = way-3
- **Update on access (hit or refill)**:
  - When a way is accessed, the tree bits are updated so that this way becomes **most recently used (MRU)**.
  - The tree is flipped to point toward another way as the **next replacement candidate**.

This approximates true LRU with only **3 bits per set**, instead of maintaining full access history.

##### ***Example Flow***:
1. CPU hits in **way-0** → PLRU tree updates (`b1=1, b2=1`) so that way-0 is marked MRU, and another way (way-1 or from the right subtree) becomes the next victim.
2. Next miss in that set → Victim is chosen by traversing the PLRU tree. For example, if `b1=1, b3=0`, then **way-2** will be evicted.
3. If CPU then hits in **way-2** → PLRU tree updates (`b1=0, b3=1`) so that way-2 is MRU, and another way (e.g., way-0, way-1, or way-3) becomes the next victim.

Thus, Tree-PLRU approximates true LRU with only **3 bits per set**, instead of storing full history.

##### iii-  **Miss Handling**

When a miss occurs:
- If **any way is invalid** → the block is refilled into the first invalid way  
- If **all 4 ways are valid** → the PLRU victim way is chosen  
- If the victim is **clean** → it is directly overwritten with the new block  
- If the victim is **dirty** → the dirty block is written back to memory first (`dirty_block_out`), then the new block is refilled into that way



#### iv- **Read and Write Operations**



- **On a Read Hit**  
```systemverilog
if (hit) begin
    data_out = cache[set][hit_way].block[blk_offset];  
    // update PLRU for this set
    plru[set] = update_plru(plru[set], hit_way);
end
```


-   **On a Write Hit** 
```systemverilog 
 if (hit) begin
    cache[set][hit_way].block[blk_offset] = data_in;
    cache[set][hit_way].dirty = 1'b1;  
    // update PLRU for this set
    plru[set] = update_plru(plru[set], hit_way);
end
```
- **On a Miss**  
```systemverilog 
  if (miss) begin
    if (exists_invalid_way(set)) begin
        victim_way = get_invalid_way(set);
    end else begin
        victim_way = get_plru_victim(plru[set]);
    end
    
    if (cache[set][victim_way].dirty) begin
        // write back dirty block to memory
        dirty_block_out = cache[set][victim_way].block;
        write_back_to_mem(tag, set, cache[set][victim_way]);
    end
    
    // refill from memory
    cache[set][victim_way].block = read_block_from_mem(address);
    cache[set][victim_way].valid = 1'b1;
    cache[set][victim_way].dirty = is_write ? 1'b1 : 1'b0;

    // update PLRU
    plru[set] = update_plru(plru[set], victim_way);
end
  
```
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



