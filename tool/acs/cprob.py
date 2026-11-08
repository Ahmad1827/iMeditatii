"""C problems with tests (PCLP, SD): statements, and the checks run with gcc.

Every reference solution is compiled with gcc (C11) and must give each test's
output; a starter that is a buggy program must fail at least one test.
"""
import os, subprocess, tempfile

C_START = '''#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    // scrie codul aici

    return 0;
}
'''


def norm(s):
    return '\n'.join(l.rstrip() for l in s.replace('\r', '').strip().split('\n'))


def statement(desc, inp, out, constraints, example):
    parts = [desc.strip()]
    if inp:
        parts.append(f'**Date de intrare.** {inp.strip()}')
    if out:
        parts.append(f'**Date de ieșire.** {out.strip()}')
    if constraints:
        parts.append('**Restricții.**\n' + '\n'.join(f'• {c}' for c in constraints))
    if example:
        i, o = example
        parts.append(f'**Exemplu.** Pentru intrarea\n\n```\n{i.strip()}\n```\n\nprogramul afișează\n\n```\n{o.strip()}\n```')
    return '\n\n'.join(parts)


class Gcc:
    def __init__(self, code):
        self.dir = tempfile.mkdtemp(prefix='acs_c_')
        src = os.path.join(self.dir, 'main.c')
        with open(src, 'w') as f:
            f.write(code)
        self.exe = os.path.join(self.dir, 'a.out')
        r = subprocess.run(['gcc', '-std=gnu11', '-O2', '-o', self.exe, src, '-lm'], capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit(f'gcc failed:\n{r.stderr}\n{code}')

    def run(self, stdin):
        r = subprocess.run([self.exe], input=stdin, capture_output=True, text=True, timeout=10)
        return r.stdout


def check(title, ref, tests, starter=None):
    g = Gcc(ref)
    for t in tests:
        got = g.run(t['input'])
        if 'output' in t:
            assert norm(got) == norm(t['output']), f'{title}: reference gives {got!r}, test wants {t["output"]!r}'
        else:
            t['output'] = got
    if starter is not None:
        s = Gcc(starter)
        fails = sum(norm(s.run(t['input'])) != norm(t['output']) for t in tests)
        assert fails > 0, f'{title}: the buggy starter passes every test'
    return tests
