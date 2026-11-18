"""Builds the APM Lucrarea 2 guide: web/materiale/apm-lucrarea-2.pdf.

Every number in the guide's tables comes from tool/acs/apm_model.py (the lab's design
modelled in Python, checked against Fig. 4 of the lab): build.py writes them to
gen.json, the .typ files read it. The Verilog shown is src/*.v as it is.

Needs the Typst compiler for Python (`pip install typst`); the diagrams use the Typst
package @preview/cetz, downloaded on the first build.
"""
import json
import pathlib
import sys

import typst

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import apm_model as m  # noqa: E402

OUT = HERE.parents[2] / 'web' / 'materiale' / 'apm-lucrarea-2.pdf'


def hx(v, n=8):
    return '—' if v is None else f'{v & 0xFFFFFFFF:0{n}X}'


def breakdown(text, hexo=False):
    w = m.encode(text, hex_offsets=hexo)
    name = text.split()[0]
    fmt = m.INSTR[name][0]
    b = f'{w:032b}'
    cut = lambda hi, lo: b[31 - hi:32 - lo]
    if fmt in ('R', 'SH'):
        cells = [('funct7', cut(31, 25), 'f7', 7), ('rs2' if fmt == 'R' else 'shamt', cut(24, 20), 'rs2', 5), ('rs1', cut(19, 15), 'rs1', 5),
                 ('funct3', cut(14, 12), 'f3', 3), ('rd', cut(11, 7), 'rd', 5), ('opcode', cut(6, 0), 'op', 7)]
    elif fmt == 'I':
        cells = [('imm[11:0]', cut(31, 20), 'imm', 12), ('rs1', cut(19, 15), 'rs1', 5), ('funct3', cut(14, 12), 'f3', 3),
                 ('rd', cut(11, 7), 'rd', 5), ('opcode', cut(6, 0), 'op', 7)]
    elif fmt == 'S':
        cells = [('imm[11:5]', cut(31, 25), 'imm', 7), ('rs2', cut(24, 20), 'rs2', 5), ('rs1', cut(19, 15), 'rs1', 5),
                 ('funct3', cut(14, 12), 'f3', 3), ('imm[4:0]', cut(11, 7), 'imm', 5), ('opcode', cut(6, 0), 'op', 7)]
    elif fmt == 'B':
        cells = [('imm[12]', cut(31, 31), 'imm', 1), ('imm[10:5]', cut(30, 25), 'imm', 6), ('rs2', cut(24, 20), 'rs2', 5),
                 ('rs1', cut(19, 15), 'rs1', 5), ('funct3', cut(14, 12), 'f3', 3), ('imm[4:1]', cut(11, 8), 'imm', 4),
                 ('imm[11]', cut(7, 7), 'imm', 1), ('opcode', cut(6, 0), 'op', 7)]
    elif fmt == 'U':
        cells = [('imm[31:12]', cut(31, 12), 'imm', 20), ('rd', cut(11, 7), 'rd', 5), ('opcode', cut(6, 0), 'op', 7)]
    else:
        cells = [('imm[20]', cut(31, 31), 'imm', 1), ('imm[10:1]', cut(30, 21), 'imm', 10), ('imm[11]', cut(20, 20), 'imm', 1),
                 ('imm[19:12]', cut(19, 12), 'imm', 8), ('rd', cut(11, 7), 'rd', 5), ('opcode', cut(6, 0), 'op', 7)]
    nib = ' '.join(b[i:i + 4] for i in range(0, 32, 4))
    f = m.fields(w)
    return {'text': text, 'fmt': 'I' if fmt == 'SH' else fmt, 'hex': hx(w), 'nibbles': nib, 'cells': cells,
            'imm_gen': hx(m.imm_gen(w)), 'spec_imm': m.spec_imm(w), 'fields': f, 'decoded': m.decode(w)}


def timeline():
    rows = []
    for t, pc, ins, o in m.lab_timeline():
        row = {'t': t, 'pc_if': hx(pc), 'ins_if': hx(ins)}
        for k, n in [('PC_ID', 8), ('INSTRUCTION_ID', 8), ('IMM_ID', 8), ('REG_DATA1_ID', 8), ('REG_DATA2_ID', 8),
                     ('FUNCT3_ID', 1), ('FUNCT7_ID', 2), ('OPCODE_ID', 2), ('RD_ID', 2), ('RS1_ID', 2), ('RS2_ID', 2)]:
            row[k] = hx(o[k], n)
        row['what'] = m.decode(o['INSTRUCTION_ID']) or ('(zero: nimic)' if o['INSTRUCTION_ID'] == 0 else '?')
        rows.append(row)
    return rows


def regs_tb():
    """tb_registers.v, step by step (what read_data1/2 show in each interval)."""
    regs = list(range(32))
    # (from, to, r1, r2, reg_write, write_reg, write_data)
    phases = [(0, 12, 1, 2, 0, 0, 0), (12, 18, 7, 2, 0, 0, 0), (18, 28, 7, 3, 1, 3, 0xAB), (28, 38, 0, 3, 1, 0, 0xFF), (38, 58, 4, 3, 0, 4, 0x55)]
    out = []
    edges = list(range(5, 58, 10))
    for a, b, r1, r2, we, wr, wd in phases:
        cuts = [a] + [e for e in edges if a < e < b] + [b]
        for x, y in zip(cuts, cuts[1:]):
            out.append({'from': x, 'to': y, 'r1': r1, 'r2': r2, 'we': we, 'wr': wr, 'wd': hx(wd, 2),
                        'd1': hx(regs[r1], 2), 'd2': hx(regs[r2], 2)})
            if y in edges and we and wr != 0:
                regs[wr] = wd
    return out


IMM_EXAMPLES = ['lw x5,-12(x2)', 'addi x1,x1,1', 'addi x7,x0,-1', 'andi x3,x4,255', 'ori x4,x1,1', 'xori x6,x6,-1',
                'slti x8,x9,-100', 'sltiu x8,x9,2047', 'slli x10,x11,4', 'srli x10,x11,31', 'srai x10,x11,3',
                'sw x4,4(x5)', 'sw x9,-8(x2)', 'beq x18,x0,92', 'bne x1,x2,-4', 'blt x5,x6,2048', 'bge x5,x6,-4096',
                'bltu x3,x4,16', 'bgeu x3,x4,-20', 'lui x5,0x12345', 'jal x1,8', 'jalr x0,0(x1)', 'add x2,x1,x0']

PRACTICE = ['sub x5,x6,x7', 'xor x10,x11,x12', 'or x1,x2,x3', 'sll x4,x4,x5', 'sra x9,x8,x7', 'andi x2,x2,-16',
            'slti x3,x4,10', 'lw x6,0x40(x10)', 'sw x6,-4(x2)', 'bne x5,x0,-8', 'bge x1,x2,0x100', 'srai x3,x3,31']

WORDS = [0x00A50533, 0x40B50533, 0xFFF00293, 0x0002A303, 0xFE62AE23, 0xFE0516E3, 0x00C59593, 0x4025D593, 0x0080006F, 0x123452B7]


def main():
    assert m.encode('beq x18,x0,5c', hex_offsets=True) == 0x04090E63
    data = {
        'lab': [breakdown(t, hexo=True) for t in m.LAB_PROGRAM],
        'timeline': timeline(),
        'regs_tb': regs_tb(),
        'imm': [breakdown(t) for t in IMM_EXAMPLES],
        'practice': [breakdown(t) for t in PRACTICE],
        'words': [{'hex': hx(w), 'decoded': m.decode(w), **breakdown(m.decode(w))} for w in WORDS],
    }
    for d in data['words']:
        assert d['hex'] == hx(m.encode(d['decoded'])), d
    (HERE / 'gen.json').write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding='utf-8')
    OUT.parent.mkdir(parents=True, exist_ok=True)
    typst.compile(str(HERE / 'main.typ'), output=str(OUT), root=str(HERE))
    print(OUT)


if __name__ == '__main__':
    main()
