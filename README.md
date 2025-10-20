# Floating Point Unit (FP16 & FP32)

## Overview
This project implements a **Floating Point Unit (FPU)** capable of performing arithmetic operations using both **half-precision (FP16)** and **single-precision (FP32)** formats, fully compliant with the **IEEE 754 Standard for Floating-Point Arithmetic**.

The system is designed in **Verilog** and was **implemented and tested on the Digilent Basys3 FPGA** using the Xilinx Vivado environment.

---

## Architecture

The design follows a modular approach, where each block handles a specific stage of the floating-point operation.  
The top-level control is managed by the **"THE_STROKIE" Module**, which synchronizes all stages.

### Main Modules
| Module | Description |
|--------|--------------|
| `fp16_decode` / `fp32_decode` | Extracts the sign, exponent, and mantissa from the floating-point input. |
| `magnitude16` / `magnitude32` | Performs the core arithmetic operation (addition, subtraction, multiplication, or division). |
| `normalize16` / `normalize32` | Normalizes the resulting mantissa and adjusts the exponent. |
| `fp16_exception` / `fp32_exception` | Detects and handles special cases: **NaN**, **infinity**, **zero**, **overflow**, and **underflow**. |

---

## Control Logic
The **control unit** ensures proper timing and synchronization between modules.  
It manages signal propagation, exception flags, and data routing for FP16 and FP32 modes.

---

## Simulation
All modules were simulated using **Vivado Simulator**, verifying:
- Correct decoding and normalization of inputs.
- Exception flag behavior.
- Functional equivalence to IEEE 754 arithmetic.

Waveforms were generated to validate:
- Overflow/Underflow handling  
- NaN propagation  
- Sign and exponent correctness  

---

### Demonstration
The FPU was successfully demonstrated performing arithmetic operations in both FP16 and FP32 formats, showcasing correct exception detection and stable real-time operation on the Basys3.

---

## References
- Harris, D. & Harris, S. *Digital Design and Computer Architecture, RISC-V Edition*. Morgan Kaufmann, 2021.  
- IEEE Standard for Floating-Point Arithmetic (IEEE 754-2019).

---

## Authors
- Matias Sebastian Walde Verano – Universidad de Ingeniería y Tecnología (UTEC), Peru  
- Yaritza Milagros Lopez Rojas – Universidad de Ingeniería y Tecnología (UTEC), Peru  
