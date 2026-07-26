# tomasulo_algorithm
A Verilog implementation of a Tomasulo-based out-of-order RISC-V processor that dynamically schedules instructions using reservation stations, register renaming, and a Common Data Bus (CDB). The processor supports speculative execution with branch prediction and branch misprediction recovery while handling data hazards without compiler intervention.

Features
32-bit RISC-V instruction support
Tomasulo dynamic scheduling algorithm
Register renaming to eliminate WAR and WAW hazards
Reservation stations for ADD/SUB, MUL/DIV, Load, Store, and Branch operations
Multi-cycle execution units with configurable execution latencies
Common Data Bus (CDB) for result broadcasting
Data hazard handling (RAW, WAR, WAW)
Branch prediction with speculative execution
Branch misprediction detection and pipeline recovery
Verilog testbench demonstrating out-of-order execution and hazard resolution
Architecture

The processor consists of:

Instruction Fetch & Decode
Register File with Renaming
Reservation Stations
Multi-cycle Functional Units (Adder, Multiplier, Divider, Load/Store)
Common Data Bus (CDB)
Branch Prediction & Recovery Logic
Technologies
Verilog HDL
ModelSim/QuestaSim
RISC-V ISA
Learning Outcomes

This project demonstrates:

Dynamic instruction scheduling
Out-of-order execution
Register renaming
Hazard detection and resolution
Speculative execution
Branch prediction and recovery
Computer architecture implementation using Verilog
