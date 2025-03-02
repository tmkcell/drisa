# drisa
After the [psyche](https://github.com/tmkcell/psyche) project, I realised that many instructions have a lot of wasted space that can be used. 
For example, an ld instruction uses the I-type instruction format, but without actually using the the 16-bit immediate section!
For this reason, I have designed this.

Inspiration is mainly Arm and their Thumb architecture, which I got the conditional instruction and 16-bit instruction ideas from.

Still being drafted, it would be greatly appreciated if you open an issue with your suggestion to this ISA :)

## Architecture

16-bit instructions, 16 32-bit registers
- all registers can be used the same, including IP (PC), SP etc
- memory can only be accessed by load stores
- no immediates outside of shift
- status flags: sign, zero, carry, overflow, (greater than, equal to, less than will be assembly abstractions) 
- 4-bit opcode for 15 instructions: 0b1111 fetches an extra byte for an extended instructions

### Base integer instruc tion setDR-I)
#### Rter layout
| Name                | Symbol | Real register |
|---------------------|--------|---------------|
| Zero                | z      | 0             |
| Instruction pointer | ip     | 1             |
| Link register       | l      | 2             |
| Stack pointer       | sp     | 3             |
| Func args/result    | f1-4   | 4-7           |
| General purpose     | r1-8   | 8-15          |

#### 4 instruction formats
Arithmetic:
| Rop1   | Rop2  | Rdest | opcode |
|--------|-------|-------|--------|
| 4-bit  | 4-bit | 4-bit | 4-bit  |

Logical:

| shamt/regselect | optype | shamt/reg | Rdest&Rop1 | opcode |
|-----------------|--------|-----------|------------|--------|
| 1-bit           | 2-bit | 5-bit      | 4-bit      | 4-bit  |

- if shamt/regselect set, 5-bit shamt/reg will select a register, with the top bit being discarded
- optype shifts left (0), right (2) or right with sign-copy (3)

Memory:
| pcskip | optype | Rop1  | Rdest | opcode |
|--------|--------|-------|-------|--------|
| 2-bit  | 2-bit  | 4-bit | 4-bit | 4-bit  |

- pcskip gets added to PC
- optype loads/stores a byte (0), a half (1) or a word (3)

Conditional:
| cond   | Rop2  | Rdest&Rop1 | opcode |
|--------|-------|------------|--------|
| 4-bit  | 4-bit | 4-bit      | 4-bit  |

- cond only performs operation if the condition is true or cond = 0

#### Total set of instructions:
| Opcode | Format      | Instruction                          |
|--------|-------------|--------------------------------------|
| 0b0000 | Arithmetic  | add                                  |
| 0b0001 | Arithmetic  | subtract                             |
| 0b0010 | Arithmetic  | and                                  |
| 0b0011 | Arithmetic  | or                                   |
| 0b0100 | Arithmetic  | xor                                  |
| 0b0101 | Logical     | shift {left, right, right sign-copy} |
| 0b0110 | Memory      | load {byte, half, word}              |
| 0b0111 | Memory      | store {byte, half, word}             |
| 0b1000 | Conditional | conditional add                      |
| 0b1001 | Conditional | conditional subtract                 |
| 0b1010 | Conditional | conditional and                      |
| 0b1011 | Conditional | conditional or                       |
| 0b1100 | Conditional | conditional xor                      |
### Extended integer instruction set (DR-IX)
Adds multiplication and division capabilities
| Opcode | Format     | Instruction |
|--------|------------|-------------|
| 0b1101 | Arithmetic | mulitply    |
| 0b1110 | Arithmetic | divide      |
## Running (not implemented yet) 
#### 1. Clone repo
```
git clone https://github.com/tmkcell/drisa.git && cd drisa
```
#### 2. Compile with meson build system (and install missing dependencies!)
```
meson setup build
meson compile -C build
meson install -C build
```
