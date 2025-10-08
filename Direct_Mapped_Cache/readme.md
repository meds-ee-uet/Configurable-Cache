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

<div align="center">
  <img src="TOP_BLOCK_LEVEL/CACHE_TOPLEVEL.png" width="600" height="400">
</div>



## **Inputs:**
| **Signal**    | **Width** | **Direction** | **Description**                           |
|---------------|-----------|---------------|-------------------------------------------|
| `req_type`    | 1 bit     | Input         | Request type: `0` = Read, `1` = Write     |
| `req_valid`   | 1 bit     | Input         | Indicates a valid request from CPU        |
| `address`     | 32 bits   | Input         | Address for read/write operation          |
| `data_in`     | 32 bits   | Input         | Data input from CPU (for writes)          |
| `data_out`    | 32 bits   | Output        | Data output to CPU (for reads)            |
| `data_in_mem` | 128 bits  | Input         | Cache line (block) fetched from memory    |
| `clk`         | 1 bit     | Input         | Clock signal                              |
| `rst`         | 1 bit     | Input         | Reset signal                              |

## **Outputs:**
| **Signal**        | **Width** | **Direction** | **Description**                                      |
|--------------------|-----------|---------------|------------------------------------------------------|
| `req_type`        | 1 bit     | Output        | Pass-through or processed request type (read/write)  |
| `address`         | 32 bits   | Output        | Address to memory or next stage                      |
| `dirty_blockout`  | 128 bits  | Output        | Dirty block sent to memory if eviction occurs        |

  

  

## **DataPath**
<div align="center">
  <img src="TOP_BLOCK_LEVEL/DATAPATH_CONTROLLER.png" width="600" height="400">
</div>






###  Datapath (Brief)


<div align="center">
  <img src="outputs/dataflow.png" width="600" height="400">
</div>




  ## ⚙️ Module-by-Module Explanation

### 1️⃣ `cache_decoder`
<div align="center">
  <img src="module_level/cache_decoder.png" width="600" height="400">
</div>




| **Port**      | **Width** | **Direction** | **Description**                                |
|---------------|-----------|---------------|------------------------------------------------|
| `clk`         | 1 bit     | Input         | Clock signal                                   |
| `address`     | 32 bits   | Input         | CPU address                                    |
| `tag`         | 24 bits   | Output        | Upper bits [31:8], used for tag comparison     |
| `index`       | 6 bits    | Output        | Bits [7:2], used to locate cache line          |
| `blk_offset`  | 2 bits    | Output        | Bits [1:0], used to select word within a block |


---



### 2️⃣ `cache_controller`
div align="center">
  <img src="module_level/CACHE_CONTROLLER.png" width="600" height="400">
</div>


### Inputs
| **Signal**        | **Width** | **Description**                         |
|--------------------|-----------|-----------------------------------------|
| `clk`             | 1 bit     | Clock signal                            |
| `rst`             | 1 bit     | Reset signal                            |
| `req_valid`       | 1 bit     | Indicates a valid CPU request           |
| `req_type`        | 1 bit     | Request type: `0` = Read, `1` = Write   |
| `hit`             | 1 bit     | Indicates if cache lookup resulted in hit |
| `dirty_bit`       | 1 bit     | Shows if the cache block is dirty       |
| `req_ready_mem`   | 1 bit     | Memory ready to accept a request        |
| `resp_valid_mem`  | 1 bit     | Memory response valid (data available)  |

### Outputs – Main Memory Interface
| **Signal**        | **Width** | **Description**                       |
|--------------------|-----------|---------------------------------------|
| `req_valid_mem`   | 1 bit     | Valid request to memory               |
| `resp_ready_mem`  | 1 bit     | Ready to accept response from memory  |
| `read_en_mem`     | 1 bit     | Enable memory read                    |
| `write_en_mem`    | 1 bit     | Enable memory write                   |

### Outputs – Cache Interface
| **Signal**        | **Width** | **Description**                       |
|--------------------|-----------|---------------------------------------|
| `read_en_cache`   | 1 bit     | Enable cache read                     |
| `write_en_cache`  | 1 bit     | Enable cache write                    |
| `write_en`        | 1 bit     | Write enable signal for cache block   |
| `refill`          | 1 bit     | Initiates cache refill                |
| `done_cache`      | 1 bit     | Indicates cache operation completion  |

### Function
| **Aspect**        | **Description**                                                                 |
|--------------------|---------------------------------------------------------------------------------|
| FSM States         | `IDLE`, `COMPARE`, `WRITE_BACK`, `WAIT_ALLOCATE`, `WRITE_ALLOCATE`, `REFILL_DONE` |
| Read/Write Hit     | CPU completes operation directly                                               |
| Miss – Clean Block | Refill cache from memory                                                       |
| Miss – Dirty Block | Write back to memory first, then refill                                        |
| Wait Cycle         | `WAIT_ALLOCATE` separates memory write and subsequent read                     |


---

##  FSM Explanation — Cache Controller

| **State**         | **Conditions**                                  | **Next State**        | **Actions**                                                          |
|-------------------|--------------------------------------------------|------------------------|----------------------------------------------------------------------|
| **IDLE**          | `req_valid = 1`                                  | `COMPARE`              | Wait for valid CPU request                                           |
| **COMPARE**       | `hit = 1`                                        | `IDLE`                 | Complete read/write, assert `done_cache`                            |
|                   | `!hit & !dirty_bit`                              | `WRITE_ALLOCATE`       | Clean miss: proceed to refill                                       |
|                   | `!hit & dirty_bit`                               | `WRITE_BACK`           | Dirty miss: write back required                                     |
| **WRITE_BACK**    | `req_ready_mem = 1`                              | `WAIT_ALLOCATE`        | Issue write-back to memory                                          |
| **WAIT_ALLOCATE** | (1-cycle wait after write-back)                  | `WRITE_ALLOCATE`       | Prevent overlap between write-back and refill request               |
| **WRITE_ALLOCATE**| `resp_valid_mem = 1`                             | `REFILL_DONE`          | Request memory read, refill cache when data arrives                 |
| **REFILL_DONE**   | -                                                | `IDLE`                 | Finalize refill; if write requested, perform CPU write after refill |

---

###  Key Points

- `WAIT_ALLOCATE` ensures **clean separation** between write-back and memory read (refill).
- `write_en_mem` is asserted only **during `WRITE_BACK`** when memory is ready.
- `read_en_mem` is asserted **during `WRITE_ALLOCATE`** when memory is ready.
- `write_en_cache` is used:
  - For **CPU write** in `COMPARE` (on hit) or in `REFILL_DONE` (after refill).
  - For **writing refill data** during `WRITE_ALLOCATE`.
- `done_cache` is asserted in `COMPARE` (on hit) and `REFILL_DONE`.


### 3️⃣ `cache_memory`
<div align="center">
<img src="module_level/CACHE_MEMORY.png" alt="Alt text" width="400"/>
</div>


### Inputs
| **Signal** |
|-------------|
| `clk`, `tag`, `index`, `blk_offset` |
| `req_type`, `read_en_cache`, `write_en_cache` |
| `ready_mem`, `data_in_mem [127:0]`, `data_in [31:0]` |

### Outputs
| **Signal** |
|-------------|
| `data_out [31:0]` (to CPU) |
| `dirty_block_out [127:0]` (to memory on write-back) |
| `dirty_bit`, `hit`, `done_cache` |

### Function
| **Description** |
|------------------|
| On **read hit**: sends required word to CPU. |
| On **write hit**: updates the word in the cache and sets the dirty bit. |
| On **miss**: |
| • Provides dirty block if necessary. |
| • Accepts new block from memory on refill. |

      


  ###  comparator 

  - Compares `tag` from CPU with stored `tag` in cache at `index`.
  - Checks valid bit.
  - **Outputs `hit` signal** if there is a valid match.



   ###  main_memory (abstract, if implemented)
  - Simulated using   random contents for testing.

---
### 🧾 Header File for Cache Specifications

A header file (`cache_defs.sv`) has been added to centralize the cache controller's specifications. It includes:

- FSM state definitions using `typedef enum`.
- Common parameters for consistency.
- Shared signal names and interface conventions.

🔧 **Purpose**: Improves modularity, avoids code duplication, and simplifies updates across modules.


## Testbenches
##  `cache_decoder_tb` Testbench

### 📌 Purpose

| **Field**       | **Bit Range** | **Description**                  |
|------------------|---------------|----------------------------------|
| `Tag`           | [31:8]        | Upper 24 bits used as cache tag  |
| `Index`         | [7:2]         | 6 bits used to select cache line |
| `Block Offset`  | [1:0]         | 2 bits used to locate word/byte  |


from a **32-bit address**, ensuring your cache’s address decoding logic is functioning correctly before integrating into the full cache pipeline.

###  Test Cases: 

### Basic Extraction Test

**Purpose:**  
To verify that `cache_decoder` correctly extracts **Tag, Index, and Block Offset** fields from a given 32-bit address.

#### 🛠 Inputs

| Signal   | Value                                                   |
|----------|----------------------------------------------------------|
| `address` | `32'b11011110101011011011111011101111` |

###  Expected Output:

---
#  Testbench: `tb_cache_controller_all_cases`

This SystemVerilog testbench is designed to **verify the behavior of a `cache_controller` module** under a comprehensive set of scenarios covering read and write requests, cache hits, and cache misses (both clean and dirty).

## 📌 Purpose

The main objective of this testbench is to validate that the `cache_controller` FSM transitions through all relevant states correctly and produces the expected control signals based on various cache request conditions.

It tests the controller under **six different scenarios**, checking state transitions and output signals for correctness.

---

## 🔌 DUT Interface

###  Inputs
| Signal         | Description                                    |
|----------------|------------------------------------------------|
| `clk`          | Clock signal (10ns period)                     |
| `rst`          | Reset signal (active high)                     |
| `req_valid`    | Cache request validity flag                    |
| `req_type`     | Type of request: `0 = Read`, `1 = Write`       |
| `hit`          | Indicates whether requested data is in cache   |
| `dirty_bit`    | Indicates if the cache block is dirty          |
| `req_ready_mem`| Main memory ready to receive request           |
| `resp_valid_mem`| Memory response is ready                      |

###  Outputs
| Signal            | Description                                   |
|-------------------|-----------------------------------------------|
| `req_valid_mem`   | Indicates if memory request is being sent     |
| `resp_ready_mem`  | Controller ready to accept memory response    |
| `read_en_mem`     | Read enable signal to memory                  |
| `write_en_mem`    | Write enable signal to memory                 |
| `read_en_cache`   | Read enable signal for cache                  |
| `write_en_cache`  | Write enable signal for cache                 |
| `write_en`        | Write enable (generic)                        |
| `refill`          | Signals when block is refilled from memory    |
| `done_cache`      | Indicates cache transaction is completed      |

---

##  Test Cases

Each test case triggers different controller states and prints internal FSM state and relevant I/O signals.

###  Test 1: Read Hit
- **Inputs:** `req_valid=1`, `req_type=0`, `hit=1`, `dirty_bit=0`
- **Expected:** Controller serves request directly from cache (`read_en_cache=1`), transitions to `IDLE`.

###  Test 2: Write Hit
- **Inputs:** `req_valid=1`, `req_type=1`, `hit=1`, `dirty_bit=0`
- **Expected:** Write directly to cache (`write_en_cache=1`), then return to `IDLE`.

###  Test 3: Read Miss (Clean)
- **Inputs:** `req_valid=1`, `req_type=0`, `hit=0`, `dirty_bit=0`
- **Expected FSM States:**
  - `COMPARE` → `WRITE_ALLOCATE` → wait for `resp_valid_mem` → `REFILL_DONE` → `IDLE`

### Test 4: Read Miss (Dirty)
- **Inputs:** `req_valid=1`, `req_type=0`, `hit=0`, `dirty_bit=1`
- **Expected FSM States:**
  - `COMPARE` → `WRITE_BACK` → `WAIT_ALLOCATE` → `WRITE_ALLOCATE` → `REFILL_DONE` → `IDLE`

###  Test 5: Write Miss (Clean)
- **Inputs:** `req_valid=1`, `req_type=1`, `hit=0`, `dirty_bit=0`
- **Expected FSM States:**
  - `COMPARE` → `WRITE_ALLOCATE` → `REFILL_DONE` → `IDLE`

###  Test 6: Write Miss (Dirty)
- **Inputs:** `req_valid=1`, `req_type=1`, `hit=0`, `dirty_bit=1`
- **Expected FSM States:**
  - `COMPARE` → `WRITE_BACK` → `WAIT_ALLOCATE` → `WRITE_ALLOCATE` → `REFILL_DONE` → `IDLE`

---



##  Expected Output

### Read Hit:


<div align="center">
<img src="outputs/readhit.png" alt="Alt text" width="400"/>
</div>

### Write hit:

<div align="center">
<img src="outputs/writehit.png" alt="Alt text" width="400"/>
</div>


### Read Miss Clean:

<div align="center">
<img src="outputs/readmissclean.png" alt="Alt text" width="400"/>
</div>

### Read Miss Dirty:

<div align="center">
<img src="outputs/readmissdirty.png" alt="Alt text" width="400"/>
</div>

### Write Miss CLean:

<div align="center">
<img src="outputs/writemissclean.png" alt="Alt text" width="400"/>
</div>

### Write Miss Dirty:

<div align="center">
<img src="outputs/writemissdirty.png" alt="Alt text" width="400"/>
</div>

### Snippet of Waves from Simulation:

<div align="center">
<img src="outputs/waveforcontroller.png" alt="Alt text" width="400"/>
</div>





 






---
#  Testbench: `cache_tb`

This SystemVerilog testbench is built to **verify and validate the functionality of the `cache_memory` module**, which simulates the data-handling behavior of a cache memory unit. It rigorously exercises read and write operations in both hit and miss scenarios, with detailed inspection of dirty bit behavior and memory refill.

---

##  Purpose

- To simulate and verify the correct behavior of the **cache memory unit** in handling various types of requests.
- To observe cache hits, misses (both clean and dirty), evictions, and refills from main memory.
- To check the internal structure of the cache, including **data storage**, **dirty bit updates**, and **data evictions**.

---

## 🔌 DUT Interface

###  Inputs

| Signal           | Description                                                         |
|------------------|---------------------------------------------------------------------|
| `clk`            | Clock signal (10ns period)                                          |
| `tag`            | Tag portion of the memory address                                   |
| `index`          | Index to select a specific cache block                              |
| `blk_offset`     | Offset to select word inside a block                                |
| `req_type`       | 0 = Read, 1 = Write                                                 |
| `read_en_cache`  | Enable signal for read operation                                    |
| `write_en_cache` | Enable signal for write operation                                   |
| `refill`         | Signal to trigger block refill from memory                          |
| `data_in_mem`    | Data coming from memory to cache (used during refill)               |
| `data_in`        | Word-level data input for write operations                          |

###  Outputs

| Signal             | Description                                                       |
|--------------------|-------------------------------------------------------------------|
| `data_out`         | Output word read from cache                                       |
| `hit`              | 1 if the cache access was a hit, 0 if it was a miss              |
| `dirty_bit`        | Indicates if the cache block has been modified                   |
| `dirty_block_out`  | Full block to be written back to memory on dirty eviction        |
| `done_cache`       | Operation done flag (optional usage)

---

##  Test Cases

The testbench runs a comprehensive set of operations designed to test key cache behaviors:

###  1. **Read Hit**
- **Setup:** Tag/index matches an initialized cache entry.
- **Action:** `read_en_cache = 1`
- **Expected:** `hit = 1`, `data_out` returns correct word, `dirty_bit` remains unchanged.

---

###  2. **Write Hit**
- **Setup:** Tag/index matches valid entry, write to word.
- **Action:** `write_en_cache = 1`, provide `data_in`.
- **Expected:** `hit = 1`, data updated in cache, `dirty_bit = 1`.

---

###  3. **Read Miss (Clean Block)**
- **Setup:** Cache line is clean and tag mismatch.
- **Action:** Trigger `read_en_cache`, then refill and write.
- **Expected:**
  - `hit = 0`, `dirty_bit = 0`
  - Block is replaced with new `data_in_mem`, no dirty eviction.

---

###  4. **Read Miss (Dirty Block)**
- **Setup:** Tag mismatch but line is dirty.
- **Action:** Trigger read, check `dirty_block_out`.
- **Expected:**
  - `hit = 0`, `dirty_bit = 1`
  - `dirty_block_out` holds block that would be evicted.

---

###  5. **Write Miss (Clean Block)**
- **Setup:** Index points to clean block with tag mismatch.
- **Action:** Write new data after refill.
- **Expected:**
  - Initial `hit = 0`
  - After refill and write, `dirty_bit = 1`

---

###  6. **Write Hit After Write Miss**
- **Setup:** After refill from write miss, same block written again.
- **Action:** `write_en_cache = 1`
- **Expected:** `hit = 1`, data written correctly, `dirty_bit = 1`

---

### 7. **Compulsory Read Miss (Empty/Invalid Entry)**
- **Setup:** Accessing an index not previously filled.
- **Action:** `read_en_cache = 1`, then refill.
- **Expected:**
  - `hit = 0`, block gets refilled.
  - `data_out` becomes valid after refill.

---

##  Features of the Testbench

- **Preloaded Cache Content:** Cache is initialized with valid binary blocks for controlled testing.
- **Cycle-by-Cycle Inspection:** Uses `@(posedge clk)` for synchronized operations.
- **Waveform-Friendly:** Internal cache content is printed after modifications.
- **Readable Logs:** Each test displays clear headers and results for `hit`, `dirty_bit`, and contents.

---

## Expected Output

 <div align="center">
<img src="outputs/READMISS.png" alt="Alt text" width="400"/>
</div>


<div align="center">
<img src="outputs/writemiss.png" alt="Alt text" width="400"/>
</div>

## Testing of integrated RTL modules:
[modular_integration](https://github.com/ee-uet/configurable-cache/tree/main/Direct_Mapped_Cache/modular_integration)

---
