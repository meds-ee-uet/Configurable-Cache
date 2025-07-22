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
<img src="https://github.com/meds-uet/Configurable_cache/blob/main/docs/CACHE_TOPLEVEL%20(1)-Page-3.png" alt="Alt text" width="400"/>
## **Inputs:**
- req_type : Whether you want to read(req_type=0) or write (req
- req_valid : to tell the cache that there is a request 
- address [31:0] : the adress where we want to read or write at 
- data_in [31 :0]
- data_out [31:0]
- data_in_mem[127:0]
- clk
- rst
## **Outputs:**  
- req_type
- address[32:0]
- dirty_blockout[128:0] 
  





