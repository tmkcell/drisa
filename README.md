# drisa
A 32-bit ISA that aims for high code density

Still being drafted, it would be greatly appreciated if you open an issue with your suggestion to this ISA :)

## Architecture
### Base integer instruction set (BRI)
16-bit instructions, 16 registers
- all registers can be used the same, including PC, SP etc
- memory can only be accessed by load stores
- no immediates outside of shift
- status flags: sign, zero, carry, overflow, greater than, equal to, less than
- 3-bit opcode + 1-bit opextend, if set fetches extra byte as extension toinstruction
#### 3 instruction formats
memory:
| optype | Rsrc  | Rdest | opcode | opextend |
|--------|-------|-------|--------|----------|
| 4-bit  | 4-bit | 4-bit | 3-bit  | 1-bit    |

- optype loads/stores a byte (0), a half (1) or a word (3)

arithmetic:
| cond   | Rsrc  | Rdest | opcode | opextend |
|--------|-------|-------|--------|----------|
| 4-bit  | 4-bit | 4-bit | 3-bit  | 1-bit    |

- cond only performs operation if less that set (1), equal to set (2), greater than set (3) or performs unconditionally (0)

logical:

| shamt/regselect | optype | shamt/reg | Rdest | opcode | opextend |
|-----------------|--------|-----------|-------|--------|----------|
| 1-bit           | 2-bit | 5-bit      | 4-bit | 3-bit  | 1-bit    |

- if shamt/regselect set, 5-bit shamt/reg will select a register, with the top bit being discarded
- optype shifts left (0), right (1) or right with sign-copy (2)
#### Total set of instructions:
| Opcode | Format     | Instruction                          |
|--------|------------|--------------------------------------|
| 0b110  | Memory     | load {byte, half, word}              |
| 0b111  | Memory     | store {byte, half, word}             |
| 0b000  | Arithmetic | add (conditional)                    |
| 0b001  | Arithmetic | subtract (conditional)               |
| 0b010  | Arithmetic | and (conditional)                    |
| 0b011  | Arithmetic | or (conditional)                     |
| 0b100  | Arithmetic | xor (conditional)                    |
| 0b101  | Logical    | shift {left, right, right sign-copy} |
### Extended integer instruction set (BRX)
Adds multiplication, division and square root and not instructions to BRI
## Running (not implemented yet) 
#### 1. Clone repo
```
git clone https://github.com/tmaakis/brisa.git && cd brisa
```
#### 2. Compile with meson build system (and install missing dependencies!)
```
meson setup build
meson compile -C build
meson install -C build
```
