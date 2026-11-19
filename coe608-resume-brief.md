# Resume Brief: 32-bit Semi-RISC CPU in VHDL (COE608)

> **For the agent reading this:** This is a fact sheet built from a read-only review of the student's course repository. Use it to write a resume **project entry**: a title line plus 3–5 bullets, and optionally a one-line skills/tech list. Everything below comes from the source code, Quartus reports, or the student's own lab report. Section 8 lists things you must **not** claim. Prefer concrete numbers and technical terms over vague wording.

---

## 1. Context

| Field | Value |
|---|---|
| Course | COE608: Computer Organization and Architecture |
| School | Toronto Metropolitan University (formerly Ryerson), Electrical & Computer Engineering |
| Term | Winter 2026 (Jan to Apr 2026, based on compile timestamps) |
| Type | Individual lab series (Labs 1–6) that builds up to one complete CPU |
| Language | VHDL (plus one small Verilog warm-up in Lab 1) |
| Tools | Intel/Altera Quartus Prime 16.0, Quartus waveform simulator (`.vwf`, timing simulation), ModelSim/QSim, MegaWizard (MegaCore RAM), Memory Initialization Files (`.mif`) |
| Target hardware | Terasic DE2-115 board, Intel Cyclone IV E FPGA (EP4CE115F29C7) |

**One-line summary:** Designed, built, and verified a multi-cycle 32-bit semi-RISC processor from the gate level up in VHDL. It has a custom ALU, a datapath, a finite-state-machine control unit, and on-chip memories, and it was synthesized for an Intel Cyclone IV FPGA.

---

## 2. How the Project Progressed (lab by lab)

Each lab produced a part that later labs reused. Together they form one CPU.

| Lab | What was built | Notes |
|---|---|---|
| 1 | XOR logic function in VHDL **and** Verilog | Learned the toolflow: compile, pin assignment, waveform simulation, program the DE2-115 |
| 2 | 1-bit register, 32-bit register (sync load, async clear), **Program Counter** (register + incrementer + 2:1 mux to pick increment or jump target) | Structural/hierarchical design |
| 3a | **Ripple-carry adder hierarchy**: full adder → 4-bit → 16-bit → 32-bit adder; **32-bit ALU** | Entirely structural. The 32-bit adder is built from 32 instantiated full-adder cells |
| 3b | **8-bit ALU** (ADD, SUB, AND, OR, XOR, NOT, SHL, …) run on real hardware: operands and opcode set by the board's 18 slide switches, result shown on the 7-segment displays, Zero/Carry flags on the LEDs | Tested on the physical FPGA board |
| 4a | **256 × 32-bit synchronous data memory** (RAM written in VHDL, read/write enable, falling-edge clocked) | Verified in simulation |
| 4b | **Full CPU datapath**: IR, PC, registers A & B, C/Z status flags, ALU, data memory, 2:1 and 4:1 muxes, zero-extension units (LZE/UZE) and an address-reduction unit (RED) | Signal paths checked per instruction with waveform files |
| 5 | **Control unit**: 3-state FSM (T0 fetch → T1 pre-decode/PC increment/memory access → T2 execute) plus a combinational instruction decoder that drives 21 control signals | Written report; timing-simulated each instruction separately |
| 6 | **Full CPU integration** (`cpu1`): datapath + control unit + reset circuit, connected to a 64 × 32 instruction RAM loaded from a `.mif` program file, in a top-level test harness | Full compile (synthesis, place & route, timing analysis) for the Cyclone IV E |

---

## 3. CPU Architecture (technical detail)

**General**
- 32-bit data path, 32-bit instructions, **multi-cycle** execution (3 clock states per instruction: T0/T1/T2).
- Accumulator-style register model: two 32-bit working registers **A** and **B**, plus **Carry (C)** and **Zero (Z)** status flags.
- **Harvard-style split memory**: a separate instruction memory (64 × 32 MegaCore RAM, initialized from a `.mif`) and a data memory (256 × 32 RAM written by hand in VHDL).
- Two clock domains: a CPU clock and a faster memory clock (the memory clock runs at least 2× the CPU clock).
- Word-addressed PC that increments by 1, with a jump/branch target loaded from the instruction's 16-bit immediate field.
- A **reset circuit** FSM holds the PC cleared and the control unit disabled for several cycles after reset, so startup is clean.

**Instruction encoding**
- `IR[31:28]` = 4-bit primary opcode.
- ALU/register instructions share opcode `0111` and use `IR[27:24]` as a function field (so 8-bit decoding for those instructions).
- `IR[15:0]` = 16-bit immediate. It is zero-extended into the low half (LZE) or high half (UZE, used for LUI).
- `IR[7:0]` = data-memory address (taken by the RED unit).

**ALU** (32-bit, 3-bit opcode): AND, OR, ADD, SUB (two's complement A + ~B + 1), pass-B, rotate/shift left by 1 (MSB → carry), shift right by 1. It produces Zero and Carry-out flags. Built from the structural 32-bit ripple-carry adder.

**Datapath muxing:** DATA_MUX (4:1, picks the memory bus, the data-memory output, or the ALU result), A_MUX/B_MUX (bus or immediate into the registers), REG_MUX (A or B into data memory for stores), IM_MUX1 (A or the upper-immediate into the ALU), IM_MUX2 (B, the immediate, the constant 1, or 0 into the ALU, used for INC/DEC).

**Control unit:** a Moore-style 3-state sequencer plus a large combinational decoder. It generates register load/clear signals, PC increment/load, IR load, ALU opcode, all mux selects, and data-memory `en`/`wen`. A T-state indicator output was used for debugging.

**Instruction set implemented in the control unit (26 instructions):**

| Category | Instructions |
|---|---|
| Load/store (memory) | LDA, LDB, STA, STB |
| Load immediate | LDAI, LDBI, LUI (load upper immediate) |
| Arithmetic | ADD, ADDI, SUB, INCA, DECA |
| Logic | AND, ANDI, ORI |
| Shift/rotate | ROL, ROR |
| Clear | CLRA, CLRB, CLRC, CLRZ |
| Control flow | JMP, BEQ, BNE |
| Flag test / skip | TSTZ, TSTC (skip the next instruction if the flag is set) |

---

## 4. Verification

- Wrote **22 separate timing-simulation waveform testbenches** (`.vwf`), one per instruction (ADD, ADDI, SUB, AND, ANDI, ORI, INCA, DECA, ROL, ROR, CLRA, CLRB, LDA, LDB, LDAI, LDBI, LUI, STA, STB, JMP, BEQ, BNE). Each one checks control-signal timing across T0/T1/T2 and the register/flag results.
- The Lab 5 report notes these were **timing (post-fit) simulations, not just functional ones**.
- Unit-level waveform testbenches for the 8-bit adder/ALU, the data memory, and the reset circuit.
- Full-system simulation of the integrated CPU (`cpu_test_sim.vwf`): CPU + instruction memory, with debug ports for A, B, C, Z, IR, PC, the T-state, and the memory buses.
- The 8-bit ALU (Lab 3b) was **tested on the physical DE2-115 board** using switches, 7-segment displays, and LEDs.

---

## 5. Hard Numbers (from the Quartus reports in the repo)

Full CPU + test harness (`CPU_TEST_Sim`, Lab 6), Cyclone IV E EP4CE115F29C7:

| Metric | Value |
|---|---|
| Logic elements | **726** (719 combinational functions) |
| Registers | **168** |
| On-chip memory bits | **10,240** |
| Fmax, CPU clock (slow 85 °C model) | **~59 MHz** |
| Fmax, memory clock (slow 85 °C model) | **~152 MHz** |
| Fitter status | Successful |

Control unit alone (Lab 5): 124 logic elements, 3 state registers.

Approximate hand-written VHDL for the final CPU: about 1,500 lines across about 20 design units (the control unit alone is about 620 lines).

---

## 6. Skills Shown (for a skills line or keyword matching)

- **Digital design / computer architecture:** datapath design, multi-cycle control, FSM design, instruction decoding, ISA implementation, ALU design, ripple-carry adders, register files/status flags, memory interfacing, Harvard architecture, clock-domain timing between CPU and memory.
- **HDL:** VHDL (structural and behavioral styles, component instantiation, processes, enumerated-type state machines), basic Verilog.
- **FPGA toolflow:** Intel Quartus Prime (synthesis, fitting, pin assignment via `.qsf`, TimeQuest static timing analysis), MegaWizard IP (RAM MegaCore), `.mif` memory initialization, programming the board over JTAG (`.sof`).
- **Verification:** waveform/timing simulation, writing per-instruction test vectors, debugging through observability ports.
- **Hardware:** Terasic DE2-115 (Cyclone IV E), slide switches, 7-segment displays, LEDs.

---

## 7. Suggested Framing (the agent can adapt this)

Possible titles:
- "32-bit Multi-Cycle RISC Processor | VHDL, Intel Quartus, Cyclone IV FPGA"
- "Semi-RISC CPU Design & FPGA Implementation | VHDL, Quartus Prime, DE2-115"

Example bullet ideas (rewrite as needed, keep them accurate):
- Designed a 32-bit multi-cycle semi-RISC CPU in VHDL from the gate level up (full adders → 32-bit ripple-carry adder → ALU → datapath → FSM control unit), supporting a **26-instruction ISA** covering load/store, immediate, arithmetic, logic, shift/rotate, branch, and flag-test operations.
- Built a 3-stage (fetch / decode / execute) **finite-state-machine control unit** that decodes 4-bit opcodes and 4-bit function fields to drive 21 datapath control signals, including memory read/write timing across separate CPU and memory clocks.
- Integrated the CPU with a 64-word instruction RAM (MegaCore, `.mif`-initialized) and a 256-word data memory in a Harvard-style design. Synthesized it for an **Intel Cyclone IV E FPGA** using **726 logic elements** with a **~59 MHz** CPU-clock Fmax.
- Verified correctness with **22 per-instruction timing-simulation testbenches** in Quartus, checking control-signal sequencing, register results, and Carry/Zero flag behavior. Tested ALU hardware on a DE2-115 board using switches, 7-segment displays, and LEDs.

---

## 8. Accuracy Guardrails (do NOT overstate)

- **Not pipelined.** It is a *multi-cycle* CPU (3 states per instruction). Do not call it "pipelined" or "5-stage".
- **Not a full RISC ISA like MIPS or RISC-V.** The course calls it "semi-RISC". It is accumulator-style with two working registers (A, B), not a general-purpose register file.
- **Course-provided scaffolding:** the course provided the top-level test harness (`CPU_TEST_Sim.vhd`), the instruction-memory MegaCore wrapper, the DE2-115 pin file, the 7-segment driver, and the bonus LCD controller files (written by the course instructor). The student designed the datapath components, ALU, adders, registers, PC, data memory, control unit, reset circuit, and the `cpu1` integration.
- **No evidence the bonus (running the full CPU on the board with LCD output) was completed.** The bonus folder holds only the provided files. Do not claim the full CPU ran on physical hardware. It was compiled and fitted successfully (a `.sof` exists) and verified in simulation. The Lab 3b ALU was the part tested on the board.
- **Branch caveat:** in the final control-unit code, BEQ/BNE load the PC in T2 without checking the Z flag, so their conditional behavior is not clearly implemented in the code. Say "branch/jump instructions" generally, and don't stress "conditional branching on flags". TSTZ/TSTC *do* check the flags.
- The `.mif` in the repo is all zeros (the test program is not kept in the repo), so don't describe a specific program the CPU ran.
- Fmax numbers come from Quartus's slow-corner timing model, not from measurements on hardware.
- Individual work. No team-size claims.

---

## 9. Repository Map (for reference)

```
lab1/, lab1-v/     XOR in VHDL / Verilog (toolflow intro)
lab2/              register1, register32, PC (pc + add + mux2to1)
lab3/lab3a/        fulladd → adder4 → adder16 → adder32, 32-bit alu
lab3/lab3b/        8-bit adder + alu8, board test harness (switches/7-seg/LEDs)
lab4/lab4a/        data_mem (256×32 RAM)
lab4/lab4b/        data_path + LZE/UZE/RED/mux4to1, per-instruction .vwf tests
lab5(1)/           Control.vhd (FSM control unit), 22 instruction .vwf, Lab 5 report PDF
lab6/              cpu1 (top CPU), Control_New, data_path, reset_circuit,
                   system_memory (MegaCore RAM + .mif), cpu_test_sim harness,
                   Quartus output_files (fit/timing reports)
lab6/bonus/        course-provided LCD / 7-seg emulation files + handout PDF
```
