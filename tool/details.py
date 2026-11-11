#!/usr/bin/env python3
"""The problem details live in assets/data/details/, one file per subject and grade
(split further when a grade passes LIMIT bytes), listed in index.json.

A problem's tests can be megabytes, and the page of one problem must not wait
for the tests of two hundred. Tests over TESTS_INLINE bytes are kept apart, in
tests/<file>_<id>.json, and the problem says where: "tests_file". merge puts
them back, so a merged file is the same as before.

  python3 tool/details.py merge OUT.json   # every part -> one file, to edit
  python3 tool/details.py split IN.json    # one file -> the parts (rewrites the folder)
  python3 tool/details.py resplit          # merge + split in one go
"""
import json, os, sys, unicodedata

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'data', 'details')
TESTS = 'tests'  # folder in ROOT; listed in pubspec.yaml
LIMIT = 40_000_000  # GitHub warns at 50 MB and refuses 100 MB
TESTS_INLINE = 8_000  # bytes of tests that stay in the grade's file


def slug(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower()
    return ''.join(c if c.isalnum() else '_' for c in s)


def dump(o):
    return json.dumps(o, ensure_ascii=False, indent=2)


def merge():
    index = json.load(open(os.path.join(ROOT, 'index.json'), encoding='utf-8'))
    out = {}
    for subject, grades in index.items():
        for grade, files in grades.items():
            g = out.setdefault(subject, {}).setdefault(grade, {})
            for f in files:
                for k, v in json.load(open(os.path.join(ROOT, f), encoding='utf-8')).items():
                    if 'tests_file' in v:  # back where "tests" was
                        tests = json.load(open(os.path.join(ROOT, v['tests_file']), encoding='utf-8'))
                        v = {('tests' if a == 'tests_file' else a): (tests if a == 'tests_file' else b) for a, b in v.items()}
                    g[k] = v
    return out


def split(data):
    os.makedirs(os.path.join(ROOT, TESTS), exist_ok=True)
    for d in (ROOT, os.path.join(ROOT, TESTS)):
        for f in os.listdir(d):
            if f.endswith('.json'):
                os.remove(os.path.join(d, f))
    index = {}
    for subject, grades in data.items():
        for grade, items in grades.items():
            base = f'{slug(subject)}_{slug(grade)}'
            chunks, cur, size = [], {}, 0
            for k, v in items.items():
                tests = v.get('tests')
                if tests is not None and len(json.dumps(tests, ensure_ascii=False).encode()) > TESTS_INLINE:
                    name = f'{TESTS}/{base}_{slug(k)}.json'
                    with open(os.path.join(ROOT, name), 'w', encoding='utf-8') as fh:
                        json.dump(tests, fh, ensure_ascii=False, separators=(',', ':'))  # data, not for reading
                    v = {('tests_file' if a == 'tests' else a): (name if a == 'tests' else b) for a, b in v.items()}
                n = len(dump({k: v}).encode())
                if cur and size + n > LIMIT:
                    chunks.append(cur); cur, size = {}, 0
                cur[k] = v; size += n
            chunks.append(cur)
            names = []
            for i, c in enumerate(chunks):
                name = f'{base}.json' if len(chunks) == 1 else f'{base}_{i + 1}.json'
                with open(os.path.join(ROOT, name), 'w', encoding='utf-8') as fh:
                    fh.write(dump(c))
                names.append(name)
            index.setdefault(subject, {})[grade] = names
    with open(os.path.join(ROOT, 'index.json'), 'w', encoding='utf-8') as fh:
        fh.write(dump(index))
    return index


if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'resplit':
        index = split(merge())
        n = len(os.listdir(os.path.join(ROOT, TESTS)))
        print(f'{sum(len(f) for g in index.values() for f in g.values())} files, {n} problems with their tests apart')
        sys.exit()
    path = sys.argv[2]
    if cmd == 'merge':
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(dump(merge()))
    elif cmd == 'split':
        print(dump(split(json.load(open(path, encoding='utf-8')))))
