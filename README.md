# APB-Based 4-Bit ALU Design

## Overview

This project implements a 4-bit Arithmetic Logic Unit (ALU) interfaced with an AMBA Advanced Peripheral Bus (APB) slave interface using Verilog HDL.

The design allows a processor or APB master to write input operands and select an ALU operation through memory-mapped registers. The computed result can then be accessed through an APB read transaction.

## Features

- 4-bit Arithmetic Logic Unit.
- APB slave interface.
- Memory-mapped register architecture.
- Support for four arithmetic and logical operations.
- Synchronous active-low reset.
- Zero-wait-state APB slave response.
- Invalid address detection using `PSLVERR`.
- Read and write transactions.

## ALU Operations

| Operation | Opcode | Function |
|---|---|---|
| Addition | `00` | A + B |
| Subtraction | `01` | A - B |
| Bitwise AND | `10` | A & B |
| Bitwise OR | `11` | A \| B |

## APB Register Map

| Address | Register | Description |
|---|---|---|
| `0x00` | OPERAND_A | Stores 4-bit input A |
| `0x04` | OPERAND_B | Stores 4-bit input B |
| `0x08` | OPERATION | Selects ALU operation |
| `0x0C` | RESULT | Provides the ALU output |
| Other | Invalid | Generates `PSLVERR` |

## Design Architecture

The design consists of two main modules:

**1. `alu_4bit`**

- Performs arithmetic and logical operations.
- Takes two 4-bit operands and a 2-bit operation code.
- Produces a 4-bit result.

**2. `apb_alu_slave`**

- Implements the APB slave interface.
- Handles operand and operation register writes.
- Provides read access to operands and the ALU result.
- Generates `PREADY` and `PSLVERR` responses.
- Instantiates the 4-bit ALU module.

## Verification

A dedicated Verilog testbench (`tb_apb_alu_slave.v`) is developed to verify the functionality of the APB-based ALU.

The testbench covers:

1. Reset operation.
2. Addition.
3. Subtraction.
4. Bitwise AND.
5. Bitwise OR.
6. Register read-back.
7. Invalid address read.
8. Invalid address write.

The testbench generates a 10 ns clock and creates APB setup and access phases for read and write transactions.

## Simulation

The design can be simulated using Icarus Verilog and GTKWave.


## Tools Used

Xilinx Vivado 

## Learning Outcomes

- Understanding APB communication protocol.
- Designing memory-mapped peripheral registers.
- Integrating an ALU with an APB slave interface.
- Implementing APB read and write transactions.
- Developing testbenches for functional verification.
- Handling invalid address transactions and error responses.

