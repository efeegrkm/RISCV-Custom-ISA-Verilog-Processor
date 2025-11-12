# Custom 32-bit RISC-V Processor and LLVM Extension
@Author Efe Görkem AKKANAT


This repository details the development of a full-stack computer architecture solution: a specialized Instruction Set Architecture (ISA) extension for RISC-V, its integration into the LLVM compiler toolchain, and the Verilog implementation of a multi-cycle processor core that executes these custom instructions. [cite_start]This project was completed as part of the BIL361 – Computer Architecture and Organization course at TOBB University of Economics and Technology[cite: 5].

## Project Overview and Key Achievements

[cite_start]The project involved simultaneous development in software and hardware components for a custom 32-bit RISC-V processor[cite: 8].

* [cite_start]**Full Toolchain Integration:** Successfully extended the LLVM RISC-V backend to translate custom instructions (defined in Table 1 [cite: 11][cite_start]) from C (inline assembly) into machine code[cite: 35, 36].
* [cite_start]**Custom Multi-Cycle Core:** Designed a 32-bit multi-cycle RISC-V processor in Verilog HDL, supporting both base and custom instruction sets[cite: 249].
* [cite_start]**Variable Latency Execution:** Implemented a complex Control Unit to manage variable execution cycle counts for specialized instructions like `MAC.LD.ST`[cite: 261].
* [cite_start]**Little-Endian Handling:** The processor correctly handles instructions received in the little-endian format, matching the output of the custom LLVM compiler[cite: 270, 273].

---

## 1. LLVM ISA Extension (Software Component)

[cite_start]The LLVM 18.1.0 source code was modified to create a new RISC-V instruction extension, named `<Surname>`, enabling the generation of machine code for nine custom instructions[cite: 35, 53].

### Implementation Steps

1.  [cite_start]**Version Control:** Cloned the `llvm-project` repository and checked out the required commit version `461274b81d8641eab64d494accddc81d7db8a09e` (LLVM 18.1.0)[cite: 53, 55].
2.  [cite_start]**Custom Tools Build:** Built the necessary custom tools (`clang`, `llc`, `llvm-objdump`) configured specifically for the RISC-V backend[cite: 57, 58, 59].
3.  **Extension Definition:**
    * [cite_start]Defined the extension in `RISCVFeatures.td` (e.g., `def FeatureExt<Surname>`)[cite: 96, 97].
    * [cite_start]Created `RISCVInstrInfo<Surname>.td` to define all custom instructions using LLVM Target Description Language[cite: 36, 90].
    * [cite_start]Enabled the extension during compilation using the `-mattr=+<surname>` flag[cite: 190, 195].

### [cite_start]Defined Custom Instructions (See Table 2 for full functions [cite: 16])

| Instruction | Format Type | Opcode | Key Functionality |
| :--- | :--- | :--- | :--- |
| **`SUB.ABS`** | R-type | `1110111` | [cite_start]Absolute value subtraction[cite: 14, 16]. |
| **`MOVU`** | I-type | `1110111` | [cite_start]Writes unsigned extended immediate value to $rd$[cite: 14, 16]. |
| **`SRT.CMP.ST`** | R-type | `1110111` | [cite_start]Sorts and stores min/max values to memory addresses $rd$ and $rd+4$[cite: 14, 16]. |
| **`LD.CMP.MAX`** | R-type | `1110111` | [cite_start]Loads from three addresses and writes the maximum value to $rd$[cite: 14, 16]. |
| **`MAC.LD.ST`** | Custom-type2 | `1111111` | [cite_start]Load, Multiply, Accumulate, and Store operation repeated $s2+1$ times[cite: 14, 16]. |

---

## 3. Custom RISC-V Processor Core (Hardware Component)

[cite_start]A multi-cycle, 32-bit RISC-V processor was implemented in `<surname>.v` using Verilog behavioral modeling[cite: 249, 250].

### Core Architecture and State Management

[cite_start]The processor utilizes four stages: Fetch, Decode, Execute, and Writeback[cite: 259].

| Stage | Default Cycles | State Value (`cur_stage_o`) |
| :--- | :--- | :--- |
| **Fetch** | 1 | [cite_start]`0` [cite: 270] |
| **Decode** | 1 | [cite_start]`1` [cite: 270] |
| **Execute** | Variable (Min 1, Max $4\times(s2+1)$) | [cite_start]`2` [cite: 270] |
| **Writeback** | 1 | [cite_start]`3` [cite: 270] |

### Variable Execution Latency

[cite_start]The Control Unit manages the cycle count for complex instructions[cite: 261]:

* [cite_start]**`SRT.CMP.ST`:** Execute stage takes **2 cycles** (5 total cycles)[cite: 261].
* [cite_start]**`LD.CMP.MAX`:** Execute stage takes **3 cycles** (6 total cycles)[cite: 261].
* [cite_start]**`MAC.LD.ST`:** Execute stage takes **$(s2 + 1) \times 4$ cycles**[cite: 261, 263].

### [cite_start]Module Interface (Table 3 Excerpt [cite: 269])

| Signal | Direction | Width |
| :--- | :--- | :--- |
| `clk_i` | Input | 1 bit |
| `rst_i` | Input | 1 bit |
| `inst_i` | Input | [cite_start]32 bits (Little-Endian) [cite: 270, 273] |
| `pc_o` | Output | 32 bits |
| `regs_o` | Output | $32 \times 32$ bits |
| `data_mem_rdata_i` | Input | 32 bits |
| `data_mem_wdata_o` | Output | 32 bits |

---

## 4. Documentation

[cite_start]Detailed architectural documentation is provided, including a hand-drawn (or digital) datapath diagram and the complete truth table for the Control Unit, saved as `<Akkanat>.pdf`[cite: 274, 275, 276].
