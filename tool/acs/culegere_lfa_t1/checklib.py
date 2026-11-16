"""Helpers for check.py: automata, the book's regular expressions, brute-force comparison.

Every automaton or regular expression the book gives as an answer is written here once
more and compared, on all words up to a length, with the language the statement
describes (a Python predicate).

Regular expressions use the book's notation: ∪ for union, * for star, + for one or
more, e for the empty word, ∅ for the empty language, parentheses; every other
character is a symbol.
"""
import itertools
import re
import sys

FAILED = []


def words(alpha, n):
    for k in range(n + 1):
        for t in itertools.product(alpha, repeat=k):
            yield ''.join(t)


def rx(expr):
    """The book's regular expression as a compiled Python one (fullmatch)."""
    out = []
    for ch in expr.replace(' ', ''):
        if ch == '∪':
            out.append('|')
        elif ch in '()*+':
            out.append({'(': '(?:', ')': ')', '*': '*', '+': '+'}[ch])
        elif ch == 'e':
            out.append('(?:)')
        elif ch == '∅':
            out.append('(?!)')
        else:
            out.append(re.escape(ch))
    return re.compile(''.join(out))


def dfa(t, start, final):
    """t: {state: {symbol: state}}; checks that δ is total and returns an acceptor."""
    syms = {a for row in t.values() for a in row}
    for q, row in t.items():
        assert set(row) == syms, f'δ is not total in {q}: {row}'
        for p in row.values():
            assert p in t, f'unknown state {p}'

    def acc(w):
        q = start
        for a in w:
            q = t[q][a]
        return q in final
    return acc


def nfa(delta, start, final):
    """delta: list of (p, u, q) with u a string (e = '' allowed), as in the course."""
    def acc(w):
        seen = set()
        todo = [(start, 0)]
        while todo:
            q, i = todo.pop()
            if (q, i) in seen:
                continue
            seen.add((q, i))
            if i == len(w) and q in final:
                return True
            for p, u, r in delta:
                if p == q and w.startswith(u, i):
                    todo.append((r, i + len(u)))
        return False
    return acc


def regex(expr):
    r = rx(expr)
    return lambda w: r.fullmatch(w) is not None


def same(name, alpha, got, want, n=9):
    for w in words(alpha, n):
        if bool(got(w)) != bool(want(w)):
            FAILED.append(f'{name}: differs on {w!r} (book {bool(got(w))}, statement {bool(want(w))})')
            return False
    return True


def minimize(t, start, final):
    """Moore's partition refinement. Returns the list of blocks (reachable states only)."""
    alpha = sorted({a for row in t.values() for a in row})
    reach, todo = {start}, [start]
    while todo:
        q = todo.pop()
        for a in alpha:
            if t[q][a] not in reach:
                reach.add(t[q][a])
                todo.append(t[q][a])
    block = {q: (q in final) for q in reach}
    while True:
        sig = {q: (block[q],) + tuple(block[t[q][a]] for a in alpha) for q in reach}
        ids = {s: i for i, s in enumerate(sorted(set(sig.values()), key=str))}
        new = {q: ids[sig[q]] for q in reach}
        if len(set(new.values())) == len(set(block.values())):
            groups = {}
            for q in reach:
                groups.setdefault(new[q], []).append(q)
            return sorted((sorted(g, key=str) for g in groups.values()), key=str)
        block = new


def subsets(delta, start, alpha):
    """Subset construction with e-closures for an NFA whose labels are symbols or ''."""
    def close(S):
        S, todo = set(S), list(S)
        while todo:
            q = todo.pop()
            for p, u, r in delta:
                if p == q and u == '' and r not in S:
                    S.add(r)
                    todo.append(r)
        return frozenset(S)
    s0 = close({start})
    table, todo = {}, [s0]
    while todo:
        S = todo.pop()
        if S in table:
            continue
        table[S] = {}
        for a in alpha:
            T = close({r for p, u, r in delta if p in S and u == a})
            table[S][a] = T
            todo.append(T)
    return s0, table


def count(name, got, want):
    if got != want:
        FAILED.append(f'{name}: got {got}, want {want}')


def cnt(w, s):
    """Occurrences of s in w, overlapping ones too (as #s(w) is used in the course)."""
    return sum(1 for i in range(len(w) - len(s) + 1) if w.startswith(s, i))


AB, ABC, B01, T012 = 'ab', 'abc', '01', '012'


def report():
    if FAILED:
        print('\n'.join(FAILED))
        sys.exit(1)
    print('all answers check out')
