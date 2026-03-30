# Pipelined 8-bit ALU with Wallace Multiplier and Division FSM

## 📌 Overview

This project implements a **4-stage pipelined 8-bit ALU** in Verilog with mixed-latency execution units. The design integrates fast combinational operations, a **carry-save (CSA) based pipelined multiplier**, and a **multi-cycle restoring division FSM**, with proper result-valid synchronization and flag alignment.

---

## ⚙️ Key Features

* 4-stage pipeline (Input → Compute → Select → Output)
* Fast ALU operations (ADD, SUB, AND, OR, XOR, SHIFT)
* Pipelined multiplier using **carry-save reduction (Wallace-class)**
* Multi-cycle restoring division FSM
* Valid/ready signaling for mixed-latency operations
* Flag support: Zero (Z), Carry (C), Sign (S), Overflow (V)
* Fully synthesizable RTL (Vivado-compatible)

---

## 🏗️ Architecture

The design separates execution units and aligns outputs through a final selection stage:

* **Stage 1:** Input latch (A, B, opcode, vin)
* **Stage 2:** Fast ALU operations + intermediate flags
* **Parallel Units:**

  * Multiplier → pipelined CSA reduction
  * Divider → FSM-based iterative division
* **Stage 3:** Result selection (MUX based on opcode + valid signals)
* **Stage 4:** Output register + flag generation

---

## 🔢 Supported Operations

| Opcode | Operation                       |
| ------ | ------------------------------- |
| 0      | ADD                             |
| 1      | SUB                             |
| 2      | AND                             |
| 3      | OR                              |
| 4      | XOR                             |
| 5      | Shift Left                      |
| 6      | Shift Right                     |
| 7      | Multiply (Wallace/CSA pipeline) |
| 8      | Divide (FSM)                    |

---

## 🧠 Design Highlights

* Uses **carry-save accumulation** to avoid long carry propagation in multiplication
* Demonstrates **heterogeneous latency handling** within a unified pipeline
* Implements **valid signal propagation** to correctly align outputs
* Clean separation of datapath and control logic

---

## 📊 Performance Characteristics

* Fast operations: ~1–2 cycles latency
* Multiplication: ~3-cycle pipeline latency (1 result/cycle throughput)
* Division: ~8-cycle latency (FSM-based)

---

## 📷 Waveform / Simulation Output

<img width="1558" height="721" alt="image" src="https://github.com/user-attachments/assets/3ee93057-523b-4e0c-b004-d3446baa7ab4" />


---

## 🧪 Testbench

A simple clock-synchronous testbench is included to:

* Apply sequential operations using `vin`
* Observe latency differences between operations
* Validate flag correctness and output timing

---

## 🛠️ Tools Used

* Verilog HDL
* Xilinx Vivado (Simulation + Synthesis)
* XSim waveform viewer

---

## 🚀 Future Improvements

* Replace CSA multiplier with full FA/HA Wallace tree
* Add signed multiplication/division support
* Implement stall/ready handshake for division
* Add performance counters (latency tracking)

---

## 📎 Summary

This project demonstrates a **hardware-accurate ALU design** with realistic pipeline behavior, making it suitable for **VLSI, FPGA, and digital design portfolios**.
