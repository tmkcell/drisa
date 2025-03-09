module drisa::assembler;

import std::io;

fn int get_real_register(String symbol) {
    switch (symbol[0]) {
        case 'z': return 0;
        case 'i': return 1;
        case 'l': return 2;
        case 's': return 3;
        case 'f': return (symbol[1] >= 1 || symbol[1] <= 4) ? (symbol[1] - '0' + 3) : -1;
        case 'r': return (symbol[1] >= 1 || symbol[1] <= 8) ? (symbol[1] - '0' + 7) : -1;
        default: return -1;
    }
}

fn int main(String[] args) {
    if (args.len == 1) {
        io::printn("File not provided");
        return 1;
    }
    bool bigendian = false;
    // todo: sort paths out
    Path! filepath = io::path::new_cwd();
    if (catch err = filepath) {
        io::printfn("Error: %s", err);
    }

    for (int i = 1; i < args.len; ++i) {
        if (args[i][0] == '-') {
            switch (args[i][1]) {
                case 'v':
                    io::printn("0.1.0");
                    return 0;
                case 'h':
                    io::printn(`drisa-asm [opts] path/to/file
Options:
    -h  Shows help menu
    -v  Shows program version`);
                    return 0;
                case 'b':
                    bigendian = true;
                case 'o':
                    filepath = io::path::new(args[++i]);
                default:
                    io::printfn("Error: unrecognised option \"%s\"", args[i]);
                    return 1;
            }
        } else {
            if (i == args.len - 1) break;
            io::printfn("Error: unrecognised option \"%s\"", args[i]);
            return 1;
        }
    }
 
    // load text file into buffer
    char[]! buf = file::load_new(args[args.len-1]);
    if (catch err = buf) {
        io::printfn("Error: %s", err);
        return 1;
    }
    
    // open out file
    File! out = io::file::open(filepath.basename(), "w");
    if (catch err = out) {
        io::printfn("Error: %s", err);
        return 1;
    }

    int line;
    for (int i; i < buf.len; ++i) {
        // skip all comments and whitespace
        for SKIPWSANDCOM: (;;) switch (buf[i]) {
            case ' ':
                ++i;
            case '\n': 
                ++line;
                ++i;
            case ';': 
                while (buf[i] != '\n') ++i;
            default: break SKIPWSANDCOM;
        }
        
        // get token
        int start = i;
        while (buf[i] != ' ') ++i;
        String token = (String)buf[start..i];
        
        // set as much of the instruction as possible
        ushort inst; 
        switch (token) {
            case "add": inst = 0b0000;
            case "sub": inst = 0b0001;
            case "and": inst = 0b0010;
            case "or": inst = 0b0011;
            case "xor": inst = 0b0100;
            case "sl": inst = 0b0101;
            case "srl": inst = (1 << 15) | 0b0101;
            case "sr": inst = (0b010 << 13) | 0b0101;
            case "srr": inst = (0b110 << 13) | 0b0101;
            case "sa": inst = (0b011 << 13) | 0b0101;
            case "sra": inst = (0b111 << 13) | 0b0101;
            case "ldb": inst = 0b0110;
            case "ldh": inst = (1 << 14) | 0b0110;
            case "ldw": inst = (2 << 14) | 0b0110;
            case "stb": inst = 0b0111;
            case "sth": inst = (1 << 14) | 0b0111;
            case "stw": inst = (2 << 14) | 0b0111;
            case "cadd": inst = 0b1000;
            case "csub": inst = 0b1001;
            case "cand": inst = 0b1010;
            case "cor": inst = 0b1011;
            case "cxor": inst = 0b1100;
            default: io::printfn("Error: unrecognised instruction \"%s\"", token); return 1;
        }
        
        // set operands
        for SETOPERANDS: (int j; j < 3; ++j) {
            while (buf[i] == ' ') ++i;
            start = i;
            while (buf[i] != ',') ++i;
            int next = i + 1;
            while (buf[i] == ' ') --i; // trim whitespace
            token = (String)buf[start..i];
            i = next;

            if (j == 1 && (inst & 0xf == 0b0101) && !(inst >> 15)) { // expect shamt instead of reg here
                ushort shamt;
                for (int k; k < token.len; ++k) shamt = shamt * 10 + token[k] - '0';
                if (shamt > 31) {
                    io::printfn("Error: shamt \"%i\" is greater than 31", shamt);
                    return 1;
                }
                inst |= shamt << 8;
                break SETOPERANDS;
            } else if (j == 3 && ((inst >> 1) & 0b111) == 0b11) { // set pcskip
                if (token[token.len-1] - '0' > 3) {
                    io::printfn("Error: pcskip \"%c\" is greater than 3", token[token.len-1]);
                    return 1;
                }
                inst |= (token[token.len-1] - '0') << ((j + 1) * 4);
            } else if (j == 3 && inst <= 0b1100 && inst >= 0b1000) {
                // todo: deal with conditions
            } else {
                if (get_real_register(token) == -1) {
                    io::printfn("Error: register \"%s\" is invalid", token);
                    return 1;
                }
                inst |= (ushort)get_real_register(token) << ((j + 1) * 4);
                if (j == 1 && (inst & 0xf == 0b0101)) break SETOPERANDS;
            }
        }

        // write instruction to file
        if (bigendian) {
            out.write_byte((char)(inst >> 8))!!; 
            out.write_byte((char)inst)!!; 
        } else {
            out.write_byte((char)inst)!!; 
            out.write_byte((char)(inst >> 8))!!; 
        }
    }

    return 0;
}
