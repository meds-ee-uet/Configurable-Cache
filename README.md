# ***CONFIGURABLE CACHE***
# Configurable Cache (SystemVerilog Implementation)

> **Parametric, synthesizable cache design with configurable associativity, block size, and replacement policies for learning and embedded systems.**

🗓️ Last updated: July 22, 2025  
© 2025 Maktab-e-Digital Systems Lahore. Licensed under the Apache 2.0 License.

---















## **PROJECT OVERVIEW**:
This project implements a direct-mapped cache controller with support for basic memory transactions. It simulates how a CPU communicates with memory via a cache to reduce access latency and improve performance. 

## OBJECTIVE:
The primary objectives of this project are:

1. **Design a Configurable Cache Architecture**: 
To build a cache system that is modular and configurable, supporting different associativity levels:

- Direct-mapped cache

- 2-way set associative cache

- 4-way set associative cache

2. **Explore Cache Organization Techniques**: 
To understand and implement multiple cache configurations, comparing their behavior and performance in handling memory access patterns.

3. **Implement Cache Controller Using FSM-Based Logic**: 
To develop a finite state machine (FSM) that manages cache operations such as:

- Cache hit/miss detection

- Block replacement (e.g., using LRU for set-associative caches)

- Write-back of dirty blocks

- Memory refill and synchronization with main memory

- Support Both Read and Write Accesses with Replacement Policies
To implement logic that handles:

- Read and write requests from a simulated CPU

- Write-back on dirty evictions

- Write-allocate and read-allocate refill policies

- LRU replacement policy in associative caches

## ***OUR STRATEGY***:
We decided to move from basic fundamentals to higher level. So, we implemented a direct mapped cache first. Then we will move our approach to set associative cache mapping.

## ***DIRECT MAPPED CACHE***:
 #### **What is a cache?**
In modern computer systems, cache memory serves as a small, fast memory layer between the CPU and the slower main memory (RAM). It stores frequently accessed data and instructions to reduce access latency and improve overall system performance.

- When the CPU needs data, it first checks the cache:

- If the data is found, it’s a cache hit (faster access).

- If not, it’s a cache miss, and the data is fetched from main memory and placed in the cache.

####  **Types of Cache Mapping**:
There are three primary techniques to map memory blocks to cache lines:

- Direct-Mapped Cache: 
Each memory block maps to exactly one cache line.
It is  Simple and fast but there is Higher chance of conflict misses.

- Fully Associative Cache: 
Any memory block can go into any cache line. It is Very flexible
but Expensive and slower to implement (requires searching all tags)

- Set-Associative Cache: 
A compromise between the above two: the cache is divided into sets, and each set has multiple ways (lines). It Balances between cost and flexibility and  is Slightly more complex than direct-mapped

### **What is a Direct-Mapped Cache?**
A direct-mapped cache maps each memory block to exactly one cache line using the index bits derived from the memory address. 

### **Specifications of Our Direct-Mapped Cache:**
Our first implementation is a direct-mapped cache with the following configuration:

| **Parameter**       | **Value**             |
|---------------------|------------------------|
| Cache Size          | 1 KB (1024 bytes)      |
| Block Size          | 128 bits (16 bytes)    |
| Line Size           | 64 lines               |
| Tag Bits            | 24 bits                |
| Valid Bit           | 1 bit                  |
| Dirty Bit           | 1 bit                  |
| Total Bits/Line     | 154 bits               |  

## **TOP LEVEL DIAGRAM**:
<img src="https://github.com/meds-uet/Configurable_cache/blob/main/docs/TOP_BLOCK_LEVEL/CACHE_TOPLEVEL%20.drawio.png" alt="Alt text" width="400"/>

## **Inputs:**
- `req_type`: Whether you want to read (`req_type = 0`) or write.
- `req_valid`: Tells the cache there is a request.
- `address [31:0]`: Address where you want to read or write.
- `data_in [31:0]`: Data input from CPU.
- `data_out [31:0]`: Data output to CPU.
- `data_in_mem [127:0]`: Data input from memory.
- `clk`: Clock.
- `rst`: Reset.

## **Outputs:**
- `req_type`: (pass-through or processed based on your design).
- `address [31:0]`: Address to memory or next stage.
- `dirty_blockout [127:0]`: The dirty block sent to memory if eviction occurs.

  

## **DataPath **
<img src="https://github.com/meds-uet/Configurable_cache/blob/main/docs/TOP_BLOCK_LEVEL/DATAPATH_CONTROLLER.drawio.png" alt="Alt text" width="400"/>





### 🛠️ Datapath (Brief)

- CPU sends `req_valid`, `req_type`, `address [31:0]`, `data_in [31:0]` (for writes).
- **Cache Decoder** splits the address into `tag`, `index`, `block offset`.
- **Comparator** checks if the `tag` matches and valid bit is set, generating `hit`.
- **Cache Controller**:
  - Decides actions based on `hit`, `dirty_bit`, `req_type`, `ready_mem`.
  - Generates control signals (`read_en_cache`, `write_en_cache`, `refill`, etc.).
- **Cache Memory**:
  - **Read hit**: sends `data_out [31:0]` to CPU.
  - **Write hit**: updates the block and sets dirty bit.
  - **Miss**: may write back dirty block (`dirty_block_out [127:0]`) and refill (`data_in_mem [127:0]`).
- **Main Memory** provides/accepts 128-bit blocks for refill or write-back using handshake signals.


  ## ⚙️ Module-by-Module Explanation

### 1️⃣ `cache_decoder`
- **Inputs**: `clk`, `address [31:0]`
- **Outputs**: 
  - `tag [23:0]`
  - `index [5:0]`
  - `blk_offset [1:0]`
- **Function**: Splits the 32-bit CPU address into:
  - `tag` (upper bits) for comparison
  - `index` to locate the cache line
  - `block offset` to select the word in the block

---

### 2️⃣ `comparator` (if separate)
- Compares `tag` from CPU with stored `tag` in cache at `index`.
- Checks valid bit.
- **Outputs `hit` signal** if there is a valid match.

---

### 3️⃣ `cache_controller`
- **Inputs**: `clk`, `rst`, `req_valid`, `req_type`, `hit`, `dirty_bit`, `ready_mem`
- **Outputs**: control signals
  - `read_en_mem`, `write_en_mem`
  - `read_en_cache`, `write_en_cache`
  - `refill`, `done_cache`
- **Function**:
  - Implements FSM (`IDLE`, `COMPARE`, `WRITE_BACK`, `WRITE_ALLOCATE`).
  - On **read/write hit**: allows CPU to proceed.
  - On **miss**:
    - If clean: initiates refill.
    - If dirty: performs write-back before refill.

---

### 4️⃣ `cache_memory`
- **Inputs**:
  - `clk`, `tag`, `index`, `blk_offset`
  - `req_type`, `read_en_cache`, `write_en_cache`
  - `ready_mem`, `data_in_mem [127:0]`, `data_in [31:0]`
- **Outputs**:
  - `data_out [31:0]` (to CPU)
  - `dirty_block_out [127:0]` (to memory on write-back)
  - `dirty_bit`, `hit`, `done_cache`
- **Function**:
  - On **read hit**: sends required word to CPU.
  - On **write hit**: updates the word in the cache and sets the dirty bit.
  - On **miss**:
    - Provides dirty block if necessary.
    - Accepts new block from memory on refill.

---

### 5️⃣ `main_memory` (abstract, if implemented)
- Provides/receives 128-bit blocks during cache refill and write-back.
- Uses handshake signals (`read_en_mem`, `write_en_mem`, `ready_mem`) with the cache.
- Simulated using a memory model with preloaded data or random contents for testing.

---







  





