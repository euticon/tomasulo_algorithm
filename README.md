# tomasulo_algorithm

A Verilog implementation of a **Tomasulo-based out-of-order RISC-V processor** that dynamically schedules instructions using reservation stations, register renaming, and a Common Data Bus (CDB). The processor supports speculative execution with branch prediction and branch misprediction recovery while handling data hazards without compiler intervention.

## Features

- 32-bit RISC-V instruction support
- Tomasulo dynamic scheduling algorithm
- Register renaming to eliminate WAR and WAW hazards
- Reservation stations for arithmetic, multiplication/division, load/store, and branch operations
- Multi-cycle functional units with configurable execution latencies
- Common Data Bus (CDB) for result broadcasting
- Data hazard handling (RAW, WAR, WAW)
- Branch prediction with speculative execution
- Branch misprediction detection and recovery
- Verilog testbench demonstrating out-of-order execution

## Architecture

The processor consists of:

- Instruction Fetch & Decode
- Register File with Renaming
- Reservation Stations
- Functional Units (Adder, Multiplier, Divider, Load/Store)
- Common Data Bus (CDB)
- Branch Prediction & Recovery Logic

## Technologies

- Verilog HDL
- ModelSim/QuestaSim
- RISC-V ISA

## Learning Outcomes

This project demonstrates:

- Dynamic instruction scheduling
- Out-of-order execution
- Register renaming
- Hazard detection and resolution
- Speculative execution
- Branch prediction and recovery
- Computer architecture implementation using Verilog
