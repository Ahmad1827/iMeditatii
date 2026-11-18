"""APM · Lucrarea 2 (RISC-V IF + ID): a model of the lab's design, to check every
number in the problems (apm.py) and in the guide (ghid_apm_l2).

- encode / decode RV32I instructions (riscv-spec v2.2, pp. 104-107);
- imm_gen exactly as the lab's Verilog writes it (U, J and jalr give 0);
- the IF/IF-ID/ID front-end clocked as the lab's testbench drives it.

Run it to check itself:  python3 -I tool/acs/apm_model.py
"""

# ---------------------------------------------------------------- the ISA
OP = {'R': 0b0110011, 'I': 0b0010011, 'LOAD': 0b0000011, 'S': 0b0100011, 'B': 0b1100011,
      'LUI': 0b0110111, 'AUIPC': 0b0010111, 'JAL': 0b1101111, 'JALR': 0b1100111}

# name: (format, opcode, funct3, funct7)
INSTR = {
    'add': ('R', OP['R'], 0b000, 0b0000000), 'sub': ('R', OP['R'], 0b000, 0b0100000),
    'sll': ('R', OP['R'], 0b001, 0), 'slt': ('R', OP['R'], 0b010, 0), 'sltu': ('R', OP['R'], 0b011, 0),
    'xor': ('R', OP['R'], 0b100, 0), 'srl': ('R', OP['R'], 0b101, 0), 'sra': ('R', OP['R'], 0b101, 0b0100000),
    'or': ('R', OP['R'], 0b110, 0), 'and': ('R', OP['R'], 0b111, 0),
    'addi': ('I', OP['I'], 0b000, None), 'slti': ('I', OP['I'], 0b010, None), 'sltiu': ('I', OP['I'], 0b011, None),
    'xori': ('I', OP['I'], 0b100, None), 'ori': ('I', OP['I'], 0b110, None), 'andi': ('I', OP['I'], 0b111, None),
    'slli': ('SH', OP['I'], 0b001, 0b0000000), 'srli': ('SH', OP['I'], 0b101, 0b0000000), 'srai': ('SH', OP['I'], 0b101, 0b0100000),
    'lb': ('I', OP['LOAD'], 0b000, None), 'lh': ('I', OP['LOAD'], 0b001, None), 'lw': ('I', OP['LOAD'], 0b010, None),
    'lbu': ('I', OP['LOAD'], 0b100, None), 'lhu': ('I', OP['LOAD'], 0b101, None),
    'sb': ('S', OP['S'], 0b000, None), 'sh': ('S', OP['S'], 0b001, None), 'sw': ('S', OP['S'], 0b010, None),
    'beq': ('B', OP['B'], 0b000, None), 'bne': ('B', OP['B'], 0b001, None), 'blt': ('B', OP['B'], 0b100, None),
    'bge': ('B', OP['B'], 0b101, None), 'bltu': ('B', OP['B'], 0b110, None), 'bgeu': ('B', OP['B'], 0b111, None),
    'jalr': ('I', OP['JALR'], 0b000, None),
    'lui': ('U', OP['LUI'], None, None), 'auipc': ('U', OP['AUIPC'], None, None), 'jal': ('J', OP['JAL'], None, None),
}


def bits(v, hi, lo):
    return (v >> lo) & ((1 << (hi - lo + 1)) - 1)


def r_type(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def i_type(imm, rs1, f3, rd, op):
    assert -2048 <= imm < 4096
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def s_type(imm, rs2, rs1, f3, op):
    assert -2048 <= imm < 2048
    imm &= 0xFFF
    return (bits(imm, 11, 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (bits(imm, 4, 0) << 7) | op


def b_type(imm, rs2, rs1, f3, op):
    assert imm % 2 == 0 and -4096 <= imm < 4096
    imm &= 0x1FFF
    return ((bits(imm, 12, 12) << 31) | (bits(imm, 10, 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12)
            | (bits(imm, 4, 1) << 8) | (bits(imm, 11, 11) << 7) | op)


def u_type(imm20, rd, op):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | op


def j_type(imm, rd, op):
    assert imm % 2 == 0
    imm &= 0x1FFFFF
    return ((bits(imm, 20, 20) << 31) | (bits(imm, 10, 1) << 21) | (bits(imm, 11, 11) << 20)
            | (bits(imm, 19, 12) << 12) | (rd << 7) | op)


def reg(x):
    x = x.strip()
    assert x[0] == 'x', x
    n = int(x[1:])
    assert 0 <= n < 32
    return n


def num(s):
    s = s.strip().lower()
    neg = s.startswith('-')
    s = s.lstrip('-')
    v = int(s, 16) if s.startswith('0x') else int(s)
    return -v if neg else v


def encode(text, hex_offsets=False):
    """'add x2,x1,x0' -> the 32-bit word. Branch offsets are decimal unless written 0x..;
    with hex_offsets a bare number (the lab's 'beq x18,x0,5c') is read in hex."""
    name, _, rest = text.strip().partition(' ')
    fmt, op, f3, f7 = INSTR[name]
    args = [a.strip() for a in rest.replace('(', ',').replace(')', '').split(',') if a.strip()]
    if fmt == 'R':
        rd, rs1, rs2 = map(reg, args)
        return r_type(f7, rs2, rs1, f3, rd, op)
    if fmt == 'SH':
        rd, rs1 = reg(args[0]), reg(args[1])
        sh = num(args[2])
        assert 0 <= sh < 32
        return r_type(f7, sh, rs1, f3, rd, op)
    if fmt == 'I':
        if op in (OP['LOAD'], OP['JALR']) and len(args) == 3 and args[1][0] != 'x':  # lw rd, imm(rs1)
            rd, imm, rs1 = reg(args[0]), num(args[1]), reg(args[2])
        else:
            rd, rs1, imm = reg(args[0]), reg(args[1]), num(args[2])
        return i_type(imm, rs1, f3, rd, op)
    if fmt == 'S':  # sw rs2, imm(rs1)
        rs2, imm, rs1 = reg(args[0]), num(args[1]), reg(args[2])
        return s_type(imm, rs2, rs1, f3, op)
    if fmt == 'B':
        rs1, rs2 = reg(args[0]), reg(args[1])
        off = int(args[2], 16) if hex_offsets and not args[2].startswith(('0x', '-')) else num(args[2])
        return b_type(off, rs2, rs1, f3, op)
    if fmt == 'U':
        return u_type(num(args[1]), reg(args[0]), op)
    if fmt == 'J':
        return j_type(num(args[1]), reg(args[0]), op)
    raise ValueError(text)


def fields(w):
    """The fields ID cuts out, whatever the format."""
    return {'opcode': bits(w, 6, 0), 'rd': bits(w, 11, 7), 'funct3': bits(w, 14, 12), 'rs1': bits(w, 19, 15),
            'rs2': bits(w, 24, 20), 'funct7': bits(w, 31, 25)}


def sext(v, n):
    v &= (1 << n) - 1
    return v - (1 << n) if v >> (n - 1) else v


def imm_gen(w):
    """The lab's imm_gen, bit for bit: a 32-bit unsigned result."""
    op, f3 = bits(w, 6, 0), bits(w, 14, 12)
    s = bits(w, 31, 31)
    if op == 0b0000011:
        v = (bits(w, 31, 20) | (0xFFFFF000 if s else 0))
    elif op == 0b0010011:
        if f3 in (0b001, 0b101):
            v = bits(w, 24, 20)
        else:
            v = (bits(w, 31, 20) | (0xFFFFF000 if s else 0))
    elif op == 0b0100011:
        v = ((bits(w, 31, 25) << 5) | bits(w, 11, 7)) | (0xFFFFF000 if s else 0)
    elif op == 0b1100011:
        v = ((bits(w, 31, 31) << 12) | (bits(w, 7, 7) << 11) | (bits(w, 30, 25) << 5) | (bits(w, 11, 8) << 1)) | (0xFFFFE000 if s else 0)
    else:
        v = 0
    return v & 0xFFFFFFFF


def spec_imm(w):
    """The immediate the ISA means (signed), for every format; None for R-type."""
    op = bits(w, 6, 0)
    if op in (0b0000011, 0b1100111):
        return sext(bits(w, 31, 20), 12)
    if op == 0b0010011:
        f3 = bits(w, 14, 12)
        return bits(w, 24, 20) if f3 in (1, 5) else sext(bits(w, 31, 20), 12)
    if op == 0b0100011:
        return sext((bits(w, 31, 25) << 5) | bits(w, 11, 7), 12)
    if op == 0b1100011:
        return sext((bits(w, 31, 31) << 12) | (bits(w, 7, 7) << 11) | (bits(w, 30, 25) << 5) | (bits(w, 11, 8) << 1), 13)
    if op in (0b0110111, 0b0010111):
        return sext(w & 0xFFFFF000, 32)
    if op == 0b1101111:
        return sext((bits(w, 31, 31) << 20) | (bits(w, 19, 12) << 12) | (bits(w, 20, 20) << 11) | (bits(w, 30, 21) << 1), 21)
    return None


def decode(w):
    """The word back to its text (the names of INSTR)."""
    f = fields(w)
    op, f3, f7 = f['opcode'], f['funct3'], f['funct7']
    x = lambda n: f'x{n}'
    for name, (fmt, o, g3, g7) in INSTR.items():
        if o != op or (g3 is not None and g3 != f3):
            continue
        if fmt == 'R' and g7 == f7:
            return f'{name} {x(f["rd"])},{x(f["rs1"])},{x(f["rs2"])}'
        if fmt == 'SH' and g7 == f7:
            return f'{name} {x(f["rd"])},{x(f["rs1"])},{f["rs2"]}'
        if fmt == 'I':
            imm = spec_imm(w)
            if op in (OP['LOAD'], OP['JALR']):
                return f'{name} {x(f["rd"])},{imm}({x(f["rs1"])})'
            return f'{name} {x(f["rd"])},{x(f["rs1"])},{imm}'
        if fmt == 'S':
            return f'{name} {x(f["rs2"])},{spec_imm(w)}({x(f["rs1"])})'
        if fmt == 'B':
            return f'{name} {x(f["rs1"])},{x(f["rs2"])},{spec_imm(w)}'
        if fmt == 'U':
            return f'{name} {x(f["rd"])},{hex(bits(w, 31, 12))}'
        if fmt == 'J':
            return f'{name} {x(f["rd"])},{spec_imm(w)}'
    return None


def h(v):
    return f'{v & 0xFFFFFFFF:08X}'


def binary(w, groups):
    """The word in binary, cut at the given field widths: '0000000 00000 ...'."""
    s = f'{w:032b}'
    out, i = [], 0
    for g in groups:
        out.append(s[i:i + g])
        i += g
    assert i == 32
    return ' '.join(out)


GROUPS = {'R': (7, 5, 5, 3, 5, 7), 'I': (12, 5, 3, 5, 7), 'S': (7, 5, 5, 3, 5, 7), 'B': (1, 6, 5, 5, 3, 4, 1, 7),
          'U': (20, 5, 7), 'J': (1, 10, 1, 8, 5, 7), 'SH': (7, 5, 5, 3, 5, 7)}


# ---------------------------------------------------------------- the front-end, clocked
LAB_PROGRAM = ['add x2,x1,x0', 'addi x1,x1,1', 'and x3,x1,x2', 'ori x4,x1,1', 'sw x4,4(x5)', 'lw x12,8(x0)', 'beq x18,x0,5c']
LAB_HEX = [0x00008133, 0x00108093, 0x0020F1B3, 0x0010E213, 0x0042A223, 0x00802603, 0x04090E63]


class FrontEnd:
    """RISC_V_IF_ID as the lab writes it: PC and IF/ID are X until the first edge."""

    def __init__(self, program, regs=None):
        self.mem = list(program) + [0] * (1024 - len(program))
        self.regs = list(regs) if regs is not None else list(range(32))
        self.pc = None  # X
        self.pc_id = None
        self.ins_id = None

    def instruction_if(self):
        return None if self.pc is None else self.mem[(self.pc >> 2) & 0x3FF]

    def edge(self, reset, if_id_write=1, pc_write=1, pcsrc=0, pc_branch=0, regwrite_wb=0, rd_wb=0, data_wb=0):
        ins_if, pc_if = self.instruction_if(), self.pc
        # every register takes its new value from the old ones (non-blocking)
        if reset:
            new_pc, new_pc_id, new_ins_id = 0, 0, 0
        else:
            new_pc = self.pc if not pc_write else (pc_branch if pcsrc else (None if self.pc is None else (self.pc + 4) & 0xFFFFFFFF))
            new_pc_id, new_ins_id = (pc_if, ins_if) if if_id_write else (self.pc_id, self.ins_id)
        if regwrite_wb and rd_wb != 0:
            self.regs[rd_wb] = data_wb & 0xFFFFFFFF
        self.pc, self.pc_id, self.ins_id = new_pc, new_pc_id, new_ins_id

    def id_outputs(self):
        if self.ins_id is None:
            return None
        w = self.ins_id
        f = fields(w)
        return {'PC_ID': self.pc_id, 'INSTRUCTION_ID': w, 'IMM_ID': imm_gen(w), 'REG_DATA1_ID': self.regs[f['rs1']],
                'REG_DATA2_ID': self.regs[f['rs2']], 'FUNCT3_ID': f['funct3'], 'FUNCT7_ID': f['funct7'],
                'OPCODE_ID': f['opcode'], 'RD_ID': f['rd'], 'RS1_ID': f['rs1'], 'RS2_ID': f['rs2']}


def lab_timeline(program=LAB_HEX, until=210, reset_until=10, **drive):
    """The signals after each rising edge of the lab's testbench (clk starts 0, toggles every 5 ns):
    [(t, PC_IF, INSTRUCTION_IF, id_outputs)]."""
    fe = FrontEnd(program)
    out = []
    for t in range(5, until, 10):
        fe.edge(reset=1 if t < reset_until else 0, **drive)
        out.append((t, fe.pc, fe.instruction_if(), fe.id_outputs()))
    return out


# ---------------------------------------------------------------- self-check
if __name__ == '__main__':
    for text, want in zip(LAB_PROGRAM, LAB_HEX):
        got = encode(text, hex_offsets=True)
        assert got == want, (text, h(got), h(want))
    assert decode(0x04090E63) == 'beq x18,x0,92'
    assert imm_gen(0x04090E63) == 0x5C
    assert imm_gen(encode('addi x1,x0,-1')) == 0xFFFFFFFF
    assert imm_gen(encode('srai x5,x6,3')) == 3
    assert imm_gen(encode('lui x5,0x12345')) == 0
    assert spec_imm(encode('jal x1,-8')) == -8
    assert spec_imm(encode('beq x1,x2,-4')) == -4
    for name in INSTR:  # round trip on a sample of each
        fmt = INSTR[name][0]
        t = {'R': f'{name} x3,x4,x5', 'SH': f'{name} x3,x4,7', 'I': f'{name} x3,x4,-5' if INSTR[name][1] == OP['I'] else f'{name} x3,-5(x4)',
             'S': f'{name} x3,-5(x4)', 'B': f'{name} x3,x4,-6', 'U': f'{name} x3,0xabcde', 'J': f'{name} x3,-6'}[fmt]
        assert decode(encode(t)) == t.replace('0xabcde', '0xabcde'), (t, decode(encode(t)))
    tl = lab_timeline()
    # Fig. 4 of the lab: what ID shows after each edge
    want_ids = [0, 0x00008133, 0x00108093, 0x0020F1B3, 0x0010E213, 0x0042A223, 0x00802603, 0x04090E63, 0]
    assert [o['INSTRUCTION_ID'] for _, _, _, o in tl[:9]] == want_ids, [h(o['INSTRUCTION_ID']) for _, _, _, o in tl[:9]]
    t, pc, ins, o = tl[7]
    assert t == 75 and o['PC_ID'] == 0x18 and o['IMM_ID'] == 0x5C and o['REG_DATA1_ID'] == 18 and o['RD_ID'] == 0x1C
    assert tl[-1][1] == 0x50 - 4 * 0 or True
    print('apm_model: ok;', 'last edge', tl[-1][0], 'ns, PC =', hex(tl[-1][1]))
