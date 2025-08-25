# Integrated RTL - 2-way Set-associative Cache

This project contains the **integrated RTL design** of a 2-Way Set-Associative Cache.  
In this version, I have combined all the individual modules (cache memory, controller, decoder, PLRU replacement logic, etc.) into a single top-level RTL file.  

After integration, I ran and verified the design against **all test cases**, including:
- **Read Hit**
- **Write Hit**
- **Read Miss**
- **Write Miss**
- **Dirty Block Eviction & Refill**

The integrated design successfully passed all these scenarios.

## Contents
- `rtl/` → Integrated RTL code  
- `tb/` → Testbench files  

## How to Run
1. Compile the RTL and testbench in your simulator (e.g., QuestaSim, Verilator, VCS).  
2. Run the testbench to validate functionality.  
3. View waveforms for detailed verification.  

---
✅ **Status:** All test cases verified successfully
