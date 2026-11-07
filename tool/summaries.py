#!/usr/bin/env python3
"""A line about every problem, for the problem list: the start of the statement
and, in informatică, the first example. The details are tens of MB per grade, too
much for a list, so this small file is made from them.

  python3 tool/summaries.py    # assets/data/details/ -> assets/data/summaries.json

Run it after changing the details (tool/details.py split). Maths shows no example:
its answer is the example.
"""
import json, os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from details import merge  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data', 'summaries.json')
STATEMENT = 170  # characters of the statement
EXAMPLE = 16  # characters on a line of the example
EXAMPLE_LINES = 4  # lines of the example's input, and of its output

# the TeX of the maths statements, as plain text for one line
TEX = {
    r'\cup': '∪', r'\cap': '∩', r'\in': '∈', r'\notin': '∉', r'\subset': '⊂', r'\subseteq': '⊆', r'\emptyset': '∅',
    r'\le': '≤', r'\leq': '≤', r'\ge': '≥', r'\geq': '≥', r'\ne': '≠', r'\neq': '≠', r'\cdot': '·', r'\times': '×',
    r'\infty': '∞', r'\to': '→', r'\rightarrow': '→', r'\Rightarrow': '⇒', r'\pi': 'π', r'\alpha': 'α', r'\beta': 'β',
    r'\mathbb{R}': 'ℝ', r'\mathbb{N}': 'ℕ', r'\mathbb{Z}': 'ℤ', r'\mathbb{Q}': 'ℚ', r'\mathbb{C}': 'ℂ', r'\circ': '∘',
    r'\sqrt': '√', r'\int': '∫', r'\sum': 'Σ', r'\lim': 'lim', r'\ln': 'ln', r'\log': 'log', r'\sin': 'sin', r'\cos': 'cos',
    r'\tg': 'tg', r'\ctg': 'ctg', r'\{': '\x01', r'\}': '\x02', r'\varepsilon': 'ε', r'\epsilon': 'ε', r'\Delta': 'Δ', r'\lambda': 'λ', r'\,': ' ', r'\;': ' ', r'\quad': ' ', r'\left': '', r'\right': '',
    r'\dots': '…', r'\ldots': '…', r'\cdots': '…', r'\%': '%', r'\ast': '∗', r'\star': '⋆', r'\perp': '⊥',
    r'\parallel': '∥', r'\angle': '∠', r'\triangle': '△', r'\equiv': '≡', r'\approx': '≈', r'\pm': '±',
}
SUP = str.maketrans('0123456789+-n', '⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻ⁿ')
SUB = str.maketrans('0123456789+-nkij', '₀₁₂₃₄₅₆₇₈₉₊₋ₙₖᵢⱼ')
MATRIX = {'pmatrix': '()', 'bmatrix': '[]', 'vmatrix': '||', 'matrix': '()', 'cases': ['\x01 ', ' \x02']}


def matrix(m):
    rows = [' '.join(c.strip() for c in r.split('&')) for r in re.split(r'\\\\', m.group(2)) if r.strip()]
    l, r = MATRIX[m.group(1)]
    return l + '; '.join(rows) + r


def plain_tex(s):
    s = re.sub(r'\s*(\\begin\{cases\}|\\end\{cases\})\s*', r' \1 ', s)
    s = re.sub(r'\\begin\{(pmatrix|bmatrix|vmatrix|matrix|cases)\}(.*?)\\end\{\1\}', matrix, s, flags=re.S)
    # innermost first, so a root inside a fraction comes out right
    prev = None
    while prev != s:
        prev = s
        s = re.sub(r'\\sqrt\[3\]\{([^{}]*)\}', r'∛(\1)', s)
        s = re.sub(r'\\sqrt\{([^{}]*)\}', r'√(\1)', s)
        s = re.sub(r'\\(?:hat|bar|vec|overline|widehat)\{([^{}]*)\}', r'\1', s)
        s = re.sub(r'\\(?:d|t)?frac\{([^{}]*)\}\{([^{}]*)\}', r'(\1)/(\2)', s)
    s = re.sub(r'\\lim_\{([^{}]*)\}', r'lim(\1) ', s)
    s = re.sub(r'\\(?:operatorname|text|mathrm|mathbf)\{([^{}]*)\}', r'\1', s)
    s = re.sub(r'\\overline\{([^{}]*)\}', r'\1', s)
    for k in sorted(TEX, key=len, reverse=True):
        tail = r'(?![A-Za-z])' if k[-1].isalpha() else ''
        s = re.sub(re.escape(k) + tail, lambda _m, v=TEX[k]: v, s)
    s = re.sub(r'\^\{([0-9+\-n]+)\}', lambda m: m.group(1).translate(SUP), s)
    s = re.sub(r'\^([0-9n])', lambda m: m.group(1).translate(SUP), s)
    s = re.sub(r'_\{([0-9+\-nkij]+)\}', lambda m: m.group(1).translate(SUB), s)
    s = re.sub(r'_([0-9nkij])', lambda m: m.group(1).translate(SUB), s)
    s = re.sub(r'_\{([^{}]*)\}', r'\1', s)
    s = s.replace('$', '').replace('{', '').replace('}', '').replace('\x01', '{').replace('\x02', '}')
    s = re.sub(r'\\([A-Za-z]+)', r'\1', s)
    # (1)/(x) -> 1/x, keeping the brackets that hold more than one term
    s = re.sub(r'\(([A-Za-z0-9]+)\)/', r'\1/', s)
    return re.sub(r'/\(([A-Za-z0-9]+)\)', r'/\1', s)


def one_line(text, limit):
    text = re.sub(r'\s+', ' ', text).strip()
    if len(text) <= limit:
        return text
    cut = text[:limit].rsplit(' ', 1)[0].rstrip(',;:')
    return cut + '…'


def statement(d, maths):
    text = d.get('description') or d.get('cerinta') or ''
    # the first paragraph that says something: not a quote, not a heading
    paras = [p.strip() for p in re.split(r'\n\s*\n', text) if p.strip()]
    para = next((p for p in paras if not p.startswith(('"', '„', '“', '>', '#'))), paras[0] if paras else '')
    para = para.replace('`', '').replace('**', '')
    if maths or '$' in para:  # informatică has a formula now and then too
        para = plain_tex(para)
    return one_line(para, STATEMENT)


def example(d):
    """The first example as lines (at most EXAMPLE_LINES, each cut at EXAMPLE),
    so a matrix still reads as a matrix in the list."""
    ex = d.get('examples')
    if isinstance(ex, list):
        ex = ex[0] if ex else None
    if not isinstance(ex, dict) or 'input' not in ex or 'output' not in ex:
        return None

    def lines(s):
        ls = [l.rstrip() for l in str(s).strip().splitlines() if l.strip()]
        if len(ls) > EXAMPLE_LINES:
            ls = ls[:EXAMPLE_LINES - 1] + ['…']
        return '\n'.join(l if len(l) <= EXAMPLE else l[:EXAMPLE - 1] + '…' for l in ls)

    i, o = lines(ex['input']), lines(ex['output'])
    return [i, o] if i and o else None


def main():
    out = {}
    for subject, grades in merge().items():
        maths = subject.lower().startswith('mat')
        for grade, problems in grades.items():
            g = out.setdefault(subject, {}).setdefault(grade, {})
            for pid, d in problems.items():
                s = {'s': statement(d, maths)}
                e = None if maths else example(d)
                if e:
                    s['e'] = e
                g[pid] = s
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    n = sum(len(p) for g in out.values() for p in g.values())
    print(f'{n} problems, {os.path.getsize(OUT) // 1024} KB -> assets/data/summaries.json')


if __name__ == '__main__':
    main()
