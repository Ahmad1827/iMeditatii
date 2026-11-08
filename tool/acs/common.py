"""Shared helpers for the ACS course files (assets/data/acs/<code>.json).

Each course module builds PROBLEMS with problem(...) and calls write_course().
Run from the repo root:  python3 -I tool/acs/<course>.py
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DIFFS = ('ușoară', 'medie', 'grea')


def problem(id, title, chapter, difficulty, statement, kind, spec, hint='', solution='', source=''):
    assert difficulty in DIFFS, (id, difficulty)
    return {
        'id': str(id), 'title': title, 'chapter': chapter, 'difficulty': difficulty,
        'source': source, 'statement': statement.strip(), 'hint': hint.strip(),
        'solution': solution.strip(), 'kind': kind, 'spec': spec,
    }


def write_course(code, chapters, problems):
    ids = [p['id'] for p in problems]
    assert len(ids) == len(set(ids)), 'duplicate ids'
    for p in problems:
        assert p['chapter'] in chapters, (p['id'], p['chapter'])
    # chapter order, then the order written
    problems = sorted(problems, key=lambda p: (chapters.index(p['chapter']), problems.index(p)))
    out = os.path.join(ROOT, 'assets', 'data', 'acs', f'{code}.json')
    text = json.dumps({'code': code, 'chapters': chapters, 'problems': problems}, ensure_ascii=False, indent=1)
    # the app's font (a subset of Iosevka) has no U+2212: a plain minus reads the same
    text = text.replace('\u2212', '-')
    with open(out, 'w', encoding='utf-8') as f:
        f.write(text + '\n')
    print(f'{code}: {len(problems)} probleme -> {os.path.relpath(out, ROOT)}', file=sys.stderr)
