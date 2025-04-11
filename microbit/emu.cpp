#include "MicroBit.h"
#include <stdint.h>

// set to what size you want, but the micro:bit is quite limited
#define MEMSIZE 65536

extern const int rom_size;
extern const char rom[];
// this needs to include the machine code of the rom to run on the emulator itself
// #include "rom.h"

// memory map:
// 0x0000 - 0x9fff Executable
// 0xa000 - 0xfeff RAM
// 0xff00 - 0xff18 Screen pixels
// 0xff19 - 0xff19 logo, ab, a, b

MicroBit uBit;

enum Flags
{
    ZERO = 0,
    SIGN = 1,
    CARRY = 2,
    OVERFLOW = 3,
};

uint32_t registers[16];
bool state[4];
char mem[MEMSIZE];
bool err; // global error state

char mem_read(uint32_t addr)
{
    if (addr < 0xff00) { return mem[addr]; }
    else if (addr < 0xff19)
    {
        return uBit.display.image.getPixelValue((addr - 0xff00) / 5, (addr - 0xff00) % 5);
    }
    else if (addr < 0xff20)
    {
        return (uBit.logo.isPressed() << 3 | uBit.buttonAB.isPressed() << 2 |
                uBit.buttonA.isPressed() << 1 | uBit.buttonB.isPressed());
    }
    return 0;
}

void mem_write(uint32_t addr, char val)
{
    if (addr < 0xff00) { mem[addr] = val; }
    else if (addr < 0xff19)
    {
        uBit.display.image.setPixelValue((addr - 0xff00) / 5, (addr - 0xff00) % 5, val);
    }
    else if (addr < 0xff20)
    {
        mem[addr] = (uBit.logo.isPressed() << 3 | uBit.buttonAB.isPressed() << 2 |
                     uBit.buttonA.isPressed() << 1 | uBit.buttonB.isPressed());
    }
}

bool condition_calc(char cond)
{
    switch (cond)
    {
        case 1: return true;
        case 0: return false;
        case 3:
            if (state[ZERO] == 1) { return true; }
            else { return false; }
        case 2:
            if (state[ZERO] == 0) { return true; }
            else { return false; }
        case 5:
            if (state[SIGN] == 1) { return true; }
            else { return false; }
        case 4:
            if (state[SIGN] == 0) { return true; }
            else { return false; }
        case 7:
            if (state[CARRY] == 1) { return true; }
            else { return false; }
        case 6:
            if (state[CARRY] == 0) { return true; }
            else { return false; }
        case 9:
            if (state[OVERFLOW] == 1) { return true; }
            else { return false; }
        case 8:
            if (state[OVERFLOW] == 0) { return true; }
            else { return false; }
        case 0b1101:
            if (state[SIGN] == state[OVERFLOW]) { return true; }
            else { return false; }
        case 0b1100:
            if (!state[SIGN] == state[OVERFLOW]) { return true; }
            else { return false; }
        default: err = true; return false;
    }
}
void step(uint16_t op)
{ // refer to the README containing the instruction documentation
    switch (op & 0xf)
    {
        case 0:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] + registers[(op & 0xf000) >> 12];
            break;
        case 1:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] - registers[(op & 0xf000) >> 12];
            break;
        case 2:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] & registers[(op & 0xf000) >> 12];
            break;
        case 3:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] | registers[(op & 0xf000) >> 12];
            break;
        case 4:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] ^ registers[(op & 0xf000) >> 12];
            break;
        case 5:
            if (op >> 15 == 1)
            {
                switch (registers[(op >> 13) & 2])
                {
                    case 0: registers[(op & 0xf0) >> 4] <<= registers[(op & 0xf00) >> 8]; break;
                    case 2: registers[(op & 0xf0) >> 4] >>= registers[(op & 0xf00) >> 8]; break;
                    case 3:
                        registers[(op & 0xf0) >> 4] =
                            (registers[(op & 0xf0) >> 4] >> registers[(op & 0xf00) >> 8]) |
                            ~(0xffff >> registers[(op & 0xf00) >> 8]);
                        break;
                }
            }
            else
            {
                switch (registers[(op >> 13) & 2])
                {
                    case 0: registers[(op & 0xf0) >> 4] <<= (op >> 8) & 5; break;
                    case 2: registers[(op & 0xf0) >> 4] >>= (op >> 8) & 5; break;
                    case 3:
                        registers[(op & 0xf0) >> 4] =
                            (registers[(op & 0xf0) >> 4] >> (op >> 8) & 5) |
                            ~(0xffff >> ((op >> 8) & 5));
                        break;
                }
            }
            break;
        case 6:
            registers[(op & 0xf0) >> 4] = 0;
            registers[0] += (op >> 12) & 2;
            for (int i = 0; i <= op >> 14; ++i)
                registers[(op & 0xf0) >> 4] |= (mem_read(registers[(op & 0xf00) >> 8] + i))
                                               << (i * 8);
            break;
        case 7:
            registers[0] += (op >> 12) & 2;
            for (int i = 0; i <= op >> 14; ++i)
                mem_write(registers[(op & 0xf0) >> 4] + i,
                    (registers[(op & 0xf00) >> 8] >> (i * 8)) & 0xff);
            break;
        case 8:
            if (condition_calc(op >> 12))
                registers[(op & 0xf0) >> 4] += registers[(op & 0xf00) >> 8];
            break;
        case 9:
            if (condition_calc(op >> 12))
                registers[(op & 0xf0) >> 4] -= registers[(op & 0xf00) >> 8];
            break;
        case 10:
            if (condition_calc(op >> 12))
                registers[(op & 0xf0) >> 4] &= registers[(op & 0xf00) >> 8];
            break;
        case 11:
            if (condition_calc(op >> 12))
                registers[(op & 0xf0) >> 4] |= registers[(op & 0xf00) >> 8];
            break;
        case 12:
            if (condition_calc(op >> 12))
                registers[(op & 0xf0) >> 4] ^= registers[(op & 0xf00) >> 8];
            break;
        case 13:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] + (int)registers[(op & 0xf000) >> 12];
            break;
        case 14:
            registers[(op & 0xf0) >> 4] =
                registers[(op & 0xf00) >> 8] - (int)registers[(op & 0xf000) >> 12];
            break;
        case 15: break; // we've got no extented opcodes yet
    }
}

int main()
{
    uBit.init();
    for (int i = 0; i < rom_size; ++i) mem[i] = rom[i];
    while (1)
    {
        step(mem[registers[0]++]);
        if (err == true)
        {
            while (1)
            {
                uBit.display.scroll("Error");
                uBit.sleep(1000);
            }
        }
    }
}
