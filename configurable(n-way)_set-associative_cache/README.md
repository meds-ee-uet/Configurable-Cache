# 🧠 N-WAY CONFIGURABLE CACHE

## 1. What is an N-Way Set Associative Cache?
An **N-way set associative cache** is a flexible design where each memory block can map to one of several lines (ways) within a specific set.  
The cache index selects the set, and within that set, **N tag comparisons** occur in parallel.  
If all lines are full, a **replacement policy** (like PLRU) decides which line to evict.

By adjusting `NUM_WAYS`, the same design can behave as:
- **Direct-Mapped** (`NUM_WAYS = 1`)
- **2-Way / 4-Way / 8-Way** Set-Associative Cache, etc.

---

## 2. Specifications of Our Configurable Cache

| **Parameter** | **Value (Default)** | **Description** |
|----------------|---------------------|-----------------|
| Word Size | 32 bits | Each word is 4 bytes |
| Words per Block | 4 | 16 bytes per cache block |
| Block Size | 128 bits | (4 × 32-bit words) |
| Total Blocks | 64 | Cache lines across all sets and ways |
| Associativity | Configurable (N-way) | e.g., 1, 2, 4, 8 |
| Number of Sets | `NUM_BLOCKS / NUM_WAYS` | Derived from configuration |
| Index Bits | `$clog2(NUM_SETS)` | Selects which set |
| Block Offset Bits | `$clog2(WORDS_PER_BLOCK)` | Selects word inside block |
| Tag Width | `ADDR_WIDTH - INDEX_BITS - OFFSET_BITS` | Identifies memory block |
| Valid & Dirty Bits | 1 each per cache line | Track usage and modification |
| Replacement Policy | PLRU | Pseudo-LRU for all sets |
| Cache Line Format | `{valid, dirty, tag, data_block}` | Stored per line |

---

## 3. Functional Overview

### **Inputs**
- `req_valid`, `req_type` → CPU request control (read/write)
- `address [31:0]` → Physical address from CPU
- `data_in [31:0]` → Data from CPU (write operations)
- `data_in_mem [127:0]` → Block fetched from memory
- `clk`, `rst` → Clock and reset

### **Outputs**
- `data_out [31:0]` → Word returned to CPU
- `done_cache` → Operation complete flag
- `dirty_block_out [127:0]` → Evicted block on write-back
- `hit` → High when tag matches in any way

---

## 4. Key Operation
1. **Address Decode:** Address is split into {Tag, Index, Offset}.  
2. **Parallel Tag Comparison:** All ways in the indexed set are checked for a match.  
3. **Hit:** Matching way provides data immediately.  
4. **Miss:** PLRU selects a victim way for replacement.  
   - If **dirty**, write back to memory.  
   - If **clean**, directly refill from memory.  
5. **PLRU Update:** Marks the accessed way as most recently used.

---

## 5. Why Configurable?
This cache design allows easy **experimentation** with cache parameters:
- Explore trade-offs between hit rate and hardware cost.
- Simulate real-world cache behavior under various architectures.
- Same RTL supports **Direct-Mapped**, **2-Way**, **4-Way**, or **8-Way** setups with simple parameter changes.

---

✅ **In short:**  
This N-way configurable cache offers a **scalable**, **synthesizable**, and **educational** platform to understand modern cache memory architectures using SystemVerilog.
