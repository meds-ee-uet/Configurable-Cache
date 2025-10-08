# ***CONFIGURABLE CACHE***
# Configurable Cache (SystemVerilog Implementation)

> **Parametric, synthesizable cache design with configurable associativity, block size, and replacement policies for learning and embedded systems.**

🗓️ Last updated: July 22, 2025  
© 2025 Maktab-e-Digital Systems Lahore. Licensed under the Apache 2.0 License.

---

##  Table of Contents
- [Project Overview](#project-overview)
- [Objective](#objective)
- [Our Strategy](#our-strategy)
- [For Testing](#for-testing)
- [Direct Mapped Cache](../readme.md)
- [2-Way Set-Associative Cache](https://github.com/meds-ee-uet/Configurable-Cache/blob/main/2-WAY%20SET_ASSOCIATIVE%20CACHE/README2.md)
- [4-Way Set-Associative Cache](https://github.com/meds-ee-uet/Configurable-Cache/blob/main/4_SET_ASSOCIATIVE_CACHE/README.md)
- [N-Way CONFIGURABLE Set-Associative Cache](https://github.com/meds-ee-uet/Configurable-Cache/tree/main/configurable(n-way)_set-associative_cache#readme)
- [Synthesization of RTL](#synthesization-of-rtl)
- [Summary](#Summary)
- 
## **PROJECT OVERVIEW**:
This project implements a direct-mapped cache,2-way set associative cache,4-way set associative cahe and configurable (n-way)set associative cache controller with support for basic memory transactions. It simulates how a CPU communicates with memory via a cache to reduce access latency and improve performance. 
## OBJECTIVE:
The primary objectives of this project are:
1. **Design a Configurable Cache Architecture**: 
To build a cache system that is modular and configurable, supporting different associativity levels:
- Direct-mapped cache
- 2-way set associative cache
- 4-way set associative cache
- n-way set associative cache
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

## For Testing:
We started from testing our RTL module by module to check their functionality, and then we integrated all the modules. Later, we tested them again for each cache, starting from direct-mapped cache.





## Synthesization of RTL:
we synthesized RTL on Vivado to check its compatibility with hardware implementation by analyzing the utilization report.
[synthesis_vivado](https://github.com/ee-uet/configurable-cache/tree/388368cb34323a59cb31c21528f4e31c361c0388/synthesis_vivado)

## Summary 


In this documentation, the **datapath** and **controller diagrams** have been provided only for the **Direct-Mapped Cache**.  
This was done because the **core architecture** and **control logic** remain **identical** across all cache configurations — from **Direct-Mapped** to **N-Way Configurable Caches**.

A **common cache controller** was designed to be used across all versions.  
It is responsible for handling operations such as read, write, cache miss detection, write-back, and refill through the same **finite state machine (FSM)**.

The **primary difference** among cache configurations lies within the **cache memory module**, where the **associativity** and **replacement policy** are varied.  
While the Direct-Mapped Cache contains a single line per set, multi-way caches (such as 2-way or N-way) perform **parallel tag comparisons** and utilize the **PLRU (Pseudo-Least Recently Used)** replacement policy to determine which block should be replaced during a miss.

Hence, the explanation and diagrams of the **Direct-Mapped Cache** serve as the conceptual foundation for understanding all **higher-associativity caches** implemented in this project.

























  





