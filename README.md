# drisa

A monorepo containing tools and specification for the drisa instruction set; contains an assembler and an emulator (both currently incomplete)

After the [psyche](https://github.com/tmkcell/psyche) project, I realised that many instructions have a lot of wasted space that can be used. 
For example, an ld instruction uses the I-type instruction format, but without actually using the the 16-bit immediate section!
For this reason, I have designed this ISA. 

Inspiration is mainly Arm and their Thumb architecture, which I got the conditional instruction and 16-bit instruction ideas from.

Still being drafted, it would be greatly appreciated if you open an issue with your suggestion to this ISA :)

## Building/running

> [!WARNING] 
> Both drisa-asm and drisa-emu are incomplete, so running the below command may not get working applications. Please wait for a stable release

drisa-asm and drisa-emu are both written in [c3](https://c3-lang.org/), so you will need the c3 compiler.

You can build the emulator with:
```
c3c build drisa-emu 
```
Or the assembler with:
```
c3c build drisa-asm
```
If the compiler complains about missing libraries, make a folder called `lib` in the repo's root directory

Both will create an executable in `build` :P

> [!WARNING] 
> The build script for the micro:bit emulator is NOT safe to use, use at your own risk.

Additionally, there is also an emulator for the BBC micro:bit written in C++. To compile this you should run the build.sh script in the microbit folder. This will download the required toolchain and libraries, and output a .hex file which you can copy onto the micro:bit. To include a drisa executable, assemble a file using the '-c' parameter to output an header file instead of a binary.

## Architecture specification

16-bit instructions, 16 32-bit registers
- all registers can be used the same, including IP (PC), SP etc
- memory can only be accessed by load stores
- no immediates outside of shift
- status flags: sign, zero, carry, overflow, (greater than, equal to, less than will be assembly abstractions) 
- 4-bit opcode for 15 instructions: 0b1111 fetches an extra byte for an instruction not in the base ISA

### Base integer instruction set (DR-I)
#### Notes
- Instructions are layed out in machine code reverse of their assembly representation

#### Register layout
| Name                | Symbol | Real register |
|---------------------|--------|---------------|
| Zero                | z      | 0             |
| Instruction pointer | ip     | 1             |
| Link register       | l      | 2             |
| Stack pointer       | sp     | 3             |
| Func args/result    | f1-4   | 4-7           |
| General purpose     | r1-8   | 8-15          |

#### Condition codes
| Bits   | Name                         | Symbol | Flags   |
|--------|------------------------------|--------|---------|
| 0b0001 | true                         | tr     | none    |
| 0b0000 | false                        | fl     | none    |
| 0b0011 | equal                        | eq     | z == 1  |
| 0b0010 | not equal                    | neq    | z == 0  |
| 0b0101 | negative                     | neg    | s == 1  |
| 0b0100 | positive                     | pos    | s == 0  |
| 0b0111 | greater than/equal to        | ge     | c == 1  |
| 0b0110 | less than                    | lt     | c == 0  |
| 0b1001 | signed overflow              | so     | v == 1  |
| 0b1000 | no signed overflow           | nso    | v == 0  |
| 0b1101 | signed greater than/equal to | sge    | s == v  |
| 0b1100 | signed less than             | slt    | !s == v |

#### 4 instruction formats
Arithmetic:
| Rop2   | Rop1  | Rdest | opcode |
|--------|-------|-------|--------|
| 4-bit  | 4-bit | 4-bit | 4-bit  |

- layout: $inst Rdest, Rop1, Rop2

Logical:

| shamt/regselect | optype | shamt/reg | Rdest&Rop1 | opcode |
|-----------------|--------|-----------|------------|--------|
| 1-bit           | 2-bit  | 5-bit     | 4-bit      | 4-bit  |

- layout: $inst Rdest/Rop1, shamt/reg
- if shamt/regselect set, 5-bit shamt/reg will select a register, with the top bit being discarded
- optype shifts left (0), right (2) or right with sign-copy (3)

Memory:
| optype | pcskip | Rop1  | Rdest | opcode |
|--------|--------|-------|-------|--------|
| 2-bit  | 2-bit  | 4-bit | 4-bit | 4-bit  |

- layout: $inst Rdest, Rop1, (IP += )pcskip
- pcskip gets added to PC
- optype loads/stores a byte (0), a half (1) or a word (3)

Conditional:
| cond   | Rop2  | Rdest&Rop1 | opcode |
|--------|-------|------------|--------|
| 4-bit  | 4-bit | 4-bit      | 4-bit  |

- layout: $inst Rdest/Rop1, Rop2, cond
- cond only performs operation if the condition is true or cond = 0

#### Total set of instructions:
| Opcode | Format      | Mnemonic    | Instruction                           |
|--------|-------------|-------------|---------------------------------------|
| 0b0000 | Arithmetic  | add         | add                                   |
| 0b0001 | Arithmetic  | sub         | subtract                              |
| 0b0010 | Arithmetic  | and         | and                                   |
| 0b0011 | Arithmetic  | or          | or                                    |
| 0b0100 | Arithmetic  | xor         | xor                                   |
| 0b0101 | Logical     | s(r){l,r,a} | shift (reg) {left, right, arithmetic} |
| 0b0110 | Memory      | ld{b,h,w}   | load {byte, half, word}               |
| 0b0111 | Memory      | st{b,h,w}   | store {byte, half, word}              |
| 0b1000 | Conditional | cadd        | conditional add                       |
| 0b1001 | Conditional | csub        | conditional subtract                  |
| 0b1010 | Conditional | cand        | conditional and                       |
| 0b1011 | Conditional | cor         | conditional or                        |
| 0b1100 | Conditional | cxor        | conditional xor                       |
| 0b1101 | Arithmetic  | adds        | add sign                              |
| 0b1110 | Arithmetic  | subs        | subtract sign                         |
| 0b1111 | Extended    |             | prefix for extended instruction       |
### Extended integer instruction set (DR-IX)
Adds multiplication and division capabilities
