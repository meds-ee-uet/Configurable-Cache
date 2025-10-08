<p align="center">
  <img src="/Direct_Mapped_Cache/docs/meds_uet_logo.png"  width="120">
</p>


# ***CONFIGURABLE CACHE***
## 📘 Table of Contents
- [Overview](#configurable-cache-systemverilog-implementation)
- [License](#license)
- [Top Level Diagram](#top-level-diagram)
- [Directory Structure](#-directory-structure)
- [User Guide](#-user-guide)
  - [Directory Overview](#-directory-overview)
  - [Address Decoder Configuration](#️-address-decoder-configuration)
  - [Parameter Configuration](#-parameter-configuration)
  - [Documentation](#Documentation)

---
# Configurable Cache (SystemVerilog Implementation)

> **Parametric, synthesizable cache design with configurable associativity, block size, and replacement policies for learning and embedded systems.**


# ***LICENSE***
🗓️ Last updated: July 22, 2025  
© 2025 Maktab-e-Digital Systems Lahore. Licensed under the Apache 2.0 License.

---


# ***TOP LEVEL DIAGRAM***
<p align="center">
  <img src="/Direct_Mapped_Cache/docs/TOP_BLOCK_LEVEL/CACHE_TOPLEVEL.png"  width="360">
</p>
## 📁 Directory Structure

```
cache-project/
│
├── direct-mapped-cache/
│   ├── docs/
│   ├── rtl/
│   ├── testbench/
│   └── modular-integration/
│       ├── rtl/
│       └── testbench/
│
├── 2-way-set-associative-cache/
│   ├── docs/
│   ├── rtl/
│   ├── testbench/
│   └── modular-integration/
│       ├── rtl/
│       └── testbench/
│
├── 4-way-set-associative-cache/
│   ├── rtl/
│   ├── testbench/
│   └── modular-integration/
│       ├── rtl/
│       └── testbench/
│
└── configurable-n-way-set-associative-cache/
    ├── rtl/
    ├── testbench/
    └── modular-integration/
        ├── rtl/
        └── testbench/
```

## 🧭 User Guide

The **Configurable_N_Way_Set_Associative_Cache** directory provides a flexible and parameterized implementation of a cache memory system.  
It allows users to easily configure the **cache associativity (number of ways)**, **address width**, **block size**, and other key architectural parameters.

### 📂 Directory Overview

Inside the `Configurable_N_Way_Set_Associative_Cache/` directory, you’ll find:

- **`rtl/`** – Contains the main SystemVerilog source files for the configurable cache design.  
- **`testbench/`** – Includes verification modules and simulation files.  
- **`modular_integration/`** – Provides integrated RTL and testbench files for modular simulation and synthesis.

---

### ⚙️ Address Decoder Configuration

In the `rtl/` folder, you will find a file named **`decoders.sv`**, which contains address decoding logic for multiple cache configurations:

- **2-way set associative cache**  
- **4-way set associative cache**  
- **8-way set associative cache**  
- **12-way set associative cache**

Each decoder is implemented within the same file for convenience.  
You can **comment out the decoders** that you are not using and **enable only the one** corresponding to your desired associativity.  
This approach makes the cache module adaptable while keeping all decoding options in one place.

---

### 🧩 Parameter Configuration

A dedicated **header file** is included to make the design customizable.  
This file defines important parameters that can be modified according to your system’s requirements.

Below is the example of parameters you can edit:

```systemverilog
parameter int NUM_WAYS         = 4; // Must be a power of 2 (e.g., 2, 4, 8, 16)
```
### Documentation
[Documentation Status](https://repo-k.readthedocs.io/en/latest/)
