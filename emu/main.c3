module drisa::emu;

import std::io;
import std::core;

enum Flags {
    ZERO = 0,
    SIGN = 1,
    CARRY = 2,
    OVERFLOW = 3,
}

uint[16] registers;
bool[4] state;
char[] mem;

bool err; // global error state

fn bool condition_calc(char cond) {
    switch (cond) {
        case 1: return true;
        case 0: return false;
        case 3: if (state[ZERO] == 1) { return true; } else { return false; } 
        case 2: if (state[ZERO] == 0) { return true; } else { return false; }
        case 5: if (state[SIGN] == 1) { return true; } else { return false; }
        case 4: if (state[SIGN] == 0) { return true; } else { return false; }
        case 7: if (state[CARRY] == 1) { return true; } else { return false; }
        case 6: if (state[CARRY] == 0) { return true; } else { return false; }
        case 9: if (state[OVERFLOW] == 1) { return true; } else { return false; }
        case 8: if (state[OVERFLOW] == 0) { return true; } else { return false; }
        case 0b1101: if (state[SIGN] == state[OVERFLOW]) { return true; } else { return false; }
        case 0b1100: if (!state[SIGN] == state[OVERFLOW]) { return true; } else { return false; }
        default:
            err = true;
            return false;
    }
}

fn void step(ushort op) { // refer to the README containing the instruction documentation
    switch (op & 0xf) {
        case 0: registers[op&0xf0] = registers[op&0xf00] + registers[op&0xf000];
        case 1: registers[op&0xf0] = registers[op&0xf00] - registers[op&0xf000];
        case 2: registers[op&0xf0] = registers[op&0xf00] & registers[op&0xf000];
        case 3: registers[op&0xf0] = registers[op&0xf00] | registers[op&0xf000];
        case 4: registers[op&0xf0] = registers[op&0xf00] ^ registers[op&0xf000];
        case 5:
            if (op >> 15 == 1) {
                switch (registers[(op>>13)&2]) {
                    case 0: registers[op&0xf0] <<= registers[op&0xf00];
                    case 2: registers[op&0xf0] >>= registers[op&0xf00];
                    case 3: registers[op&0xf0] = (registers[op&0xf0] >> registers[op&0xf00]) | ~(0xffff >> registers[op&0xf00]);
                }
            } else {
                switch (registers[(op>>13)&2]) {
                    case 0: registers[op&0xf0] <<= (op >> 8) & 5;
                    case 2: registers[op&0xf0] >>= (op >> 8) & 5;
                    case 3: registers[op&0xf0] = (registers[op&0xf0] >> (op >> 8) & 5) | ~(0xffff >> ((op >> 8) & 5));
                }
            }
        case 6:
            registers[op&0xf0] = 0;
            registers[0] += (op >> 12) & 2;
            for (int i = 0; i <= op >> 14; ++i) registers[op&0xf0] |= (mem[registers[op&0xf00]] + i) << (i * 4);
        case 7:
            registers[0] += (op >> 12) & 2;
            for (int i = 0; i <= op >> 14; ++i) mem[registers[op&0xf0] + i] = (registers[op&0xf00] >> (i * 4)) & 0xff;
        case 8: if (condition_calc(op>>12)) registers[op&0xf0] += registers[op&0xf00];
        case 9: if (condition_calc(op>>12)) registers[op&0xf0] -= registers[op&0xf00];
        case 10: if (condition_calc(op>>12)) registers[op&0xf0] &= registers[op&0xf00];
        case 11: if (condition_calc(op>>12)) registers[op&0xf0] |= registers[op&0xf00];
        case 12: if (condition_calc(op>>12)) registers[op&0xf0] ^= registers[op&0xf00];
        case 13: registers[op&0xf0] = registers[op&0xf00] + (int)registers[op&0xf000];
        case 14: registers[op&0xf0] = registers[op&0xf00] - (int)registers[op&0xf000];
        case 15: break; // we've got no extented opcodes yet
    }
}

fn int main(String[] args)
{
    ulong memsize = 0x1000000; // default 16MiB RAM
    if (args.len == 1) {
        io::printn("File not provided");
        return 1;
    }
    for (int i = 1; i < args.len; ++i) {
        if (args[i][0] == '-') {
            switch (args[i][1]) {
                case 'v':
                    io::printn("0.1.0");
                    return 0;
                case 'h':
                    io::printn(`drisa-emu [opts] path/to/exec
Options:
    -h   Shows help menu
    -v   Shows program version
    -m n Use RAM size n (default 16MiB)`);
                    return 0;
                case 'm':
                    memsize = args[++i].to_long();
                default:
                    io::printfn("\e[31merror:\e[0m unrecognised option \"%s\"", args[i]);
                    return 1;
            }
        } else {
            if (i == args.len - 1) break;
            io::printfn("\e[31merror:\e[0m unrecognised option \"%s\"", args[i]);
            return 1;
        }
    }

    mem = std::core::mem::new_array(char, memsize);
    defer free(mem);

    while (1) {
        step(mem[registers[0]++]);
        if (err == -1) {
            printfn("\e[31merror:\e[0m instruction \"0x%02x\" caused an error!", mem[registers[0]-1]);
            return 1;
        }
    }

	return 0;
}
